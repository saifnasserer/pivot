import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> fetchSectionCounts() async {
    try {
      final doc =
          await _firestore.collection('settings').doc('registration').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!['section_counts'];
        return Map<String, int>.from(data);
      }
      return {};
    } catch (e) {
      throw Exception('Failed to fetch section counts: $e');
    }
  }

  Future<bool> fetchTeamFormationButtonVisibility() async {
    try {
      final doc =
          await _firestore
              .collection('settings')
              .doc('update_management')
              .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['show_team_formation_button'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to fetch team formation button visibility: $e');
    }
  }

  Future<void> updateSectionCount(String section, int count) async {
    try {
      await _firestore.collection('settings').doc('registration').update({
        'section_counts.$section': count,
      });
    } catch (e) {
      throw Exception('Failed to update section count: $e');
    }
  }

  Future<void> updateTeamFormationButtonVisibility(bool show) async {
    try {
      await _firestore.collection('settings').doc('update_management').update({
        'show_team_formation_button': show,
      });
    } catch (e) {
      throw Exception('Failed to update team formation button visibility: $e');
    }
  }
}
