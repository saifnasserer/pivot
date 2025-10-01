import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/subject_model.dart';

class SubjectsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all subjects
  Future<List<Subject>> getAllSubjects() async {
    try {
      final snapshot = await _firestore.collection('subjects').get();
      return snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch subjects: $e');
    }
  }

  // Get subjects by IDs
  Future<List<Subject>> getSubjectsByIds(List<String> subjectIds) async {
    if (subjectIds.isEmpty) return [];

    try {
      final snapshot =
          await _firestore
              .collection('subjects')
              .where(FieldPath.documentId, whereIn: subjectIds)
              .get();
      return snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch subjects by IDs: $e');
    }
  }

  // Add a subject
  Future<Subject> addSubject(Subject subject) async {
    try {
      final docRef = await _firestore
          .collection('subjects')
          .add(subject.toFirestore());
      return subject.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to add subject: $e');
    }
  }

  // Update a subject
  Future<void> updateSubject(Subject subject) async {
    try {
      await _firestore
          .collection('subjects')
          .doc(subject.id)
          .update(subject.toFirestore());
    } catch (e) {
      throw Exception('Failed to update subject: $e');
    }
  }

  // Delete a subject
  Future<void> deleteSubject(String subjectId) async {
    try {
      await _firestore.collection('subjects').doc(subjectId).delete();
    } catch (e) {
      throw Exception('Failed to delete subject: $e');
    }
  }

  // Get subjects by user (enrolled or teaching)
  Future<List<Subject>> getSubjectsByUser(String userId) async {
    try {
      // This would require querying users collection first to get their subjects
      // For now, return empty - implement based on your data structure
      return [];
    } catch (e) {
      throw Exception('Failed to fetch subjects for user: $e');
    }
  }

  // Get subjects by year
  Future<List<Subject>> getSubjectsByYear(int year) async {
    try {
      final snapshot =
          await _firestore
              .collection('subjects')
              .where('year', isEqualTo: year)
              .get();
      return snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch subjects by year: $e');
    }
  }

  // Search subjects
  Future<List<Subject>> searchSubjects(String query) async {
    try {
      final snapshot = await _firestore.collection('subjects').get();
      final allSubjects =
          snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();

      // Filter by query
      return allSubjects.where((subject) {
        final lowerQuery = query.toLowerCase();
        return subject.name.toLowerCase().contains(lowerQuery) ||
            subject.englishName.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search subjects: $e');
    }
  }

  // Get filtered subjects
  Future<List<Subject>> getFilteredSubjects({
    String? searchQuery,
    int? year,
    String? department,
    String? level,
  }) async {
    try {
      Query query = _firestore.collection('subjects');

      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      if (department != null) {
        query = query.where('departments', arrayContains: department);
      }

      final snapshot = await query.get();
      var subjects =
          snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();

      // Filter by search query locally
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        subjects =
            subjects.where((subject) {
              return subject.name.toLowerCase().contains(lowerQuery) ||
                  subject.englishName.toLowerCase().contains(lowerQuery);
            }).toList();
      }

      return subjects;
    } catch (e) {
      throw Exception('Failed to get filtered subjects: $e');
    }
  }

  // Enroll user in subject
  Future<bool> enrollUserInSubject(String userId, String subjectId) async {
    try {
      // Update user's enrolled subjects and subject's enrolled students
      await _firestore.collection('users').doc(userId).update({
        'enrolledSubjects': FieldValue.arrayUnion([subjectId]),
      });
      await _firestore.collection('subjects').doc(subjectId).update({
        'enrolledStudents': FieldValue.arrayUnion([userId]),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to enroll user: $e');
    }
  }

  // Unenroll user from subject
  Future<bool> unenrollUserFromSubject(String userId, String subjectId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'enrolledSubjects': FieldValue.arrayRemove([subjectId]),
      });
      await _firestore.collection('subjects').doc(subjectId).update({
        'enrolledStudents': FieldValue.arrayRemove([userId]),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to unenroll user: $e');
    }
  }

  // Update user subjects
  Future<bool> updateUserSubjects(
    String userId,
    List<String> subjectIds,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'enrolledSubjects': subjectIds,
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update user subjects: $e');
    }
  }

  // Get paginated subjects
  Future<List<Subject>> getPaginatedSubjects({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    int? year,
    String? department,
    String? level,
  }) async {
    try {
      Query query = _firestore.collection('subjects');

      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      if (department != null) {
        query = query.where('departments', arrayContains: department);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get paginated subjects: $e');
    }
  }

  // Cache methods - stub implementations
  Future<List<Subject>> getCachedSubjects() async {
    // Implement with Hive or SharedPreferences if needed
    return [];
  }

  Future<void> cacheSubjects(List<Subject> subjects) async {
    // Implement with Hive or SharedPreferences if needed
  }

  Future<void> clearSubjectsCache() async {
    // Implement with Hive or SharedPreferences if needed
  }

  // Get available years
  Future<List<int>> getAvailableYears() async {
    try {
      final snapshot = await _firestore.collection('subjects').get();
      final years =
          snapshot.docs
              .map((doc) => doc.data()['year'] as int?)
              .where((year) => year != null)
              .toSet()
              .toList();
      years.sort();
      return years.cast<int>();
    } catch (e) {
      throw Exception('Failed to get available years: $e');
    }
  }

  // Get available departments
  Future<List<String>> getAvailableDepartments() async {
    try {
      final snapshot = await _firestore.collection('subjects').get();
      final departments = <String>{};
      for (var doc in snapshot.docs) {
        final depts = doc.data()['departments'] as List?;
        if (depts != null) {
          departments.addAll(depts.cast<String>());
        }
      }
      return departments.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get departments: $e');
    }
  }

  // Get available levels
  Future<List<String>> getAvailableLevels() async {
    // Return common academic levels
    return [
      'المستوى الأول',
      'المستوى الثاني',
      'المستوى الثالث',
      'المستوى الرابع',
    ];
  }
}
