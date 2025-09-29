import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/feedback/services/feedback_service.dart';
import 'package:pivot/features/feedback/repositories/feedback_repository.dart';
import 'dart:io';

// Services
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

// Repositories
final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  final service = ref.watch(feedbackServiceProvider);
  return FeedbackRepository(service);
});

// State classes
class FeedbackState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> feedback;
  final Map<String, dynamic>? statistics;
  final String? uploadedImageUrl;
  final bool isUploadingImage;

  const FeedbackState({
    this.isLoading = false,
    this.error,
    this.feedback = const [],
    this.statistics,
    this.uploadedImageUrl,
    this.isUploadingImage = false,
  });

  FeedbackState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? feedback,
    Map<String, dynamic>? statistics,
    String? uploadedImageUrl,
    bool? isUploadingImage,
  }) {
    return FeedbackState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      feedback: feedback ?? this.feedback,
      statistics: statistics ?? this.statistics,
      uploadedImageUrl: uploadedImageUrl ?? this.uploadedImageUrl,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
    );
  }
}

// Notifier
class FeedbackNotifier extends StateNotifier<FeedbackState> {
  final FeedbackRepository _repository;

  FeedbackNotifier(this._repository) : super(const FeedbackState());

  // Submit feedback
  Future<bool> submitFeedback({
    required String userId,
    required String userName,
    required String userEmail,
    required String category,
    required String feedback,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.submitFeedback(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        category: category,
        feedback: feedback,
        imageUrl: imageUrl,
      );
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Upload feedback image
  Future<String?> uploadFeedbackImage(File imageFile) async {
    state = state.copyWith(isUploadingImage: true, error: null);
    try {
      final imageUrl = await _repository.uploadFeedbackImage(imageFile);
      state = state.copyWith(
        isUploadingImage: false,
        uploadedImageUrl: imageUrl,
      );
      return imageUrl;
    } catch (e) {
      state = state.copyWith(isUploadingImage: false, error: e.toString());
      return null;
    }
  }

  // Load all feedback
  Future<void> loadAllFeedback() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final feedback = await _repository.getAllFeedback();
      state = state.copyWith(isLoading: false, feedback: feedback);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load feedback by status
  Future<void> loadFeedbackByStatus(String status) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final feedback = await _repository.getFeedbackByStatus(status);
      state = state.copyWith(isLoading: false, feedback: feedback);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load feedback by category
  Future<void> loadFeedbackByCategory(String category) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final feedback = await _repository.getFeedbackByCategory(category);
      state = state.copyWith(isLoading: false, feedback: feedback);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Update feedback status
  Future<bool> updateFeedbackStatus(String feedbackId, String status) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.updateFeedbackStatus(
        feedbackId,
        status,
      );
      if (success) {
        await loadAllFeedback();
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Delete feedback
  Future<bool> deleteFeedback(String feedbackId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.deleteFeedback(feedbackId);
      if (success) {
        await loadAllFeedback();
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Load feedback statistics
  Future<void> loadFeedbackStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statistics = await _repository.getFeedbackStatistics();
      state = state.copyWith(isLoading: false, statistics: statistics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Search feedback
  Future<void> searchFeedback(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final feedback = await _repository.searchFeedback(query);
      state = state.copyWith(isLoading: false, feedback: feedback);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load feedback by user
  Future<void> loadFeedbackByUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final feedback = await _repository.getFeedbackByUser(userId);
      state = state.copyWith(isLoading: false, feedback: feedback);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load recent feedback
  Future<void> loadRecentFeedback({int limit = 10}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final feedback = await _repository.getRecentFeedback(limit: limit);
      state = state.copyWith(isLoading: false, feedback: feedback);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get feedback categories
  List<String> getFeedbackCategories() {
    return _repository.getFeedbackCategories();
  }

  // Get feedback statuses
  List<String> getFeedbackStatuses() {
    return _repository.getFeedbackStatuses();
  }

  // Clear uploaded image
  void clearUploadedImage() {
    state = state.copyWith(uploadedImageUrl: null);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final feedbackProvider =
    AutoDisposeStateNotifierProvider<FeedbackNotifier, FeedbackState>((ref) {
      final repository = ref.watch(feedbackRepositoryProvider);
      return FeedbackNotifier(repository);
    });

// Convenience providers for specific data
final feedbackListProvider = AutoDisposeProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final state = ref.watch(feedbackProvider);
  return state.feedback;
});

final feedbackStatisticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(feedbackProvider);
  return state.statistics;
});

final feedbackCategoriesProvider = Provider<List<String>>((ref) {
  final notifier = ref.watch(feedbackProvider.notifier);
  return notifier.getFeedbackCategories();
});

final feedbackStatusesProvider = Provider<List<String>>((ref) {
  final notifier = ref.watch(feedbackProvider.notifier);
  return notifier.getFeedbackStatuses();
});

final uploadedImageUrlProvider = AutoDisposeProvider<String?>((ref) {
  final state = ref.watch(feedbackProvider);
  return state.uploadedImageUrl;
});

final isUploadingImageProvider = AutoDisposeProvider<bool>((ref) {
  final state = ref.watch(feedbackProvider);
  return state.isUploadingImage;
});
