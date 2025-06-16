import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/lecture_model.dart';

class DoctorSubjectService {
  final CollectionReference _lecturesCollection =
      FirebaseFirestore.instance.collection('lectures');

  Future<List<Lecture>> getLecturesForDoctorCategory(
      String doctorId, String categoryName) async {
    try {
      final QuerySnapshot snapshot = await _lecturesCollection
          .where('doctorId', isEqualTo: doctorId)
          .where('categoryName', isEqualTo: categoryName)
          .get();

      return snapshot.docs
          .map((doc) => Lecture.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching lectures: $e');
      rethrow;
    }
  }

  Future<DocumentReference> addLecture(Lecture lecture) async {
    try {
      return await _lecturesCollection.add(lecture.toJson());
    } catch (e) {
      print('Error adding lecture: $e');
      rethrow;
    }
  }

  Future<void> deleteLecture(String lectureId) async {
    try {
      await _lecturesCollection.doc(lectureId).delete();
    } catch (e) {
      print('Error deleting lecture: $e');
      rethrow;
    }
  }

  Future<void> addLinkToLecture(String lectureId, Map<String, String> link) async {
    try {
      await _lecturesCollection.doc(lectureId).update({
        'links': FieldValue.arrayUnion([link])
      });
    } catch (e) {
      print('Error adding link: $e');
      rethrow;
    }
  }

  Future<void> deleteLinkFromLecture(String lectureId, Map<String, String> link) async {
    try {
      await _lecturesCollection.doc(lectureId).update({
        'links': FieldValue.arrayRemove([link])
      });
    } catch (e) {
      print('Error deleting link: $e');
      rethrow;
    }
  }
}
