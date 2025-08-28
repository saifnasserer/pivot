import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> _sectionCounts = {};
  bool _isLoading = false;
  String? _error;
  bool _showTeamFormationButton = false;

  Map<String, int> get sectionCounts => _sectionCounts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showTeamFormationButton => _showTeamFormationButton;

  SettingsProvider();

  Future<void> fetchSectionCounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc =
          await _firestore.collection('settings').doc('registration').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!['section_counts'];
        _sectionCounts = Map<String, int>.from(data);
      }
    } catch (e) {
      debugPrint('Failed to fetch seccccccccccccccccctions: $e');
      _error = 'Failed to fetch settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeamFormationButtonVisibility() async {
    try {
      final doc =
          await _firestore
              .collection('settings')
              .doc('update_management')
              .get();

      if (doc.exists && doc.data() != null) {
        _showTeamFormationButton =
            doc.data()!['show_team_formation_button'] ?? false;
      } else {
        _showTeamFormationButton = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch team formation button visibility: $e');
      _showTeamFormationButton = false;
      notifyListeners();
    }
  }

  Future<void> updateSectionCounts(Map<String, int> newCounts) async {
    try {
      await _firestore.collection('settings').doc('registration').set({
        'section_counts': newCounts,
      }, SetOptions(merge: true));
      _sectionCounts = newCounts;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }

  Future<void> updateTeamFormationButtonVisibility(bool show) async {
    try {
      await _firestore.collection('settings').doc('update_management').set({
        'show_team_formation_button': show,
      }, SetOptions(merge: true));
      _showTeamFormationButton = show;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update team formation button visibility: $e');
    }
  }
}
