import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/subject_model.dart';
import 'dart:developer' as developer;

class SubjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference<Subject> _subjectsCollection;

  SubjectService() {
    _subjectsCollection = _firestore
        .collection('subjects')
        .withConverter<Subject>(
          fromFirestore:
              (snapshot, _) => Subject.fromJson(snapshot.data()!, snapshot.id),
          toFirestore: (subject, _) => subject.toJson(),
        );
  }

  /// Fetches all subjects from the Firestore 'subjects' collection.
  Future<List<Subject>> getSubjects() async {
    developer.log('SubjectService: getSubjects called', name: 'SubjectService');
    try {
      developer.log(
        'SubjectService: Fetching from Firestore collection: subjects',
        name: 'SubjectService',
      );
      final snapshot = await _subjectsCollection.get();
      developer.log(
        'SubjectService: Firestore returned ${snapshot.docs.length} documents',
        name: 'SubjectService',
      );

      final subjects = snapshot.docs.map((doc) => doc.data()).toList();
      developer.log(
        'SubjectService: Parsed ${subjects.length} subjects from documents',
        name: 'SubjectService',
      );

      // Log first few subjects for debugging
      if (subjects.isNotEmpty) {
        developer.log(
          'SubjectService: First 3 subjects: ${subjects.take(3).map((s) => '${s.id}:${s.name}').toList()}',
          name: 'SubjectService',
        );
      }

      return subjects;
    } catch (e) {
      developer.log(
        'SubjectService: Error fetching subjects: $e',
        name: 'SubjectService',
      );
      print('Error fetching subjects: $e');
      rethrow;
    }
  }

  /// Fetches only specific subjects by their IDs (more efficient for filtering).
  Future<List<Subject>> getSubjectsByIds(List<String> subjectIds) async {
    try {
      if (subjectIds.isEmpty) {
        return [];
      }

      // Use 'whereIn' to fetch only the specified subjects
      final snapshot =
          await _subjectsCollection
              .where(FieldPath.documentId, whereIn: subjectIds)
              .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching subjects by IDs: $e');
      rethrow;
    }
  }

  /// Adds a new subject to the Firestore 'subjects' collection.
  Future<Subject> addSubject(Subject subject) async {
    try {
      final docRef = _subjectsCollection.doc();
      final newSubject = subject.copyWith(id: docRef.id);
      await docRef.set(newSubject);
      return newSubject;
    } catch (e) {
      print('Error adding subject: $e');
      rethrow;
    }
  }

  /// Updates an existing subject in the Firestore 'subjects' collection.
  Future<void> updateSubject(Subject subject) async {
    try {
      await _subjectsCollection.doc(subject.id).update(subject.toJson());
    } catch (e) {
      print('Error updating subject: $e');
      rethrow;
    }
  }

  /// Deletes a subject from the Firestore 'subjects' collection.
  Future<void> deleteSubject(String subjectId) async {
    try {
      await _subjectsCollection.doc(subjectId).delete();
    } catch (e) {
      print('Error deleting subject: $e');
      rethrow;
    }
  }
}
