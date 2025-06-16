import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/section_model.dart';

class SectionService {
  final CollectionReference _sectionsCollection = FirebaseFirestore.instance.collection('sections');

  Future<List<Section>> getSectionsForSubjects(List<String> subjectIds) async {
    if (subjectIds.isEmpty) {
      return [];
    }

    try {
      final QuerySnapshot snapshot = await _sectionsCollection
          .where('subjectId', whereIn: subjectIds)
          .get();

      return snapshot.docs
          .map((doc) => Section.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching sections: $e');
      rethrow;
    }
  }

  Future<Section> addSection(Section section) async {
    try {
      final docRef = await _sectionsCollection.add(section.toJson());
      // Return a new Section object with the ID from the created document
      return Section(
        id: docRef.id,
        name: section.name,
        subjectId: section.subjectId,
        days: section.days,
        time: section.time,
        location: section.location,
      );
    } catch (e) {
      print('Error adding section: $e');
      rethrow;
    }
  }

  Future<void> updateSection(Section section) async {
    try {
      await _sectionsCollection.doc(section.id).update(section.toJson());
    } catch (e) {
      print('Error updating section: $e');
      rethrow;
    }
  }

  Future<void> deleteSection(String sectionId) async {
    try {
      await _sectionsCollection.doc(sectionId).delete();
    } catch (e) {
      print('Error deleting section: $e');
      rethrow;
    }
  }
}
