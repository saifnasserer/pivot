import 'package:flutter/foundation.dart';
import 'package:pivot/screens/models/section_info.dart';

class SectionProvider with ChangeNotifier {
  // Internal data structure: Map of Subject Name -> List of Sections
  final Map<String, List<SectionInfo>> _sectionsBySubject = {
    // Initial dummy data
    'Machine Learning': [
      SectionInfo(
        title: 'سكشن 1',
        days: 'الاحد والخميس',
        location: 'قاعة 3',
        time: 'الساعه 5',
      ),
      SectionInfo(
        title: 'سكشن 2',
        days: 'الاثنين والاربعاء',
        location: 'قاعة 1',
        time: 'الساعه 10',
      ),
    ],
    'Software Engineering': [
      SectionInfo(
        title: 'سكشن 3',
        days: 'الثلاثاء',
        location: 'قاعة 2',
        time: 'الساعه 11',
      ),
    ],
  };

  // Getter for all sections grouped by subject
  Map<String, List<SectionInfo>> get sectionsBySubject => _sectionsBySubject;

  // Getter for just the subject names
  List<String> get subjectNames => _sectionsBySubject.keys.toList();

  // Getter for sections of a specific subject
  List<SectionInfo> getSectionsForSubject(String subjectName) {
    return _sectionsBySubject[subjectName] ?? [];
  }

  // Find a specific section by ID within a subject
  SectionInfo? getSectionById(String subjectName, String sectionId) {
    if (_sectionsBySubject.containsKey(subjectName)) {
      try {
        return _sectionsBySubject[subjectName]!.firstWhere(
          (s) => s.id == sectionId,
        );
      } catch (e) {
        // firstWhere throws if no element is found
        return null;
      }
    }
    return null; // Subject not found
  }

  // Add a new section to a subject
  void addSection(String subjectName, SectionInfo newSection) {
    if (!_sectionsBySubject.containsKey(subjectName)) {
      _sectionsBySubject[subjectName] =
          []; // Create subject if it doesn't exist
    }
    // Check if section ID already exists for this subject
    if (_sectionsBySubject[subjectName]!.any((s) => s.id == newSection.id)) {
      // Handle error: Section ID must be unique for the subject
      print(
        'Error: Section ID ${newSection.id} already exists for $subjectName.',
      );
      return;
    }
    _sectionsBySubject[subjectName]!.add(newSection);
    notifyListeners();
  }

  // Update an existing section
  void updateSection(
    String subjectName,
    String sectionId,
    SectionInfo updatedSection,
  ) {
    if (_sectionsBySubject.containsKey(subjectName)) {
      final index = _sectionsBySubject[subjectName]!.indexWhere(
        (s) => s.id == sectionId,
      );
      if (index != -1) {
        _sectionsBySubject[subjectName]![index] = updatedSection;
        notifyListeners();
      } else {
        print('Error: Section ID $sectionId not found for $subjectName.');
      }
    } else {
      print('Error: Subject $subjectName not found.');
    }
  }

  // Delete a section
  void deleteSection(String subjectName, String sectionId) {
    if (_sectionsBySubject.containsKey(subjectName)) {
      _sectionsBySubject[subjectName]!.removeWhere((s) => s.id == sectionId);
      // Optional: Remove subject if it becomes empty
      if (_sectionsBySubject[subjectName]!.isEmpty) {
        _sectionsBySubject.remove(subjectName);
      }
      notifyListeners();
    } else {
      print('Error: Subject $subjectName not found.');
    }
  }

  // Add a new subject (initially empty or with sections)
  void addSubject(String subjectName, [List<SectionInfo>? initialSections]) {
    if (!_sectionsBySubject.containsKey(subjectName)) {
      _sectionsBySubject[subjectName] = initialSections ?? [];
      notifyListeners();
    } else {
      print('Error: Subject $subjectName already exists.');
    }
  }

  // Delete a subject and all its sections
  void deleteSubject(String subjectName) {
    if (_sectionsBySubject.containsKey(subjectName)) {
      _sectionsBySubject.remove(subjectName);
      notifyListeners();
    } else {
      print('Error: Subject $subjectName not found.');
    }
  }
}
