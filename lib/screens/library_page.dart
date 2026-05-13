// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../ui/tokens.dart';
import '../services/player_controller.dart';
import '../services/settings_service.dart';
import '../services/library_scan_service.dart';
import '../repositories/song_repository.dart';
import '../widgets/star_rating.dart';
import 'settings_screen.dart';
import 'playlists_screen.dart';
import '../widgets/player_provider.dart';
import '../widgets/artwork_image.dart';
import '../utils/ui_utils.dart';
import '../repositories/playlist_repository.dart';
import '../ui/glass_panel.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _query = oaq.OnAudioQuery();
  List<oaq.SongModel> _allSongs = [];
  List<oaq.SongModel> _songs = [];
  final Map<int, String> _searchIndex = {};
  bool _loading = true;
  bool _showFavoritesOnly = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    SettingsService.instance.removeListener(_onSettingsChanged);
    LibraryScanService.instance.removeListener(_onScanChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SettingsService.instance.addListener(_onSettingsChanged);
    LibraryScanService.instance.addListener(_onScanChanged);
    _bootstrap();
  }

  void _onScanChanged() {
    if (!mounted) return;
    final scan = LibraryScanService.instance;

    // If a scan was started from elsewhere (e.g. Settings), refresh the view
    // when it completes by reading the PlayerController library cache.
    if (scan.phase == LibraryScanPhase.done) {
      final songs = PlayerController.ensure().librarySongs;
      setState(() {
        // Safety-net dedupe in case a platform query returns duplicates.
        final seen = <String>{};
        _allSongs =
            songs.where((s) => (s.data).isNotEmpty).where((s) {
              final key = Platform.isWindows ? s.data.toLowerCase() : s.data;
              return seen.add(key);
            }).toList();
        _rebuildSearchIndex();
        _songs = _computeFiltered(_searchCtrl.text);
        _loading = false;
      });
    } else if (scan.phase == LibraryScanPhase.error) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
    _loadSongs();
  }

  Future<void> _bootstrap() async {
    final granted = await _requestPermissions();
    if (!mounted) return;
    if (granted) {
      try {
        // Check if on_audio_query recognizes the permission
        bool oaqStatus = true;
        if (Platform.isAndroid) {
          oaqStatus = await _query.permissionsStatus();
          if (!oaqStatus) {
            try {
              // Call permissionsRequest to update internal state, but with timeout
              oaqStatus = await _query.permissionsRequest().timeout(
                const Duration(seconds: 2),
              );
            } catch (e) {
              debugPrint('Audio permission request failed: $e');
            }
          }
        }

        await _loadSongs();
      } catch (e) {
        debugPrint('Song load failed: $e');
        if (mounted) {
          setState(() => _loading = false);
          showToast(context, 'Failed to load songs: $e');
        }
      }
    } else {
      setState(() => _loading = false);
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Try audio permission first (Android 13+)
      final audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) {
        return true;
      }

      // If audio permission is not granted, try storage permission (Android 12 and below)
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Storage/Audio permission is required to access music files',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _loadSongs() async {
    try {
      if (mounted) {
        setState(() => _loading = true);
      }

      final songs = await LibraryScanService.instance.scanLibrary(
        restorePlayerState: true,
      );

      if (!mounted) return;
      setState(() {
        _allSongs = songs.where((s) => (s.data).isNotEmpty).toList();
        _rebuildSearchIndex();
        _songs = _computeFiltered(_searchCtrl.text);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(
        context,
        "Couldn't read your audio library: ${e is TimeoutException ? 'Query timed out' : 'Check permissions'}",
      );
    }
  }

  List<oaq.SongModel> _computeFiltered(String query) {
    List<oaq.SongModel> filtered = _allSongs;

    // 1. Filter by Favorites
    if (_showFavoritesOnly) {
      final favs = PlayerController.ensure().favoritesNotifier.value;
      filtered = filtered.where((s) => favs.contains(s.id.toString())).toList();
    }

    // 2. Filter by Search Query
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered =
          filtered.where((s) {
            return (_searchIndex[s.id] ?? _searchTextFor(s)).contains(q);
          }).toList();
    }

    return filtered;
  }

  void _rebuildSearchIndex() {
    _searchIndex
      ..clear()
      ..addEntries(_allSongs.map((s) => MapEntry(s.id, _searchTextFor(s))));
  }

  String _searchTextFor(oaq.SongModel s) {
    return '${s.title} ${s.artist ?? ''} ${s.album ?? ''} ${s.displayName}'
        .toLowerCase();
  }

  void _filterSongs(String query) {
    setState(() {
      _songs = _computeFiltered(query);
    });
  }

  int get _favoriteCount {
    final favs = PlayerController.ensure().favoritesNotifier.value;
    return _allSongs.where((s) => favs.contains(s.id.toString())).length;
  }

  String get _librarySummary {
    final total = _allSongs.length;
    if (_showFavoritesOnly) {
      return '$_favoriteCount favorite${_favoriteCount == 1 ? '' : 's'}';
    }
    if (_searchCtrl.text.trim().isNotEmpty) {
      return '${_songs.length} match${_songs.length == 1 ? '' : 'es'} of $total';
    }
    return '$total track${total == 1 ? '' : 's'}';
  }

  Future<void> _playNow(oaq.SongModel s) async {
    final ctrl = PlayerController.ensure();
    final index = _songs.indexOf(s);
    if (index != -1) {
      await ctrl.replaceQueue(_songs, initialIndex: index);
    }
    HapticFeedback.selectionClick();
  }

  Future<void> _playNext(oaq.SongModel s) async {
    final ctrl = PlayerController.ensure();
    await ctrl.insertNext(s);
    if (!mounted) return;
    showToast(context, 'Added to queue');
    HapticFeedback.selectionClick();
  }

  Future<void> _showRatingDialog(String songId) async {
    final meta = await SongRepository.instance.getMetadata(songId);
    if (!mounted) return;

    int tempRating = meta?.rating ?? 0;
    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: GlassPanel(
                    borderRadius: BorderRadius.circular(18),
                    borderColor: Colors.white.withValues(alpha: 0.15),
                    backdropBlurSigma: 0,
                    backgroundColor: kColorGlassBlackTint,
                    padding: const EdgeInsets.all(kSp * 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rate Song',
                          style: TextStyle(
                            color: kColorOn,
                            fontSize: kTextLg,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: kSp * 1.5),
                        Center(
                          child: StarRating(
                            rating: tempRating,
                            size: 36,
                            onRatingChanged:
                                (r) => setState(() => tempRating = r),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            tempRating == 0
                                ? 'No rating'
                                : '$tempRating star${tempRating > 1 ? "s" : ""}',
                            style: const TextStyle(color: kColorOn2),
                          ),
                        ),
                        const SizedBox(height: kSp * 1.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                await SongRepository.instance.updateRating(
                                  songId,
                                  tempRating,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) setState(() {});
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _showSortMenu() {
    final accentColor = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(kSp * 2),
              child: GlassPanel(
                borderRadius: BorderRadius.circular(20),
                borderColor: Colors.white.withValues(alpha: 0.15),
                backdropBlurSigma: 0,
                backgroundColor: kColorGlassBlackTint,
                padding: const EdgeInsets.all(kSp * 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sort Library',
                      style: TextStyle(
                        fontSize: kTextLg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: kSp),
                    _buildSortOption(label: 'Date Added', value: 'DATE_ADDED'),
                    _buildSortOption(label: 'Title', value: 'TITLE'),
                    _buildSortOption(label: 'Artist', value: 'ARTIST'),
                    _buildSortOption(label: 'Album', value: 'ALBUM'),
                    const Divider(color: Colors.white10),
                    ListTile(
                      title: const Text('Ascending'),
                      leading: Radio<int>(
                        value: 0,
                        groupValue: SettingsService.instance.librarySortOrder,
                        onChanged: (v) {
                          SettingsService.instance.setLibrarySort(
                            SettingsService.instance.librarySortType,
                            v!,
                          );
                          Navigator.pop(context);
                        },
                        activeColor: accentColor,
                      ),
                    ),
                    ListTile(
                      title: const Text('Descending'),
                      leading: Radio<int>(
                        value: 1,
                        groupValue: SettingsService.instance.librarySortOrder,
                        onChanged: (v) {
                          SettingsService.instance.setLibrarySort(
                            SettingsService.instance.librarySortType,
                            v!,
                          );
                          Navigator.pop(context);
                        },
                        activeColor: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildSortOption({required String label, required String value}) {
    final current = SettingsService.instance.librarySortType;
    final accentColor = Theme.of(context).colorScheme.primary;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(color: current == value ? accentColor : kColorOn),
      ),
      trailing: current == value ? Icon(Icons.check, color: accentColor) : null,
      onTap: () {
        SettingsService.instance.setLibrarySort(
          value,
          SettingsService.instance.librarySortOrder,
        );
        Navigator.pop(context);
      },
      dense: true,
    );
  }

  Future<void> _addToPlaylist(oaq.SongModel song) async {
    final playlists = await PlaylistRepository.instance.getAll();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(kSp * 2),
              child: GlassPanel(
                borderRadius: BorderRadius.circular(20),
                borderColor: Colors.white.withValues(alpha: 0.15),
                backdropBlurSigma: 0,
                backgroundColor: kColorGlassBlackTint,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Add to Playlist',
                        style: TextStyle(
                          color: kColorOn,
                          fontSize: kTextLg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (playlists.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No playlists found',
                          style: TextStyle(color: kColorOn2),
                        ),
                      )
                    else
                      ...playlists.map(
                        (p) => ListTile(
                          leading: const Icon(
                            Icons.queue_music,
                            color: kColorOn2,
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(color: kColorOn),
                          ),
                          subtitle: Text(
                            '${p.songCount} songs',
                            style: const TextStyle(color: kColorOn2),
                          ),
                          onTap: () async {
                            await PlaylistRepository.instance.addSong(
                              p.id,
                              song.id.toString(),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              showToast(context, 'Added to "${p.name}"');
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerProvider.of(context);
    final currentSongId = player.currentMediaItem?.id;
    final scan = LibraryScanService.instance;
    final accentColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: scan,
      builder: (context, _) {
        // NOTE: LibraryPage is already hosted inside the app-wide Scaffold
        // in `main.dart`, so we avoid a nested Scaffold here to keep it
        // visually consistent with Now Playing.
        return SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(kSp, kSp * 0.5, kSp, 0),
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: PlayerController.ensure().favoritesNotifier,
                  builder: (context, favs, _) {
                    return _LibraryHeader(
                      summary: _librarySummary,
                      favoritesOnly: _showFavoritesOnly,
                      scanning: scan.isScanning,
                      onFavoritesTap: () {
                        setState(() {
                          _showFavoritesOnly = !_showFavoritesOnly;
                          _songs = _computeFiltered(_searchCtrl.text);
                        });
                      },
                      onPlaylistsTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlaylistsScreen(),
                            ),
                          ),
                      onSortTap: _showSortMenu,
                      onSettingsTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                    );
                  },
                ),
              ),
              if (scan.isScanning)
                Padding(
                  padding: const EdgeInsets.fromLTRB(kSp, 6, kSp, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: kSp),
                          Text(
                            'Scanning… ${scan.phase.name}',
                            style: const TextStyle(
                              color: kColorOn2,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: scan.progress == 0 ? null : scan.progress,
                          backgroundColor: Colors.white10,
                          color: accentColor,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              if (scan.phase == LibraryScanPhase.error &&
                  scan.lastError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(kSp, 6, kSp, 0),
                  child: GlassPanel(
                    useShader: false,
                    borderRadius: BorderRadius.circular(kRadius),
                    borderColor: Colors.redAccent.withValues(alpha: 0.35),
                    padding: const EdgeInsets.all(kSp),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: kSp),
                        Expanded(
                          child: Text(
                            'Scan failed. ${scan.lastError}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kColorOn2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: scan.isScanning ? null : _loadSongs,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Main Glass Surface (Search + List)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(kSp, 6, kSp, 0),
                  child: GlassPanel(
                    useShader: false,
                    borderRadius: BorderRadius.circular(16),
                    borderColor: Colors.white.withValues(alpha: 0.15),
                    backgroundColor: kColorGlassBlackTint,
                    boxShadow: const [],
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // Search Bar (match Now Playing chip-glass)
                        GlassPanel(
                          useShader: false,
                          borderRadius: BorderRadius.circular(999),
                          borderColor: Colors.white.withValues(alpha: 0.15),
                          backgroundColor: const Color(0x04FFFFFF),
                          boxShadow: const [],
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _filterSongs,
                            style: const TextStyle(color: kColorOn),
                            decoration: const InputDecoration(
                              hintText: 'Search library',
                              hintStyle: TextStyle(color: kColorOn2),
                              prefixIcon: Icon(
                                PhosphorIconsRegular.magnifyingGlass,
                                color: kColorOn2,
                              ),
                              filled: false,
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 5),
                          child: Row(
                            children: [
                              Text(
                                _showFavoritesOnly ? 'Favorites' : 'All Tracks',
                                style: const TextStyle(
                                  color: kColorOn,
                                  fontSize: kTextSm,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _librarySummary,
                                style: const TextStyle(
                                  color: kColorOn2,
                                  fontSize: kTextXs,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Hairline divider under search
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        const SizedBox(height: 4),

                        Expanded(
                          child:
                              _loading
                                  ? Center(
                                    child: CircularProgressIndicator(
                                      color: accentColor,
                                    ),
                                  )
                                  : _songs.isEmpty
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _showFavoritesOnly
                                              ? PhosphorIconsRegular.heartBreak
                                              : PhosphorIconsRegular.musicNotes,
                                          size: 54,
                                          color: kColorOn2,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _showFavoritesOnly
                                              ? 'No favorites yet'
                                              : (_allSongs.isEmpty
                                                  ? 'No songs found'
                                                  : 'No matches'),
                                          style: const TextStyle(
                                            color: kColorOn2,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (_allSongs.isEmpty &&
                                            !_showFavoritesOnly)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                            ),
                                            child: TextButton(
                                              onPressed:
                                                  scan.isScanning
                                                      ? null
                                                      : _loadSongs,
                                              child: const Text(
                                                'Refresh Library',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                  : ListView.separated(
                                    padding: const EdgeInsets.only(
                                      bottom: kNavHeight + 76,
                                    ),
                                    itemCount: _songs.length,
                                    separatorBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          left: 64,
                                        ),
                                        child: Container(
                                          height: 1,
                                          color: Colors.white.withValues(
                                            alpha: 0.06,
                                          ),
                                        ),
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final s = _songs[index];
                                      final isPlaying =
                                          currentSongId == s.id.toString();

                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _playNow(s),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                // Tiny selection accent
                                                SizedBox(
                                                  width: 4,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 160,
                                                      ),
                                                      width: 3,
                                                      height:
                                                          isPlaying ? 22 : 0,
                                                      decoration: BoxDecoration(
                                                        color: accentColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              99,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Artwork (minimal chrome)
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: SizedBox(
                                                    width: 38,
                                                    height: 38,
                                                    child: DecoratedBox(
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Color(
                                                              0x04FFFFFF,
                                                            ),
                                                          ),
                                                      child: ArtworkImage(
                                                        id: s.id,
                                                        type:
                                                            oaq
                                                                .ArtworkType
                                                                .AUDIO,
                                                        nullArtworkWidget:
                                                            const Icon(
                                                              Icons.music_note,
                                                              color: kColorOn2,
                                                            ),
                                                        artworkBorder:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        artworkFit:
                                                            BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        s.title,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: TextStyle(
                                                          color:
                                                              isPlaying
                                                                  ? accentColor
                                                                  : kColorOn,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        s.artist ?? '<unknown>',
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: const TextStyle(
                                                          color: kColorOn2,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                PopupMenuButton<String>(
                                                  icon: const Icon(
                                                    Icons.more_vert,
                                                    color: kColorOn2,
                                                  ),
                                                  color: kColorCard,
                                                  onSelected: (value) {
                                                    switch (value) {
                                                      case 'play_next':
                                                        _playNext(s);
                                                        break;
                                                      case 'add_playlist':
                                                        _addToPlaylist(s);
                                                        break;
                                                      case 'rate':
                                                        _showRatingDialog(
                                                          s.id.toString(),
                                                        );
                                                        break;
                                                    }
                                                  },
                                                  itemBuilder:
                                                      (context) => [
                                                        const PopupMenuItem(
                                                          value: 'play_next',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .playlist_add,
                                                                color:
                                                                    kColorOn2,
                                                              ),
                                                              SizedBox(
                                                                width: 12,
                                                              ),
                                                              Text(
                                                                'Play Next',
                                                                style: TextStyle(
                                                                  color:
                                                                      kColorOn,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'add_playlist',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .queue_music,
                                                                color:
                                                                    kColorOn2,
                                                              ),
                                                              SizedBox(
                                                                width: 12,
                                                              ),
                                                              Text(
                                                                'Add to Playlist',
                                                                style: TextStyle(
                                                                  color:
                                                                      kColorOn,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'rate',
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .star_outline,
                                                                color:
                                                                    kColorOn2,
                                                              ),
                                                              SizedBox(
                                                                width: 12,
                                                              ),
                                                              Text(
                                                                'Rate Song',
                                                                style: TextStyle(
                                                                  color:
                                                                      kColorOn,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  final String summary;
  final bool favoritesOnly;
  final bool scanning;
  final VoidCallback onFavoritesTap;
  final VoidCallback onPlaylistsTap;
  final VoidCallback onSortTap;
  final VoidCallback onSettingsTap;

  const _LibraryHeader({
    required this.summary,
    required this.favoritesOnly,
    required this.scanning,
    required this.onFavoritesTap,
    required this.onPlaylistsTap,
    required this.onSortTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GlassPanel(
      useShader: false,
      borderRadius: BorderRadius.circular(16),
      borderColor: Colors.white.withValues(alpha: 0.14),
      backgroundColor: kColorGlassBlackTint,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kColorOn,
                fontSize: kTextMd,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _HeaderAction(
            tooltip: favoritesOnly ? 'Show all' : 'Show favorites',
            icon:
                favoritesOnly
                    ? PhosphorIconsFill.heart
                    : PhosphorIconsRegular.heart,
            active: favoritesOnly,
            onTap: scanning ? null : onFavoritesTap,
          ),
          _HeaderAction(
            tooltip: 'Playlists',
            icon: PhosphorIconsBold.playlist,
            onTap: scanning ? null : onPlaylistsTap,
          ),
          _HeaderAction(
            tooltip: 'Sort',
            icon: PhosphorIconsRegular.slidersHorizontal,
            onTap: scanning ? null : onSortTap,
          ),
          _HeaderAction(
            tooltip: 'Settings',
            icon: PhosphorIconsBold.gear,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        color: active ? accent : kColorOn,
        style: IconButton.styleFrom(
          fixedSize: const Size(34, 34),
          backgroundColor:
              active
                  ? accent.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.045),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.025),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
      ),
    );
  }
}
