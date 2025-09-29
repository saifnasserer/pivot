import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Submit feedback
  Future<bool> submitFeedback({
    required String userId,
    required String userName,
    required String userEmail,
    required String category,
    required String feedback,
    String? imageUrl,
  }) async {
    try {
      final feedbackData = {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'category': category,
        'feedback': feedback,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      await _firestore.collection('feedback').add(feedbackData);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Upload feedback image
  Future<String?> uploadFeedbackImage(File imageFile) async {
    try {
      // Compress the image
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 1024,
        minHeight: 1024,
        quality: 80,
      );

      if (compressedBytes == null) {
        throw Exception('Image compression failed');
      }

      final fileName = 'feedback_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('feedback/$fileName');

      final uploadTask = ref.putData(compressedBytes);
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        return await snapshot.ref.getDownloadURL();
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      return null;
    }
  }

  // Get all feedback
  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('feedback')
              .orderBy('timestamp', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get feedback by status
  Future<List<Map<String, dynamic>>> getFeedbackByStatus(String status) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('feedback')
              .where('status', isEqualTo: status)
              .orderBy('timestamp', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get feedback by category
  Future<List<Map<String, dynamic>>> getFeedbackByCategory(
    String category,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('feedback')
              .where('category', isEqualTo: category)
              .orderBy('timestamp', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Update feedback status
  Future<bool> updateFeedbackStatus(String feedbackId, String status) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete feedback
  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get feedback statistics
  Future<Map<String, dynamic>> getFeedbackStatistics() async {
    try {
      final querySnapshot = await _firestore.collection('feedback').get();

      int totalFeedback = querySnapshot.docs.length;
      int pendingFeedback = 0;
      int resolvedFeedback = 0;
      int rejectedFeedback = 0;

      Map<String, int> categoryCounts = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        final category = data['category'] ?? 'أخرى';

        switch (status) {
          case 'pending':
            pendingFeedback++;
            break;
          case 'resolved':
            resolvedFeedback++;
            break;
          case 'rejected':
            rejectedFeedback++;
            break;
        }

        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return {
        'totalFeedback': totalFeedback,
        'pendingFeedback': pendingFeedback,
        'resolvedFeedback': resolvedFeedback,
        'rejectedFeedback': rejectedFeedback,
        'categoryCounts': categoryCounts,
      };
    } catch (e) {
      return {
        'totalFeedback': 0,
        'pendingFeedback': 0,
        'resolvedFeedback': 0,
        'rejectedFeedback': 0,
        'categoryCounts': {},
      };
    }
  }

  // Get feedback categories
  List<String> getFeedbackCategories() {
    return ['فيدباك عام', 'مشكلة تقنية', 'شكوى', 'استفسار', 'أخرى'];
  }

  // Get feedback statuses
  List<String> getFeedbackStatuses() {
    return ['pending', 'resolved', 'rejected'];
  }

  // Search feedback
  Future<List<Map<String, dynamic>>> searchFeedback(String query) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('feedback')
              .orderBy('timestamp', descending: true)
              .get();

      final allFeedback =
          querySnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

      // Client-side search since Firestore doesn't support full-text search
      final lowercaseQuery = query.toLowerCase();
      return allFeedback.where((feedback) {
        final feedbackText =
            (feedback['feedback'] ?? '').toString().toLowerCase();
        final userName = (feedback['userName'] ?? '').toString().toLowerCase();
        final category = (feedback['category'] ?? '').toString().toLowerCase();

        return feedbackText.contains(lowercaseQuery) ||
            userName.contains(lowercaseQuery) ||
            category.contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get feedback by user
  Future<List<Map<String, dynamic>>> getFeedbackByUser(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('feedback')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get recent feedback
  Future<List<Map<String, dynamic>>> getRecentFeedback({int limit = 10}) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('feedback')
              .orderBy('timestamp', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }
}
