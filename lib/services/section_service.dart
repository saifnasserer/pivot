import 'package:pivot/models/section_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SectionService {
  final CollectionReference _sectionsCollection = FirebaseFirestore.instance
      .collection('sections');

  Future<List<Section>> getAllSections() async {
    try {
      final QuerySnapshot snapshot = await _sectionsCollection.get();
      return snapshot.docs.map((doc) => Section.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Section>> getSectionsForSubjects(List<String> subjectIds) async {
    if (subjectIds.isEmpty) {
      return [];
    }

    try {
      List<Section> allSections = [];
      // Firestore whereIn supports up to 30 items
      for (var i = 0; i < subjectIds.length; i += 30) {
        final chunk = subjectIds.sublist(
          i,
          i + 30 > subjectIds.length ? subjectIds.length : i + 30,
        );
        final QuerySnapshot snapshot =
            await _sectionsCollection.where('subjectId', whereIn: chunk).get();
        allSections.addAll(
          snapshot.docs.map((doc) => Section.fromFirestore(doc)),
        );
      }
      return allSections;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Section>> getSectionsForAssistant(String assistantId) async {
    if (assistantId.isEmpty) {
      return [];
    }

    try {
      final QuerySnapshot snapshot =
          await _sectionsCollection
              .where('assistantId', isEqualTo: assistantId)
              .get();

      final sections =
          snapshot.docs.map((doc) => Section.fromFirestore(doc)).toList();

      return sections;
    } catch (e) {
      rethrow;
    }
  }

  Future<Section> addSection(Section section) async {
    try {
      final sectionData = section.toJson();

      final docRef = await _sectionsCollection.add(sectionData);
      // Return a new Section object with the ID from the created document
      return Section(
        id: docRef.id,
        name: section.name,
        assistantId: section.assistantId,
        subjectId: section.subjectId,
        days: section.days,
        time: section.time,
        location: section.location,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSection(Section section) async {
    try {
      await _sectionsCollection.doc(section.id).update(section.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSection(String sectionId) async {
    try {
      await _sectionsCollection.doc(sectionId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
