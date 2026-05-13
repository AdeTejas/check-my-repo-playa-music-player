// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../services/settings_service.dart';
import '../ui/deep_space_background.dart';
import '../ui/tokens.dart';

class ScreensaverScreen extends StatefulWidget {
  const ScreensaverScreen({super.key});

  @override
  State<ScreensaverScreen> createState() => _ScreensaverScreenState();
}

class _ScreensaverScreenState extends State<ScreensaverScreen> {
  Timer? _hintTimer;
  bool _showHint = true;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_enterScreensaverMode());
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    unawaited(_restoreAppMode());
    super.dispose();
  }

  Future<void> _enterScreensaverMode() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await WakelockPlus.enable();
    } catch (_) {
      // Platform channels can be unavailable in widget tests.
    }
  }

  Future<void> _restoreAppMode() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (SettingsService.instance.keepScreenOn) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Platform channels can be unavailable in widget tests.
    }
  }

  void _exit() {
    if (_exiting) return;
    _exiting = true;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _exit,
        onPanDown: (_) => _exit(),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DeepSpaceBackground(
                subtle: false,
                mode: DeepSpaceMode.background,
              ),
            ),
            const Positioned.fill(
              child: DeepSpaceBackground(
                subtle: false,
                mode: DeepSpaceMode.overlay,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showHint ? 1 : 0,
                    duration: const Duration(milliseconds: 700),
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Text(
                          'Tap anywhere to exit',
                          style: TextStyle(
                            color: kColorOn.withOpacity(0.88),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
