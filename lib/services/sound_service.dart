import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Play notification sound
  Future<void> playNotificationSound() async {
    if (kIsWeb) return;

    try {
      await SystemSound.play(SystemSoundType.click);
      // Note: For custom sounds, we'd need to use a package like audioplayers
      // For now, using system sound as a fallback
    } catch (e) {
      print('Error playing notification sound: $e');
    }
  }

  // Play correct sound for task completion
  Future<void> playCorrectSound() async {
    if (kIsWeb) return;

    try {
      await SystemSound.play(SystemSoundType.click);
      // Note: For custom sounds, we'd need to use a package like audioplayers
      // For now, using system sound as a fallback
    } catch (e) {
      print('Error playing correct sound: $e');
    }
  }
}
