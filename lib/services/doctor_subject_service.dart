import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/lecture_model.dart';

class DoctorSubjectService {
  final CollectionReference _lecturesCollection = FirebaseFirestore.instance
      .collection('lectures');

  Future<List<Lecture>> getLecturesForDoctorSubject(
    String doctorId,
    String subjectId,
  ) async {
    try {
      final QuerySnapshot snapshot =
          await _lecturesCollection
              .where('doctorId', isEqualTo: doctorId)
              .where('subjectId', isEqualTo: subjectId)
              .get();

      return snapshot.docs.map((doc) => Lecture.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching lectures: $e');
      rethrow;
    }
  }

  Future<Lecture?> getLectureById(String lectureId) async {
    try {
      final DocumentSnapshot doc =
          await _lecturesCollection.doc(lectureId).get();
      if (doc.exists) {
        return Lecture.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching lecture by ID: $e');
      rethrow;
    }
  }

  Future<Lecture> addLecture(Lecture lecture) async {
    try {
      final docRef = await _lecturesCollection.add(lecture.toJson());
      // Create a new Lecture object that includes the generated ID
      return lecture.copyWith(id: docRef.id);
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

  Future<void> addLinkToLecture(
    String lectureId,
    Map<String, String> link,
  ) async {
    try {
      await _lecturesCollection.doc(lectureId).update({
        'links': FieldValue.arrayUnion([link]),
      });
    } catch (e) {
      print('Error adding link: $e');
      rethrow;
    }
  }

  Future<void> deleteLinkFromLecture(
    String lectureId,
    Map<String, String> link,
  ) async {
    try {
      await _lecturesCollection.doc(lectureId).update({
        'links': FieldValue.arrayRemove([link]),
      });
    } catch (e) {
      print('Error deleting link: $e');
      rethrow;
    }
  }

  Future<void> updateLinkInLecture(
    String lectureId,
    Map<String, dynamic> updatedLink,
  ) async {
    try {
      // First, get the current lecture to find the old link
      final lecture = await getLectureById(lectureId);
      if (lecture == null) {
        throw Exception('Lecture not found');
      }

      // Find the old link by URL and replace it with the updated one
      final oldLinks = List<Map<String, dynamic>>.from(lecture.links);
      final oldLinkIndex = oldLinks.indexWhere(
        (link) => link['url'] == updatedLink['url'],
      );

      if (oldLinkIndex != -1) {
        oldLinks[oldLinkIndex] = updatedLink;

        // Update the lecture with the new links array
        await _lecturesCollection.doc(lectureId).update({'links': oldLinks});
      } else {
        throw Exception('Link not found in lecture');
      }
    } catch (e) {
      print('Error updating link: $e');
      rethrow;
    }
  }
}
