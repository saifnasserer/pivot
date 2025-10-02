import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/announcements/repositories/announcements_repository.dart';
import 'package:pivot/features/announcements/services/announcements_service.dart';
import 'package:pivot/features/home/screens/adminstration/models/announcement_data.dart';
import 'package:pivot/models/comment_data.dart';

final announcementsServiceProvider = Provider<AnnouncementsService>(
  (ref) => AnnouncementsService(),
);

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((
  ref,
) {
  final service = ref.watch(announcementsServiceProvider);
  return AnnouncementsRepository(service);
});

class AnnouncementsState {
  final List<AnnouncementData> announcements;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? currentDepartmentFilter;
  final String? currentTimeFilter;
  final String? currentUserLevel;
  final bool isUploading;
  final double uploadProgress;
  final String? uploadError;

  const AnnouncementsState({
    this.announcements = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentDepartmentFilter,
    this.currentTimeFilter,
    this.currentUserLevel,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadError,
  });

  AnnouncementsState copyWith({
    List<AnnouncementData>? announcements,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? currentDepartmentFilter,
    String? currentTimeFilter,
    String? currentUserLevel,
    bool? isUploading,
    double? uploadProgress,
    String? uploadError,
  }) => AnnouncementsState(
    announcements: announcements ?? this.announcements,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: error ?? this.error,
    currentDepartmentFilter:
        currentDepartmentFilter ?? this.currentDepartmentFilter,
    currentTimeFilter: currentTimeFilter ?? this.currentTimeFilter,
    currentUserLevel: currentUserLevel ?? this.currentUserLevel,
    isUploading: isUploading ?? this.isUploading,
    uploadProgress: uploadProgress ?? this.uploadProgress,
    uploadError: uploadError ?? this.uploadError,
  );
}

final announcementsProvider = StateNotifierProvider.autoDispose<
  AnnouncementsNotifier,
  AnnouncementsState
>((ref) => AnnouncementsNotifier(ref));

class AnnouncementsNotifier extends StateNotifier<AnnouncementsState> {
  AnnouncementsNotifier(this._ref) : super(const AnnouncementsState());

  final Ref _ref;
  late final AnnouncementsRepository _repo = _ref.read(
    announcementsRepositoryProvider,
  );

  Future<void> fetchAnnouncements({
    String? department,
    String? timeFilter,
    String? userLevel,
    bool includeScheduledAndExpired = false,
    int limit = 10,
  }) async {
    state = state.copyWith(isLoading: true, error: null, hasMore: true);
    try {
      final announcements = await _repo.fetchAnnouncements(
        department: department,
        timeFilter: timeFilter,
        userLevel: userLevel,
        includeScheduledAndExpired: includeScheduledAndExpired,
        limit: limit,
        startAfterDocument: null, // Fresh fetch, no pagination
      );

      // If we got fewer announcements than the limit, there are no more
      final hasMore = announcements.length >= limit;

      state = state.copyWith(
        isLoading: false,
        announcements: announcements,
        currentDepartmentFilter: department,
        currentTimeFilter: timeFilter,
        currentUserLevel: userLevel,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMoreAnnouncements() async {
    // Don't load more if already loading or no more data
    if (state.isLoadingMore || !state.hasMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final lastDoc = _repo.getLastDocument();
      if (lastDoc == null) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }

      final newAnnouncements = await _repo.fetchAnnouncements(
        department: state.currentDepartmentFilter,
        timeFilter: state.currentTimeFilter,
        userLevel: state.currentUserLevel,
        limit: 10,
        startAfterDocument: lastDoc,
      );

      // If we got fewer announcements than the limit, there are no more
      final hasMore = newAnnouncements.length >= 10;

      if (mounted) {
        state = state.copyWith(
          isLoadingMore: false,
          announcements: [...state.announcements, ...newAnnouncements],
          hasMore: hasMore,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoadingMore: false, error: e.toString());
      }
    }
  }

  Future<void> addAnnouncement(AnnouncementData announcement) async {
    try {
      // Add to repository
      await _repo.addAnnouncement(announcement);

      // Add to local state immediately for instant feedback
      if (mounted) {
        final updatedAnnouncements = [...state.announcements, announcement];
        state = state.copyWith(announcements: updatedAnnouncements);
        print('✅ [AnnouncementsProvider] Added to local state');
      }

      // Wait a moment for Firestore to index the new document
      await Future.delayed(Duration(milliseconds: 300));

      // Refresh the list to get the server version with ID
      print(
        '🔄 [AnnouncementsProvider] Refreshing after add (fetching all announcements)...',
      );

      // Fetch all announcements without filters
      if (mounted) {
        await fetchAnnouncements(includeScheduledAndExpired: true);
      }

      print('✅ [AnnouncementsProvider] Refresh complete');
    } catch (e) {
      print('❌ [AnnouncementsProvider] Error adding announcement: $e');
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  Future<void> updateAnnouncement(
    String id,
    AnnouncementData announcement,
  ) async {
    try {
      await _repo.updateAnnouncement(id, announcement);

      // Update local state immediately
      if (mounted) {
        final updatedAnnouncements =
            state.announcements.map((a) {
              return a.id == id ? announcement : a;
            }).toList();
        state = state.copyWith(announcements: updatedAnnouncements);
        print('✅ [AnnouncementsProvider] Updated in local state');
      }

      // Wait a moment then refresh from server
      await Future.delayed(Duration(milliseconds: 300));

      print('🔄 [AnnouncementsProvider] Refreshing after update...');

      // Fetch all announcements without filters
      if (mounted) {
        await fetchAnnouncements(includeScheduledAndExpired: true);
      }

      print('✅ [AnnouncementsProvider] Refresh complete');
    } catch (e) {
      print('❌ [AnnouncementsProvider] Error updating announcement: $e');
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _repo.deleteAnnouncement(id);
      // Remove from local state
      final updatedAnnouncements =
          state.announcements
              .where((announcement) => announcement.id != id)
              .toList();
      state = state.copyWith(announcements: updatedAnnouncements);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> togglePin(String id) async {
    try {
      await _repo.togglePin(id);
      // Update local state
      final updatedAnnouncements =
          state.announcements.map((announcement) {
            if (announcement.id == id) {
              return announcement.copyWith(pinned: !announcement.pinned);
            }
            return announcement;
          }).toList();
      state = state.copyWith(announcements: updatedAnnouncements);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> pinAnnouncement(AnnouncementData announcement) async {
    if (announcement.id == null) return;
    try {
      // Update local state immediately
      final updatedAnnouncements =
          state.announcements.map((a) {
            if (a.id == announcement.id) {
              return a.copyWith(pinned: true);
            }
            return a;
          }).toList();
      state = state.copyWith(announcements: updatedAnnouncements);

      // Update in repository
      await _repo.togglePin(announcement.id!);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Refresh to get correct state on error
      await fetchAnnouncements(
        department: state.currentDepartmentFilter,
        timeFilter: state.currentTimeFilter,
      );
    }
  }

  Future<void> unpinAnnouncement(AnnouncementData announcement) async {
    if (announcement.id == null) return;
    try {
      // Update local state immediately
      final updatedAnnouncements =
          state.announcements.map((a) {
            if (a.id == announcement.id) {
              return a.copyWith(pinned: false);
            }
            return a;
          }).toList();
      state = state.copyWith(announcements: updatedAnnouncements);

      // Update in repository
      await _repo.togglePin(announcement.id!);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Refresh to get correct state on error
      await fetchAnnouncements(
        department: state.currentDepartmentFilter,
        timeFilter: state.currentTimeFilter,
      );
    }
  }

  Future<List<String>> uploadAnnouncementImages(List<String> imagePaths) async {
    try {
      final uploadedUrls = await _repo.uploadImages(imagePaths);
      return uploadedUrls;
    } catch (e) {
      print('❌ [AnnouncementsProvider] Error uploading images: $e');
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      rethrow;
    }
  }

  Future<void> addComment(String announcementId, CommentData comment) async {
    try {
      await _repo.addComment(announcementId, comment);
      // Refresh the list
      await fetchAnnouncements(
        department: state.currentDepartmentFilter,
        timeFilter: state.currentTimeFilter,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteComment(String announcementId, String commentId) async {
    try {
      await _repo.deleteComment(announcementId, commentId);
      // Refresh the list
      await fetchAnnouncements(
        department: state.currentDepartmentFilter,
        timeFilter: state.currentTimeFilter,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Get comments for announcement
  Future<List<CommentData>> getCommentsForAnnouncement(
    String announcementId,
  ) async {
    try {
      return await _repo.getCommentsForAnnouncement(announcementId);
    } catch (e) {
      throw Exception('Failed to get comments: $e');
    }
  }

  // Like comment
  Future<void> likeComment(
    String announcementId,
    String commentId,
    String userId,
  ) async {
    try {
      await _repo.likeComment(announcementId, commentId, userId);
    } catch (e) {
      throw Exception('Failed to like comment: $e');
    }
  }

  // Reply to comment
  Future<void> replyToComment(
    String announcementId,
    String parentCommentId,
    CommentData reply,
  ) async {
    try {
      await _repo.replyToComment(announcementId, parentCommentId, reply);
    } catch (e) {
      throw Exception('Failed to reply to comment: $e');
    }
  }

  // Update comment
  Future<void> updateComment(
    String announcementId,
    String commentId,
    String newContent,
  ) async {
    try {
      await _repo.updateComment(announcementId, commentId, newContent);
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setUploadProgress(double progress) {
    state = state.copyWith(uploadProgress: progress);
  }

  void setUploading(bool uploading) {
    state = state.copyWith(isUploading: uploading);
  }

  void setUploadError(String? error) {
    state = state.copyWith(uploadError: error);
  }
}
