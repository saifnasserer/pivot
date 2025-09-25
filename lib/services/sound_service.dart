import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Play notification sound
  Future<void> playNotificationSound() async {
    if (kIsWeb) return;

    try {
      // Try to play custom notification sound
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      // Fallback to system sound
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (fallbackError) {
      }
    }
  }

  // Play correct sound for task completion
  Future<void> playCorrectSound() async {
    if (kIsWeb) return;

    try {
      // Try to play custom correct sound
      await _audioPlayer.play(AssetSource('sounds/correct.mp3'));
    } catch (e) {
      // Fallback to system sound
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (fallbackError) {
      }
    }
  }

  // Dispose audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}
