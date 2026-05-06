import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../services/player_controller.dart';
import '../ui/tokens.dart';

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
            final processingState = playerState?.processingState ?? ProcessingState.idle;

            return GestureDetector(
              onTap: onTap,
              child: Container(
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: kSp, vertical: kSp / 2),
                decoration: BoxDecoration(
                  color: kColorSurface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      // Album art
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.all(kSp),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(kRadius / 2),
                          image: mediaItem.artUri != null
                              ? DecorationImage(
                                  image: NetworkImage(mediaItem.artUri.toString()),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: kColorSurface,
                        ),
                        child: mediaItem.artUri == null
                            ? Icon(
                                PhosphorIconsBold.musicNote,
                                color: kColorOn.withValues(alpha: 0.5),
                                size: 24,
                              )
                            : null,
                      ),

                      // Track info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mediaItem.title,
                              style: const TextStyle(
                                fontSize: kTextSm,
                                fontWeight: FontWeight.w600,
                                color: kColorOn,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              mediaItem.artist ?? 'Unknown Artist',
                              style: TextStyle(
                                fontSize: kTextXs,
                                color: kColorOn.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              PhosphorIconsBold.skipBack,
                              color: kColorOn,
                              size: 20,
                            ),
                            onPressed: ctrl.isReady ? ctrl.player.seekToPrevious : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isPlaying && processingState != ProcessingState.buffering
                                  ? PhosphorIconsBold.pause
                                  : PhosphorIconsBold.play,
                              color: kColorOn,
                              size: 24,
                            ),
                            onPressed: ctrl.isReady
                                ? () => isPlaying ? ctrl.pause() : ctrl.play()
                                : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              PhosphorIconsBold.skipForward,
                              color: kColorOn,
                              size: 20,
                            ),
                            onPressed: ctrl.isReady ? ctrl.player.seekToNext : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ],
                      ),

                      // Close button
                      if (onTap != null)
                        IconButton(
                          icon: const Icon(
                            PhosphorIconsBold.x,
                            color: kColorOn,
                            size: 16,
                          ),
                          onPressed: () => ctrl.stop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
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

extension on PlayerController {
  pause() {}
}