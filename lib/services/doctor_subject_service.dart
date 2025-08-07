import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/models/material_link.dart';

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
    Map<String, dynamic> link,
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
    Map<String, dynamic> link,
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

  // New method to rate a material link
  Future<void> rateMaterialLink(
    String lectureId,
    String materialUrl,
    String userId,
    double rating,
  ) async {
    try {
      // Get the current lecture
      final lecture = await getLectureById(lectureId);
      if (lecture == null) {
        throw Exception('Lecture not found');
      }

      // Find the material link to update
      final oldLinks = List<Map<String, dynamic>>.from(lecture.links);
      final linkIndex = oldLinks.indexWhere(
        (link) => link['url'] == materialUrl,
      );

      if (linkIndex == -1) {
        throw Exception('Material link not found');
      }

      // Get current link data
      final currentLink = Map<String, dynamic>.from(oldLinks[linkIndex]);

      // Update or add user rating
      Map<String, dynamic> userRatings = Map<String, dynamic>.from(
        currentLink['userRatings'] ?? {},
      );
      userRatings[userId] = rating;

      // Calculate new average rating
      final ratings = userRatings.values.cast<double>();
      final averageRating =
          ratings.isEmpty
              ? 0.0
              : ratings.reduce((a, b) => a + b) / ratings.length;

      // Update the link with new rating data
      final updatedLink = Map<String, dynamic>.from(currentLink);
      updatedLink['userRatings'] = userRatings;
      updatedLink['totalRatings'] = userRatings.length;
      updatedLink['averageRating'] = averageRating;

      // Replace the old link with the updated one
      oldLinks[linkIndex] = updatedLink;

      // Update the lecture
      await _lecturesCollection.doc(lectureId).update({'links': oldLinks});
    } catch (e) {
      print('Error rating material: $e');
      rethrow;
    }
  }

  // New method to remove a rating
  Future<void> removeMaterialRating(
    String lectureId,
    String materialUrl,
    String userId,
  ) async {
    try {
      // Get the current lecture
      final lecture = await getLectureById(lectureId);
      if (lecture == null) {
        throw Exception('Lecture not found');
      }

      // Find the material link to update
      final oldLinks = List<Map<String, dynamic>>.from(lecture.links);
      final linkIndex = oldLinks.indexWhere(
        (link) => link['url'] == materialUrl,
      );

      if (linkIndex == -1) {
        throw Exception('Material link not found');
      }

      // Get current link data
      final currentLink = Map<String, dynamic>.from(oldLinks[linkIndex]);

      // Remove user rating
      Map<String, dynamic> userRatings = Map<String, dynamic>.from(
        currentLink['userRatings'] ?? {},
      );
      userRatings.remove(userId);

      // Calculate new average rating
      final ratings = userRatings.values.cast<double>();
      final averageRating =
          ratings.isEmpty
              ? 0.0
              : ratings.reduce((a, b) => a + b) / ratings.length;

      // Update the link with new rating data
      final updatedLink = Map<String, dynamic>.from(currentLink);
      updatedLink['userRatings'] = userRatings;
      updatedLink['totalRatings'] = userRatings.length;
      updatedLink['averageRating'] = averageRating;

      // Replace the old link with the updated one
      oldLinks[linkIndex] = updatedLink;

      // Update the lecture
      await _lecturesCollection.doc(lectureId).update({'links': oldLinks});
    } catch (e) {
      print('Error removing rating: $e');
      rethrow;
    }
  }
}
