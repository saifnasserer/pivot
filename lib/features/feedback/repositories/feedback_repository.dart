import 'package:pivot/features/feedback/services/feedback_service.dart';
import 'dart:io';

class FeedbackRepository {
  final FeedbackService _feedbackService;

  FeedbackRepository(this._feedbackService);

  // Submit feedback
  Future<bool> submitFeedback({
    required String userId,
    required String userName,
    required String userEmail,
    required String category,
    required String feedback,
    String? imageUrl,
  }) async {
    return await _feedbackService.submitFeedback(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      category: category,
      feedback: feedback,
      imageUrl: imageUrl,
    );
  }

  // Upload feedback image
  Future<String?> uploadFeedbackImage(File imageFile) async {
    return await _feedbackService.uploadFeedbackImage(imageFile);
  }

  // Get all feedback
  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    return await _feedbackService.getAllFeedback();
  }

  // Get feedback by status
  Future<List<Map<String, dynamic>>> getFeedbackByStatus(String status) async {
    return await _feedbackService.getFeedbackByStatus(status);
  }

  // Get feedback by category
  Future<List<Map<String, dynamic>>> getFeedbackByCategory(
    String category,
  ) async {
    return await _feedbackService.getFeedbackByCategory(category);
  }

  // Update feedback status
  Future<bool> updateFeedbackStatus(String feedbackId, String status) async {
    return await _feedbackService.updateFeedbackStatus(feedbackId, status);
  }

  // Delete feedback
  Future<bool> deleteFeedback(String feedbackId) async {
    return await _feedbackService.deleteFeedback(feedbackId);
  }

  // Get feedback statistics
  Future<Map<String, dynamic>> getFeedbackStatistics() async {
    return await _feedbackService.getFeedbackStatistics();
  }

  // Get feedback categories
  List<String> getFeedbackCategories() {
    return _feedbackService.getFeedbackCategories();
  }

  // Get feedback statuses
  List<String> getFeedbackStatuses() {
    return _feedbackService.getFeedbackStatuses();
  }

  // Search feedback
  Future<List<Map<String, dynamic>>> searchFeedback(String query) async {
    return await _feedbackService.searchFeedback(query);
  }

  // Get feedback by user
  Future<List<Map<String, dynamic>>> getFeedbackByUser(String userId) async {
    return await _feedbackService.getFeedbackByUser(userId);
  }

  // Get recent feedback
  Future<List<Map<String, dynamic>>> getRecentFeedback({int limit = 10}) async {
    return await _feedbackService.getRecentFeedback(limit: limit);
  }
}
