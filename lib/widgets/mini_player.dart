import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/player_controller.dart';
import '../ui/tokens.dart';
import 'artwork_image.dart';

class MiniPlayer extends StatelessWidget {
  final PlayerController ctrl;
  final VoidCallback? onTap;

  const MiniPlayer({super.key, required this.ctrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SequenceState?>(
      stream: ctrl.player.sequenceStateStream,
      builder: (context, sequenceSnapshot) {
        final sequenceState = sequenceSnapshot.data;
        final currentItem = sequenceState?.currentSource;

        if (currentItem == null) return const SizedBox.shrink();

        final mediaItem = currentItem.tag as MediaItem;

        return StreamBuilder<PlayerState>(
          stream: ctrl.player.playerStateStream,
          builder: (context, playerSnapshot) {
            final playerState = playerSnapshot.data;
            final isPlaying = playerState?.playing ?? false;
            final processingState =
                playerState?.processingState ?? ProcessingState.idle;
            final songId = mediaItem.extras?['songId'];
            final artworkId = songId is int ? songId : int.tryParse('$songId');

            return Padding(
              padding: const EdgeInsets.only(bottom: kSp),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: kColorSurface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.all(kSp),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(kRadius / 2),
                          color: kColorSurface,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            artworkId == null
                                ? Icon(
                                  PhosphorIconsBold.musicNote,
                                  color: kColorOn.withValues(alpha: 0.5),
                                  size: 24,
                                )
                                : ArtworkImage(
                                  id: artworkId,
                                  type: oaq.ArtworkType.AUDIO,
                                  artworkFit: BoxFit.cover,
                                  artworkBorder: BorderRadius.circular(
                                    kRadius / 2,
                                  ),
                                  nullArtworkWidget: Icon(
                                    PhosphorIconsBold.musicNote,
                                    color: kColorOn.withValues(alpha: 0.5),
                                    size: 24,
                                  ),
                                ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mediaItem.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: kTextSm,
                                fontWeight: FontWeight.w700,
                                color: kColorOn,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mediaItem.artist ?? 'Unknown Artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: kTextXs,
                                color: kColorOn.withValues(alpha: 0.68),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _MiniIconButton(
                        icon: PhosphorIconsBold.skipBack,
                        onPressed:
                            ctrl.isReady ? ctrl.player.seekToPrevious : null,
                      ),
                      _MiniIconButton(
                        icon:
                            isPlaying &&
                                    processingState != ProcessingState.buffering
                                ? PhosphorIconsBold.pause
                                : PhosphorIconsBold.play,
                        size: 24,
                        onPressed:
                            ctrl.isReady
                                ? () =>
                                    isPlaying
                                        ? ctrl.player.pause()
                                        : ctrl.play()
                                : null,
                      ),
                      _MiniIconButton(
                        icon: PhosphorIconsBold.skipForward,
                        onPressed: ctrl.isReady ? ctrl.player.seekToNext : null,
                      ),
                      if (onTap != null)
                        _MiniIconButton(
                          icon: PhosphorIconsBold.x,
                          size: 16,
                          width: 34,
                          onPressed: ctrl.stop,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double width;

  const _MiniIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 20,
    this.width = 40,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: kColorOn, size: size),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: width, minHeight: 44),
    );
  }
}
