// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../services/player_controller.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import '../models/song_metadata.dart';
import '../ui/tokens.dart';
import '../ui/glass_panel.dart';
import '../ui/turntable_widget.dart';
import '../ui/waveform_widget.dart';
import '../ui/lyrics_sheet.dart';
import 'screensaver_screen.dart';
import '../utils/ui_utils.dart';
import '../widgets/player_provider.dart';

class PlayerScreen extends StatefulWidget {
  final bool isVisible;
  const PlayerScreen({this.isVisible = true, super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    _updateWakelock();
    SettingsService.instance.addListener(_updateWakelock);
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_updateWakelock);
    WakelockPlus.disable();
    super.dispose();
  }

  void _updateWakelock() {
    if (SettingsService.instance.keepScreenOn) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = PlayerProvider.of(context);
    final p = ctrl.player;

    return SafeArea(
      top: false,
      bottom: false,
      child: AnimatedBuilder(
        animation: SettingsService.instance,
        builder: (context, _) {
          return StreamBuilder<SequenceState?>(
            stream: p.sequenceStateStream,
            builder: (context, _) {
              final tag = ctrl.currentMediaItem;
              return StreamBuilder<PlayerState>(
                stream: p.playerStateStream,
                builder: (context, _) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final orientation = MediaQuery.orientationOf(context);
                      if (orientation == Orientation.landscape &&
                          constraints.maxWidth >= 780) {
                        return _NowPlayingLandscape(
                          ctrl: ctrl,
                          item: tag,
                          isVisible: widget.isVisible,
                        );
                      } else {
                        return _NowPlayingPortrait(
                          ctrl: ctrl,
                          item: tag,
                          isVisible: widget.isVisible,
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NowPlayingPortrait extends StatelessWidget {
  final PlayerController ctrl;
  final MediaItem? item;
  final bool isVisible;

  const _NowPlayingPortrait({
    required this.ctrl,
    required this.item,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 760;
        final tight = constraints.maxHeight < 690;
        final deckSide = <double>[
          constraints.maxWidth - kSp * 0.25,
          constraints.maxHeight * (tight ? 0.40 : (compact ? 0.46 : 0.48)),
          516.0,
        ].reduce((a, b) => a < b ? a : b);
        final deckTopGap = tight ? kSp * 2.0 : kSp * 3.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            kSp,
            tight ? 0 : kSp * 0.25,
            kSp,
            kSp * 0.5,
          ),
          child: Column(
            children: [
              SizedBox(height: deckTopGap),
              SizedBox(
                height: deckSide,
                child: Center(
                  child: SizedBox.square(
                    dimension: deckSide,
                    child: RepaintBoundary(
                      child: TurntableDeck(
                        ctrl: ctrl,
                        item: item,
                        isVisible: isVisible,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: tight ? kSp * 0.85 : kSp * 1.35),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: tight ? kSp * 0.25 : kSp),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      width: constraints.maxWidth - kSp * 0.5,
                      child: _NowPlayingSurface(
                        compact: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RocinanteProgress(
                              item: item,
                              player: ctrl.player,
                              compact: true,
                            ),
                            const SizedBox(height: 8),
                            _TrackInfoPanel(
                              item: item,
                              playerCtrl: ctrl,
                              compact: true,
                            ),
                            const SizedBox(height: 7),
                            _TransportBar(ctrl: ctrl, compact: true),
                            const SizedBox(height: 5),
                            _SecondaryControls(ctrl: ctrl, compact: true),
                          ],
                        ),
                      ),
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

class _NowPlayingLandscape extends StatelessWidget {
  final PlayerController ctrl;
  final MediaItem? item;
  final bool isVisible;

  const _NowPlayingLandscape({
    required this.ctrl,
    required this.item,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp * 2, kSp, kSp * 2, kSp * 2),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: RepaintBoundary(
                  child: TurntableDeck(
                    ctrl: ctrl,
                    item: item,
                    isVisible: isVisible,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: kSp * 2),
          Expanded(
            flex: 4,
            child: _NowPlayingSurface(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RocinanteProgress(item: item, player: ctrl.player),
                  const SizedBox(height: kSp * 0.75),
                  _TrackInfoPanel(item: item, playerCtrl: ctrl, compact: true),
                  const SizedBox(height: kSp * 0.75),
                  _TransportBar(ctrl: ctrl),
                  const SizedBox(height: kSp * 0.5),
                  _SecondaryControls(ctrl: ctrl, compact: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingSurface extends StatelessWidget {
  final Widget child;
  final bool compact;

  const _NowPlayingSurface({required this.child, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      useShader: false,
      borderRadius: BorderRadius.circular(22),
      borderWidth: 1.5,
      borderColor: Colors.white.withValues(alpha: 0.15),
      backgroundColor: kColorGlassClear,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? kSp * 0.85 : kSp * 1.5,
        vertical: compact ? kSp * 0.8 : kSp * 1.25,
      ),
      child: child,
    );
  }
}

class _RocinanteProgress extends StatelessWidget {
  final MediaItem? item;
  final AudioPlayer player;
  final bool compact;

  const _RocinanteProgress({
    required this.item,
    required this.player,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final path = item?.extras?['path'];
    final height = compact ? 64.0 : 78.0;

    if (item == null || path is! String || path.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: WaveformWidget(
        path: path,
        player: player,
        playedColor: Theme.of(context).colorScheme.primary,
        item: item,
      ),
    );
  }
}

class _TransportBar extends StatelessWidget {
  final PlayerController ctrl;
  final bool compact;
  const _TransportBar({required this.ctrl, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final p = ctrl.player;
    final accent = Theme.of(context).colorScheme.primary;

    final controls = <Widget>[
      _IconBtn(
        icon: PhosphorIconsBold.skipBack,
        onTap: () async {
          if (!ctrl.isReady) return;
          if (p.hasPrevious) {
            await p.seekToPrevious();
          } else {
            final len = p.sequenceState.sequence.length;
            if (len > 0) {
              await p.seek(Duration.zero, index: len - 1);
            }
          }
          HapticFeedback.selectionClick();
        },
      ),
      _IconBtn(
        icon: PhosphorIconsBold.arrowCounterClockwise,
        onTap: () async {
          if (!ctrl.isReady) return;
          final pos = p.position;
          final newPos = pos - const Duration(seconds: 10);
          await p.seek(newPos.isNegative ? Duration.zero : newPos);
          HapticFeedback.selectionClick();
        },
      ),
      Semantics(
        label: 'Play or pause music',
        button: true,
        child: ElevatedButton(
          onPressed: () async {
            if (!ctrl.isReady) return;
            if (p.playing) {
              await p.pause();
            } else {
              await p.play();
            }
            HapticFeedback.selectionClick();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            shape: const CircleBorder(),
            padding: EdgeInsets.all(compact ? 8 : 12),
            elevation: 4,
            shadowColor: Colors.black54,
          ),
          child: StreamBuilder<bool>(
            stream: p.playingStream,
            initialData: p.playing,
            builder: (_, snap) {
              final playing = snap.data ?? false;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: PhosphorIcon(
                  playing ? PhosphorIconsFill.pause : PhosphorIconsFill.play,
                  key: ValueKey(playing),
                  size: compact ? 22 : 27,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
      _IconBtn(
        icon: PhosphorIconsBold.arrowClockwise,
        onTap: () async {
          if (!ctrl.isReady) return;
          await p.seek(p.position + const Duration(seconds: 10));
          HapticFeedback.selectionClick();
        },
      ),
      _IconBtn(
        icon: PhosphorIconsBold.skipForward,
        onTap: () async {
          if (!ctrl.isReady) return;
          if (p.hasNext) {
            await p.seekToNext();
          } else {
            final len = p.sequenceState.sequence.length;
            if (len > 0) {
              await p.seek(Duration.zero, index: 0);
            }
          }
          HapticFeedback.selectionClick();
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 260) {
          return Wrap(
            spacing: kSp * 0.7,
            runSpacing: kSp * 0.45,
            alignment: WrapAlignment.center,
            children: controls,
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: controls,
        );
      },
    );
  }
}

class _SecondaryControls extends StatefulWidget {
  final PlayerController ctrl;
  final bool compact;
  const _SecondaryControls({required this.ctrl, this.compact = false});

  @override
  State<_SecondaryControls> createState() => _SecondaryControlsState();
}

class _SecondaryControlsState extends State<_SecondaryControls> {
  late List<String> _chipOrder;
  bool _isReordering = false;
  int? _selectedChipIndex;

  @override
  void initState() {
    super.initState();
    _chipOrder = List.from(SettingsService.instance.controlChipOrder);
  }

  void _reorderChips(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _chipOrder.removeAt(oldIndex);
      _chipOrder.insert(newIndex, item);
    });
    SettingsService.instance.setControlChipOrder(_chipOrder);
    HapticFeedback.selectionClick();
  }

  void _handleReorderTap(int index) {
    final selected = _selectedChipIndex;
    if (selected == null) {
      setState(() => _selectedChipIndex = index);
      HapticFeedback.selectionClick();
      return;
    }

    if (selected == index) {
      setState(() => _selectedChipIndex = null);
      HapticFeedback.selectionClick();
      return;
    }

    _reorderChips(selected, index);
    setState(() => _selectedChipIndex = null);
  }

  Widget _buildChip(String chipId, BuildContext context, int index) {
    final p = widget.ctrl.player;

    switch (chipId) {
      case 'shuffle':
        return StreamBuilder<bool>(
          stream: p.shuffleModeEnabledStream,
          initialData: p.shuffleModeEnabled,
          builder: (_, snap) {
            final shuf = snap.data ?? false;
            return _ReorderableChipIcon(
              key: const ValueKey('shuffle'),
              icon:
                  shuf ? PhosphorIconsFill.shuffle : PhosphorIconsLight.shuffle,
              label: 'Shuffle',
              active: shuf,
              isReordering: _isReordering,
              isSelected: _selectedChipIndex == index,
              onTap: () async {
                if (_isReordering) {
                  _handleReorderTap(index);
                  return;
                }
                if (!widget.ctrl.isReady) return;
                await p.setShuffleModeEnabled(!shuf);
                if (!shuf) await p.shuffle();
                HapticFeedback.selectionClick();
              },
              onLongPress:
                  _isReordering
                      ? () {
                        // In reorder mode, long-press moves selected chip here
                        if (_selectedChipIndex != null &&
                            _selectedChipIndex != index) {
                          _reorderChips(_selectedChipIndex!, index);
                          setState(() => _selectedChipIndex = null);
                        }
                      }
                      : null,
            );
          },
        );

      case 'repeat':
        return StreamBuilder<LoopMode>(
          stream: p.loopModeStream,
          initialData: p.loopMode,
          builder: (_, snap) {
            final lm = snap.data ?? LoopMode.off;
            final next =
                lm == LoopMode.off
                    ? LoopMode.one
                    : (lm == LoopMode.one ? LoopMode.all : LoopMode.off);
            final icon =
                lm == LoopMode.one
                    ? PhosphorIconsBold.numberCircleOne
                    : PhosphorIconsBold.arrowsClockwise;
            final active = lm != LoopMode.off;
            return _ReorderableChipIcon(
              key: ValueKey('repeat'),
              icon: icon,
              label:
                  lm == LoopMode.all
                      ? 'Repeat All'
                      : (lm == LoopMode.one ? 'Repeat One' : 'Repeat'),
              active: active,
              isReordering: _isReordering,
              isSelected: _selectedChipIndex == index,
              onTap: () {
                if (_isReordering) {
                  _handleReorderTap(index);
                  return;
                }
                if (!widget.ctrl.isReady) return;
                p.setLoopMode(next);
                HapticFeedback.selectionClick();
              },
              onLongPress:
                  _isReordering
                      ? () {
                        if (_selectedChipIndex != null &&
                            _selectedChipIndex != index) {
                          _reorderChips(_selectedChipIndex!, index);
                          setState(() => _selectedChipIndex = null);
                        }
                      }
                      : null,
            );
          },
        );

      case 'neural_mix':
        return _ReorderableChipIcon(
          key: ValueKey('neural_mix'),
          icon: PhosphorIconsBold.brain,
          label: 'Sonic Flow',
          active: false,
          isReordering: _isReordering,
          isSelected: _selectedChipIndex == index,
          onTap: () async {
            if (_isReordering) {
              _handleReorderTap(index);
              return;
            }
            if (!widget.ctrl.isReady) return;
            showToast(context, 'Building Sonic Flow...');
            await widget.ctrl.smartShuffle();
            if (!context.mounted) return;
            showToast(context, 'Sonic Flow ready');
            HapticFeedback.mediumImpact();
          },
          onLongPress:
              _isReordering
                  ? () {
                    if (_selectedChipIndex != null &&
                        _selectedChipIndex != index) {
                      _reorderChips(_selectedChipIndex!, index);
                      setState(() => _selectedChipIndex = null);
                    }
                  }
                  : null,
        );

      case 'speed':
        return _ReorderableChipIcon(
          key: ValueKey('speed'),
          icon: PhosphorIconsBold.gauge,
          label: 'Speed',
          active: false,
          isReordering: _isReordering,
          isSelected: _selectedChipIndex == index,
          onTap: () async {
            if (_isReordering) {
              _handleReorderTap(index);
              return;
            }
            if (!widget.ctrl.isReady) return;
            final current = p.speed;
            final picked = await showModalBottomSheet<double>(
              context: context,
              builder: (_) => _SpeedSheet(current: current),
            );
            if (picked != null && picked > 0) {
              try {
                await p.setSpeed(picked);
                HapticFeedback.selectionClick();
              } catch (_) {
                if (context.mounted) {
                  showToast(
                    context,
                    'Speed not supported on this track/device',
                  );
                }
              }
            }
          },
          onLongPress:
              _isReordering
                  ? () {
                    if (_selectedChipIndex != null &&
                        _selectedChipIndex != index) {
                      _reorderChips(_selectedChipIndex!, index);
                      setState(() => _selectedChipIndex = null);
                    }
                  }
                  : null,
        );

      case 'screensaver':
        return AnimatedBuilder(
          animation: SettingsService.instance,
          builder: (context, _) {
            final enabled = SettingsService.instance.screensaverEnabled;
            return _ReorderableChipIcon(
              key: ValueKey('screensaver'),
              icon: Icons.slideshow,
              label: 'Screensaver',
              active: enabled,
              isReordering: _isReordering,
              isSelected: _selectedChipIndex == index,
              onTap: () async {
                if (_isReordering) {
                  _handleReorderTap(index);
                  return;
                }
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScreensaverScreen()),
                );
              },
              onLongPress: () async {
                if (_isReordering) {
                  if (_selectedChipIndex != null &&
                      _selectedChipIndex != index) {
                    _reorderChips(_selectedChipIndex!, index);
                    setState(() => _selectedChipIndex = null);
                  }
                  return;
                }
                await SettingsService.instance.setScreensaverEnabled(!enabled);
                if (!context.mounted) return;
                showToast(
                  context,
                  enabled ? 'Screensaver disabled' : 'Screensaver enabled',
                );
              },
            );
          },
        );

      case 'bookmark':
        return _ReorderableChipIcon(
          key: ValueKey('bookmark'),
          icon: PhosphorIconsBold.bookmarkSimple,
          label: 'Bookmark',
          active: false,
          isReordering: _isReordering,
          isSelected: _selectedChipIndex == index,
          onTap: () {
            if (_isReordering) {
              _handleReorderTap(index);
              return;
            }
            if (!widget.ctrl.isReady) return;

            final controller = TextEditingController();
            showDialog(
              context: context,
              builder: (ctx) {
                final a = Theme.of(ctx).colorScheme.primary;
                return AlertDialog(
                  backgroundColor: kColorSurface,
                  title: const Text('Add Chapter'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Note (optional)...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: kColorOn2),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: a),
                      ),
                    ),
                    style: const TextStyle(color: kColorOn),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: kColorOn2),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final added = await widget.ctrl.addBookmark(
                          note: controller.text,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        showToast(
                          context,
                          added ? 'Chapter added' : 'No active track',
                        );
                        HapticFeedback.selectionClick();
                      },
                      child: Text('Add', style: TextStyle(color: a)),
                    ),
                  ],
                );
              },
            );
          },
          onLongPress: () async {
            if (_isReordering) {
              if (_selectedChipIndex != null && _selectedChipIndex != index) {
                _reorderChips(_selectedChipIndex!, index);
                setState(() => _selectedChipIndex = null);
              }
              return;
            }
            if (!widget.ctrl.isReady) return;
            await widget.ctrl.reloadBookmarks();
            if (!context.mounted) return;
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => BookmarksSheet(ctrl: widget.ctrl),
            );
          },
        );

      case 'lyrics':
        return _ReorderableChipIcon(
          key: ValueKey('lyrics'),
          icon: PhosphorIconsBold.microphoneStage,
          label: 'Lyrics',
          active: false,
          isReordering: _isReordering,
          isSelected: _selectedChipIndex == index,
          onTap: () {
            if (_isReordering) {
              _handleReorderTap(index);
              return;
            }
            if (!widget.ctrl.isReady) return;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => LyricsSheet(ctrl: widget.ctrl),
            );
          },
          onLongPress:
              _isReordering
                  ? () {
                    if (_selectedChipIndex != null &&
                        _selectedChipIndex != index) {
                      _reorderChips(_selectedChipIndex!, index);
                      setState(() => _selectedChipIndex = null);
                    }
                  }
                  : null,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Wrap(
            spacing: widget.compact ? 4 : 6,
            runSpacing: widget.compact ? 4 : 6,
            alignment: WrapAlignment.center,
            children: [
              Tooltip(
                message: _isReordering ? 'Done arranging' : 'Arrange functions',
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() {
                      _isReordering = !_isReordering;
                      _selectedChipIndex = null;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    width: widget.compact ? 22 : 26,
                    height: widget.compact ? 22 : 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _isReordering
                              ? accent.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color:
                            _isReordering
                                ? accent.withValues(alpha: 0.7)
                                : Colors.white12,
                      ),
                    ),
                    child: Icon(
                      _isReordering ? Icons.check : Icons.drag_indicator,
                      size: 14,
                      color: _isReordering ? accent : kColorOn2,
                    ),
                  ),
                ),
              ),
              ..._chipOrder.asMap().entries.map((entry) {
                final index = entry.key;
                final chipId = entry.value;
                return _buildChip(chipId, context, index);
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: PhosphorIcon(icon, size: 20, color: kColorOn),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    );
  }
}

class _TrackInfoPanel extends StatelessWidget {
  final MediaItem? item;
  final PlayerController playerCtrl;
  final bool compact;

  const _TrackInfoPanel({
    required this.item,
    required this.playerCtrl,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: compact ? 34 : 38),
            Expanded(
              child: _MarqueeText(
                text: item?.title ?? '—',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 18 : 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  height: 1.08,
                ),
              ),
            ),
            _FavoriteButton(item: item, playerCtrl: playerCtrl),
          ],
        ),
        SizedBox(height: compact ? 5 : 7),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            item?.artist ?? 'Unknown Artist',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kColorOn2.withValues(alpha: 0.88),
              fontSize: compact ? 12.5 : 15,
              fontWeight: FontWeight.w500,
              height: 1.15,
            ),
          ),
        ),
        SizedBox(height: compact ? 3 : 5),
        if (!compact && item != null) _SonicDnaBadge(songId: item!.id),
      ],
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const _MarqueeText({
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _configureAnimation({
    required bool shouldScroll,
    required Duration duration,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!shouldScroll) {
        _controller.stop();
        _controller.value = 0;
        return;
      }

      if (_controller.duration != duration) {
        _controller.duration = duration;
      }
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final textDirection = Directionality.of(context);
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: textDirection,
        )..layout();

        if (maxWidth <= 0 || painter.width <= maxWidth) {
          _configureAnimation(
            shouldScroll: false,
            duration: const Duration(milliseconds: 1),
          );
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: widget.textAlign,
            style: widget.style,
          );
        }

        const gap = 48.0;
        final travel = painter.width + gap;
        final duration = Duration(
          milliseconds: (travel * 42).round().clamp(5200, 18000),
        );
        _configureAnimation(shouldScroll: true, duration: duration);

        Widget titleText() {
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: widget.style,
          );
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SizedBox(
                width: maxWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -_controller.value * travel,
                      top: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          titleText(),
                          const SizedBox(width: gap),
                          ExcludeSemantics(child: titleText()),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final MediaItem? item;
  final PlayerController playerCtrl;

  const _FavoriteButton({required this.item, required this.playerCtrl});

  @override
  Widget build(BuildContext context) {
    final id = item?.id;
    final enabled = id != null && id.isNotEmpty;

    return ValueListenableBuilder<List<String>>(
      valueListenable: playerCtrl.favoritesNotifier,
      builder: (context, favorites, _) {
        final isFavorite = enabled && favorites.contains(id);

        return Semantics(
          label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          button: true,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(isFavorite),
            tween: Tween(begin: isFavorite ? 0.0 : 1.0, end: 1.0),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (context, pulse, child) {
              final scale = isFavorite ? 0.88 + (0.12 * pulse) : 1.0;
              final glow = isFavorite ? pulse : 0.0;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isFavorite
                            ? Colors.redAccent.withValues(alpha: 0.14)
                            : Colors.white.withValues(alpha: 0.045),
                    border: Border.all(
                      color:
                          isFavorite
                              ? Colors.redAccent.withValues(alpha: 0.62)
                              : Colors.white.withValues(alpha: 0.12),
                    ),
                    boxShadow:
                        isFavorite
                            ? [
                              BoxShadow(
                                color: Colors.redAccent.withValues(
                                  alpha: 0.24 * glow,
                                ),
                                blurRadius: 16,
                                spreadRadius: -2,
                              ),
                            ]
                            : null,
                  ),
                  child: IconButton(
                    tooltip: isFavorite ? 'Favorited' : 'Favorite',
                    onPressed:
                        enabled
                            ? () async {
                              await playerCtrl.toggleFavorite(id);
                              HapticFeedback.selectionClick();
                            }
                            : null,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder:
                          (child, animation) => ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                      child: PhosphorIcon(
                        isFavorite
                            ? PhosphorIconsFill.heart
                            : PhosphorIconsRegular.heart,
                        key: ValueKey(isFavorite),
                        size: 20,
                        color: isFavorite ? Colors.redAccent : kColorOn2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ReorderableChipIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool isReordering;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  // removed unused onReorder callback (was never provided by callers)

  const _ReorderableChipIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.isReordering,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_ReorderableChipIcon> createState() => _ReorderableChipIconState();
}

class _ReorderableChipIconState extends State<_ReorderableChipIcon> {
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onLongPressStart:
          widget.isReordering
              ? (details) {
                setState(() => _isDragging = true);
                HapticFeedback.mediumImpact();
              }
              : null,
      onLongPressMoveUpdate:
          widget.isReordering
              ? (details) {
                setState(() => _dragOffset = details.localPosition);
              }
              : null,
      onLongPressEnd:
          widget.isReordering
              ? (details) {
                setState(() {
                  _isDragging = false;
                  _dragOffset = Offset.zero;
                });
              }
              : null,
      child: Transform.translate(
        offset: _isDragging ? _dragOffset : Offset.zero,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color:
                widget.active
                    ? accent.withValues(alpha: 0.2)
                    : (widget.isSelected
                        ? accent.withValues(alpha: 0.30)
                        : (widget.isReordering
                            ? accent.withValues(alpha: 0.10)
                            : kColorOn.withValues(alpha: 0.035))),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  widget.active
                      ? accent
                      : (widget.isSelected
                          ? accent
                          : (widget.isReordering
                              ? accent.withValues(alpha: 0.48)
                              : kColorOn.withValues(alpha: 0.13))),
            ),
            boxShadow:
                _isDragging
                    ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isReordering) ...[
                Icon(
                  widget.isSelected
                      ? Icons.radio_button_checked
                      : Icons.drag_indicator,
                  size: 13,
                  color:
                      widget.isSelected
                          ? accent
                          : accent.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 3),
              ],
              Icon(
                widget.icon,
                size: 15,
                color: widget.active ? accent : kColorOn2,
              ),
              const SizedBox(width: 3),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.active ? accent : kColorOn2,
                  fontSize: 10,
                  fontWeight:
                      widget.active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedSheet extends StatelessWidget {
  final double current;
  const _SpeedSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      color: kColorSurface,
      padding: const EdgeInsets.all(kSp * 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Playback Speed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: kSp),
          Wrap(
            spacing: kSp,
            children:
                [0.5, 0.8, 1.0, 1.2, 1.5, 2.0].map((speed) {
                  final selected = (speed - current).abs() < 0.01;
                  return ChoiceChip(
                    label: Text('${speed}x'),
                    selected: selected,
                    onSelected: (_) => Navigator.pop(context, speed),
                    selectedColor: accent,
                    backgroundColor: kColorCard,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : kColorOn,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class QueueSheet extends StatefulWidget {
  final PlayerController ctrl;
  final ScrollController scrollController;

  const QueueSheet({
    super.key,
    required this.ctrl,
    required this.scrollController,
  });

  @override
  State<QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<QueueSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GlassPanel(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      borderColor: Colors.white.withValues(alpha: 0.14),
      backgroundColor: kColorGlassBlackTint,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: accent,
            labelColor: accent,
            unselectedLabelColor: kColorOn2,
            tabs: const [Tab(text: 'Queue'), Tab(text: 'Library')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildQueueList(), _buildLibraryList()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList() {
    final p = widget.ctrl.player;
    return StreamBuilder<SequenceState?>(
      stream: p.sequenceStateStream,
      builder: (context, snapshot) {
        final accent = Theme.of(context).colorScheme.primary;
        final state = snapshot.data;
        final sequence = state?.sequence ?? [];
        return ReorderableListView.builder(
          scrollController: widget.scrollController,
          itemCount: sequence.length,
          onReorder: (oldIndex, newIndex) async {
            if (oldIndex < newIndex) newIndex--;
            await widget.ctrl.moveQueueItem(oldIndex, newIndex);
            HapticFeedback.selectionClick();
          },
          itemBuilder: (context, index) {
            final item = sequence[index];
            final isPlaying = index == state?.currentIndex;
            final mediaItem = item.tag;
            final why =
                mediaItem.extras?['sonicFlowWhy']?.toString() ??
                mediaItem.extras?['neuralMixWhy']?.toString();
            return ListTile(
              key: ValueKey(item),
              title: Text(
                mediaItem.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isPlaying ? accent : kColorOn,
                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                why == null
                    ? (mediaItem.artist ?? 'Unknown')
                    : '${mediaItem.artist ?? 'Unknown'} • $why',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kColorOn2, fontSize: 12),
              ),
              trailing:
                  isPlaying
                      ? Icon(
                        PhosphorIconsFill.speakerHigh,
                        color: accent,
                        size: 16,
                      )
                      : null,
              onTap: () {
                p.seek(Duration.zero, index: index);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLibraryList() {
    final songs =
        widget.ctrl.librarySongs.where((s) {
          if (_searchQuery.isEmpty) return true;
          return s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (s.artist?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false);
        }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search Library...',
              prefixIcon: const Icon(
                PhosphorIconsRegular.magnifyingGlass,
                color: kColorOn2,
              ),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              hintStyle: const TextStyle(color: kColorOn2),
            ),
            style: const TextStyle(color: kColorOn),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            // Not attaching scrollController here to avoid conflict,
            // but this means this list won't drive the sheet drag.
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final s = songs[index];
              return ListTile(
                title: Text(
                  s.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kColorOn),
                ),
                subtitle: Text(
                  s.artist ?? '<unknown>',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kColorOn2),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    PhosphorIconsRegular.plusCircle,
                    color: kColorOn2,
                  ),
                  onPressed: () {
                    widget.ctrl.addToQueue(s);
                    showToast(context, 'Added to Queue');
                  },
                ),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: kColorSurface,
                    builder:
                        (ctx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(
                                PhosphorIconsRegular.play,
                                color: kColorOn,
                              ),
                              title: const Text(
                                'Play Now',
                                style: TextStyle(color: kColorOn),
                              ),
                              onTap: () {
                                widget.ctrl.replaceQueue([s]);
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                PhosphorIconsRegular.queue,
                                color: kColorOn,
                              ),
                              title: const Text(
                                'Play Next',
                                style: TextStyle(color: kColorOn),
                              ),
                              onTap: () {
                                widget.ctrl.insertNext(s);
                                Navigator.pop(ctx);
                                showToast(context, 'Playing Next');
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                PhosphorIconsRegular.plus,
                                color: kColorOn,
                              ),
                              title: const Text(
                                'Add to Queue',
                                style: TextStyle(color: kColorOn),
                              ),
                              onTap: () {
                                widget.ctrl.addToQueue(s);
                                Navigator.pop(ctx);
                                showToast(context, 'Added to Queue');
                              },
                            ),
                          ],
                        ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class BookmarksSheet extends StatelessWidget {
  final PlayerController ctrl;
  const BookmarksSheet({super.key, required this.ctrl});

  Future<void> _editBookmarkNote(
    BuildContext context, {
    required int index,
    required String initial,
  }) async {
    final controller = TextEditingController(text: initial);
    final accent = Theme.of(context).colorScheme.primary;

    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: kColorSurface,
          title: const Text('Edit Chapter'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Note (optional)...',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: kColorOn2),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: accent),
              ),
            ),
            style: const TextStyle(color: kColorOn),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: kColorOn2)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text('Save', style: TextStyle(color: accent)),
            ),
          ],
        );
      },
    );

    if (saved == null) return;
    await ctrl.updateBookmarkNote(index, saved);
    if (!context.mounted) return;
    showToast(context, 'Chapter updated');
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GlassPanel(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      borderColor: Colors.white.withValues(alpha: 0.14),
      backgroundColor: kColorGlassBlackTint,
      child: SizedBox(
        height: 400,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chapters / Bookmarks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: ctrl.bookmarksNotifier,
                builder: (context, bookmarks, _) {
                  if (bookmarks.isEmpty) {
                    return const Center(
                      child: Text(
                        'No chapters added',
                        style: TextStyle(color: kColorOn2),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final b = bookmarks[index];
                      final pos = Duration(
                        milliseconds: (b['pos'] as int?) ?? 0,
                      );
                      return ListTile(
                        leading: Text(
                          _fmt(pos),
                          style: TextStyle(
                            color: accent,
                            fontFamily: 'monospace',
                          ),
                        ),
                        title: Text((b['note'] as String?) ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () async {
                                await _editBookmarkNote(
                                  context,
                                  index: index,
                                  initial: (b['note'] as String?) ?? '',
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () async {
                                await ctrl.removeBookmark(index);
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                showToast(context, 'Chapter removed');
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          ctrl.player.seek(pos);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

class _SonicDnaBadge extends StatefulWidget {
  final String songId;
  const _SonicDnaBadge({required this.songId});

  @override
  State<_SonicDnaBadge> createState() => _SonicDnaBadgeState();
}

class _SonicDnaBadgeState extends State<_SonicDnaBadge> {
  late Future<SongMetadata?> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseService.instance.getSongMetadata(widget.songId);
  }

  @override
  void didUpdateWidget(covariant _SonicDnaBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) {
      _future = DatabaseService.instance.getSongMetadata(widget.songId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SongMetadata?>(
      future: _future,
      builder: (context, snapshot) {
        final meta = snapshot.data;
        if (meta == null || meta.bpm == null) return const SizedBox.shrink();

        final source =
            meta.isManualDna ? 'manual' : (meta.bpmSource ?? 'saved');
        final confidence = meta.bpmConfidence;
        final confidenceText =
            source == 'tag'
                ? 'tag'
                : source == 'manual'
                ? 'manual'
                : confidence == null
                ? source
                : '${(confidence * 100).round()}% estimate';

        return GestureDetector(
          onTap: () => _showCorrectionDialog(context, meta),
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1F26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(
                  alpha: meta.isManualDna ? 0.55 : 0.24,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsBold.waveform,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${meta.bpm!.round()} BPM',
                  style: const TextStyle(
                    color: Color(0xFFE8DCCA),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (meta.key != null) ...[
                  const SizedBox(width: 7),
                  Container(width: 1, height: 10, color: Colors.white24),
                  const SizedBox(width: 7),
                  Text(
                    meta.key!,
                    style: const TextStyle(
                      color: Color(0xFFA68B6C),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(width: 7),
                Text(
                  confidenceText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.46),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCorrectionDialog(
    BuildContext context,
    SongMetadata meta,
  ) async {
    final bpmController = TextEditingController(
      text: meta.bpm?.toStringAsFixed(0) ?? '',
    );
    final keyController = TextEditingController(text: meta.key ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: kColorSurface,
            title: const Text('Correct BPM / Key'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bpmController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'BPM',
                    hintText: 'Example: 124',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keyController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Key',
                    hintText: 'Example: 8A, C#m, F',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result != true) return;
    final bpm = double.tryParse(bpmController.text.trim());
    final key = keyController.text.trim();
    if (bpm == null && key.isEmpty) return;
    await DatabaseService.instance.updateSonicDna(
      widget.songId,
      bpm: bpm,
      key: key.isEmpty ? null : key,
      source: 'manual',
      confidence: 1.0,
      manual: true,
    );
    if (!mounted || !context.mounted) return;
    setState(() {
      _future = DatabaseService.instance.getSongMetadata(widget.songId);
    });
    showToast(context, 'BPM/key corrected');
  }
}
