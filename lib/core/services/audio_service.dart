import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playBeep() async {
    try {
      // Play system beep or custom sound
      await _player.play(AssetSource('sounds/store-scanner-beep.mp3'));
    } catch (e) {
      // If sound file not found, ignore
    }
  }

  Future<void> playError() async {
    try {
      await _player.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      // If sound file not found, ignore
    }
  }

  Future<void> playSuccess() async {
    try {
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      // If sound file not found, ignore
    }
  }

  void dispose() {
    _player.dispose();
  }
}
