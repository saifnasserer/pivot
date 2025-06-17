import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> _sectionCounts = {};
  bool _isLoading = false;
  String? _error;

  Map<String, int> get sectionCounts => _sectionCounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SettingsProvider() {
    fetchSectionCounts();
  }

  Future<void> fetchSectionCounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _firestore.collection('settings').doc('registration').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!['section_counts'];
        _sectionCounts = Map<String, int>.from(data);
      }
    } catch (e) {
      _error = 'Failed to fetch settings: $e';
    } finally {
      _isLoading = false;
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
}
