import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

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
      print('Error playing custom notification sound: $e');
      // Fallback to system sound
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (fallbackError) {
        print('Error playing fallback notification sound: $fallbackError');
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
      print('Error playing custom correct sound: $e');
      // Fallback to system sound
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (fallbackError) {
        print('Error playing fallback correct sound: $fallbackError');
      }
    }
  }

  // Dispose audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}
