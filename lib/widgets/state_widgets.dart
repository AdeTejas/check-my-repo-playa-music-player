// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../ui/tokens.dart';
import 'feedback_button.dart';

/// Error state widget with retry functionality
class ErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final String? retryText;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.title,
    this.message,
    this.retryText,
    this.onRetry,
    this.icon = PhosphorIconsBold.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSp * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: kSp),
            Text(
              title,
              style: TextStyle(
                fontSize: kTextMd,
                fontWeight: FontWeight.w600,
                color: kColorOn,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: kSp / 2),
              Text(
                message!,
                style: TextStyle(
                  fontSize: kTextSm,
                  color: kColorOn.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: kSp * 1.5),
              FeedbackButton(
                hapticType: HapticFeedbackType.mediumImpact,
                onPressed: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSp * 1.5,
                    vertical: kSp,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(kRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIconsBold.arrowClockwise,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: kSp / 2),
                      Text(
                        retryText ?? 'Try Again',
                        style: TextStyle(
                          fontSize: kTextSm,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading state widget with progress indicator
class LoadingState extends StatelessWidget {
  final String? message;
  final double? progress;

  const LoadingState({
    super.key,
    this.message,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSp * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: kSp),
              Text(
                message!,
                style: TextStyle(
                  fontSize: kTextSm,
                  color: kColorOn.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success state widget with animation
class SuccessState extends StatefulWidget {
  final String message;
  final Duration autoHideDuration;
  final VoidCallback? onComplete;

  const SuccessState({
    super.key,
    required this.message,
    this.autoHideDuration = const Duration(seconds: 2),
    this.onComplete,
  });

  @override
  State<SuccessState> createState() => _SuccessStateState();
}

class _SuccessStateState extends State<SuccessState>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();

    if (widget.autoHideDuration > Duration.zero) {
      Future.delayed(widget.autoHideDuration, () {
        if (mounted) {
          _animationController.reverse().then((_) {
            widget.onComplete?.call();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kSp * 1.5,
                vertical: kSp,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsBold.check,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: kSp / 2),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: kTextSm,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}