import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _beepPlayer = AudioPlayer(playerId: 'beep');
  bool _isPreloaded = false;
  DateTime? _lastBeep;
  static const _minBeepGap = Duration(milliseconds: 250);

  AudioService() {
    // Ensure the player stops at the end of the clip (no looping).
    _beepPlayer.setReleaseMode(ReleaseMode.stop);
    _beepPlayer.setVolume(1.0);
  }

  /// Call once at app start (e.g., in main or root widget initState)
  Future<void> preload() async {
    try {
      await _beepPlayer.setSource(AssetSource('sounds/store-scanner-beep.mp3'));
      _isPreloaded = true;
      debugPrint('✅ AudioService: beep preloaded');
    } catch (e) {
      debugPrint('⚠️ AudioService: preload failed: $e');
    }
  }

  Future<void> playBeep() async {
    // Debounce to avoid overlapping/queued plays on rapid scans
    final now = DateTime.now();
    if (_lastBeep != null && now.difference(_lastBeep!) < _minBeepGap) {
      return;
    }
    _lastBeep = now;

    try {
      if (_isPreloaded) {
        // Restart from the beginning and play
        await _beepPlayer.stop(); // guarantees fresh start
        await _beepPlayer.resume();
      } else {
        await _beepPlayer.play(AssetSource('sounds/store-scanner-beep.mp3'));
      }
    } catch (e) {
      debugPrint('⚠️ AudioService: beep failed: $e');
    }
  }

  Future<void> playSuccess() async {
    try {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      await p.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint('⚠️ AudioService: success failed: $e');
    }
  }

  Future<void> playError() async {
    try {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      await p.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      debugPrint('⚠️ AudioService: error failed: $e');
    }
  }

  void dispose() {
    _beepPlayer.dispose();
  }
}
