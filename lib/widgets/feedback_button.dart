import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced button with haptic feedback and scale animation
class FeedbackButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final Duration animationDuration;
  final HapticFeedbackType hapticType;

  const FeedbackButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.scaleFactor = 0.95,
    this.animationDuration = const Duration(milliseconds: 100),
    this.hapticType = HapticFeedbackType.lightImpact,
  });

  @override
  State<FeedbackButton> createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<FeedbackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  void _triggerHaptic() {
    switch (widget.hapticType) {
      case HapticFeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap:
          widget.onPressed != null
              ? () {
                _triggerHaptic();
                widget.onPressed!();
              }
              : null,
      onLongPress:
          widget.onLongPress != null
              ? () {
                _triggerHaptic();
                widget.onLongPress!();
              }
              : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}

/// Enhanced IconButton with better feedback
class FeedbackIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;
  final HapticFeedbackType hapticType;

  const FeedbackIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.onLongPress,
    this.iconSize,
    this.color,
    this.tooltip,
    this.padding,
    this.hapticType = HapticFeedbackType.lightImpact,
  });

  @override
  Widget build(BuildContext context) {
    final button = FeedbackButton(
      hapticType: hapticType,
      onPressed: onPressed,
      onLongPress: onLongPress,
      child: Container(
        padding: padding ?? const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: iconSize ?? 24,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
