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
  final String? error;
  final String? currentDepartmentFilter;
  final String? currentTimeFilter;
  final bool isUploading;
  final double uploadProgress;
  final String? uploadError;

  const AnnouncementsState({
    this.announcements = const [],
    this.isLoading = false,
    this.error,
    this.currentDepartmentFilter,
    this.currentTimeFilter,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadError,
  });

  AnnouncementsState copyWith({
    List<AnnouncementData>? announcements,
    bool? isLoading,
    String? error,
    String? currentDepartmentFilter,
    String? currentTimeFilter,
    bool? isUploading,
    double? uploadProgress,
    String? uploadError,
  }) => AnnouncementsState(
    announcements: announcements ?? this.announcements,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    currentDepartmentFilter:
        currentDepartmentFilter ?? this.currentDepartmentFilter,
    currentTimeFilter: currentTimeFilter ?? this.currentTimeFilter,
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
    bool includeScheduledAndExpired = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final announcements = await _repo.fetchAnnouncements(
        department: department,
        timeFilter: timeFilter,
        includeScheduledAndExpired: includeScheduledAndExpired,
      );
      state = state.copyWith(
        isLoading: false,
        announcements: announcements,
        currentDepartmentFilter: department,
        currentTimeFilter: timeFilter,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addAnnouncement(AnnouncementData announcement) async {
    try {
      await _repo.addAnnouncement(announcement);
      // Refresh the list
      await fetchAnnouncements(
        department: state.currentDepartmentFilter,
        timeFilter: state.currentTimeFilter,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateAnnouncement(
    String id,
    AnnouncementData announcement,
  ) async {
    try {
      await _repo.updateAnnouncement(id, announcement);
      // Refresh the list
      await fetchAnnouncements(
        department: state.currentDepartmentFilter,
        timeFilter: state.currentTimeFilter,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
