import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/subject_model.dart';

class SubjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference<Subject> _subjectsCollection;

  SubjectService() {
    _subjectsCollection = _firestore
        .collection('subjects')
        .withConverter<Subject>(
          fromFirestore: (snapshot, _) => Subject.fromJson(snapshot.data()!, snapshot.id),
          toFirestore: (subject, _) => subject.toJson(),
        );
  }

  /// Fetches all subjects from the Firestore 'subjects' collection.
  Future<List<Subject>> getSubjects() async {
    try {
      final snapshot = await _subjectsCollection.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching subjects: $e');
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
