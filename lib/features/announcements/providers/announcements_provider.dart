import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/announcements/repositories/announcements_repository.dart';
import 'package:pivot/features/announcements/services/announcements_service.dart';
import 'package:pivot/features/home/screens/adminstration/models/announcement_data.dart';
import 'package:pivot/models/comment_data.dart';
import 'package:pivot/services/cache_service.dart';

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
  final bool isFromCache;
  final DateTime? lastFetchTime;

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
    this.isFromCache = false,
    this.lastFetchTime,
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
    bool? isFromCache,
    DateTime? lastFetchTime,
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
    isFromCache: isFromCache ?? this.isFromCache,
    lastFetchTime: lastFetchTime ?? this.lastFetchTime,
  );
}

final announcementsProvider = StateNotifierProvider.autoDispose<
  AnnouncementsNotifier,
  AnnouncementsState
>((ref) => AnnouncementsNotifier(ref));

// StreamProvider for comments
final commentsStreamProvider = StreamProvider.family
    .autoDispose<List<CommentData>, String>((ref, announcementId) {
      final repo = ref.watch(announcementsRepositoryProvider);
      return repo.streamComments(announcementId);
    });

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
    bool forceRefresh = false,
  }) async {
    // Generate cache key based on filters
    final cacheKey = _generateCacheKey(department, timeFilter, userLevel);

    // Check if we should use cache first
    if (!forceRefresh) {
      final cachedAnnouncements = _getCachedAnnouncements(cacheKey);
      if (cachedAnnouncements.isNotEmpty) {
        // Show cached data immediately
        if (!mounted) return;

        state = state.copyWith(
          announcements: cachedAnnouncements,
          isLoading: false,
          error: null,
          currentDepartmentFilter: department,
          currentTimeFilter: timeFilter,
          currentUserLevel: userLevel,
          isFromCache: true,
          lastFetchTime: DateTime.now(),
        );

        // Still fetch fresh data in background for next time
        _fetchAnnouncementsInBackground(
          department,
          timeFilter,
          userLevel,
          includeScheduledAndExpired,
          limit,
          cacheKey,
        );
        return;
      }
    }

    // No cache available or force refresh - fetch from network
    if (!mounted) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      hasMore: true,
      isFromCache: false,
    );
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

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        announcements: announcements,
        currentDepartmentFilter: department,
        currentTimeFilter: timeFilter,
        currentUserLevel: userLevel,
        hasMore: hasMore,
        isFromCache: false,
        lastFetchTime: DateTime.now(),
      );

      // Cache the results after updating state
      _cacheAnnouncements(cacheKey, announcements);
    } catch (e) {
      // If network fails, try to show cached data as fallback
      if (!mounted) return;

      final cachedAnnouncements = _getCachedAnnouncements(cacheKey);
      if (!mounted) return; // Check again after cache operation

      if (cachedAnnouncements.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          announcements: cachedAnnouncements,
          error: 'اتصال ضعيف - يتم عرض البيانات المحفوظة',
          currentDepartmentFilter: department,
          currentTimeFilter: timeFilter,
          currentUserLevel: userLevel,
          isFromCache: true,
        );
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> loadMoreAnnouncements() async {
    // Don't load more if already loading or no more data
    if (state.isLoadingMore || !state.hasMore || state.isLoading) {
      return;
    }

    if (!mounted) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final lastDoc = _repo.getLastDocument();
      if (lastDoc == null) {
        if (mounted) {
          state = state.copyWith(isLoadingMore: false, hasMore: false);
        }
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
      if (!mounted) return;

      final updatedAnnouncements =
          state.announcements
              .where((announcement) => announcement.id != id)
              .toList();
      state = state.copyWith(announcements: updatedAnnouncements);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  Future<void> togglePin(String id) async {
    try {
      await _repo.togglePin(id);
      // Update local state
      if (!mounted) return;

      final updatedAnnouncements =
          state.announcements.map((announcement) {
            if (announcement.id == id) {
              return announcement.copyWith(pinned: !announcement.pinned);
            }
            return announcement;
          }).toList();
      state = state.copyWith(announcements: updatedAnnouncements);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  Future<void> pinAnnouncement(AnnouncementData announcement) async {
    if (announcement.id == null) return;
    try {
      // Update local state immediately
      if (!mounted) return;

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
      if (!mounted) return;

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
      if (!mounted) return;

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
      if (!mounted) return;

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
      if (!mounted) return;

      await fetchAnnouncements(
        department: state.currentDepartmentFilter,
        timeFilter: state.currentTimeFilter,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  Future<void> deleteComment(String announcementId, String commentId) async {
    try {
      await _repo.deleteComment(announcementId, commentId);
      // Refresh the list
      if (!mounted) return;

      await fetchAnnouncements(
        department: state.currentDepartmentFilter,
        timeFilter: state.currentTimeFilter,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
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
    if (!mounted) return;
    state = state.copyWith(error: null);
  }

  void setUploadProgress(double progress) {
    if (!mounted) return;
    state = state.copyWith(uploadProgress: progress);
  }

  void setUploading(bool uploading) {
    if (!mounted) return;
    state = state.copyWith(isUploading: uploading);
  }

  void setUploadError(String? error) {
    if (!mounted) return;
    state = state.copyWith(uploadError: error);
  }

  // ===== CACHING HELPER METHODS =====

  /// Generate a unique cache key based on filters
  String _generateCacheKey(
    String? department,
    String? timeFilter,
    String? userLevel,
  ) {
    return 'announcements_${department ?? 'all'}_${timeFilter ?? 'all'}_${userLevel ?? 'all'}';
  }

  /// Get cached announcements for a specific key
  List<AnnouncementData> _getCachedAnnouncements(String cacheKey) {
    try {
      final cacheService = CacheService.instance;

      // First try category-specific cache
      final isCacheValid = cacheService.isCategoryCacheValid(cacheKey);
      if (isCacheValid == true) {
        final cachedAnnouncements = cacheService
            .getCachedAnnouncementsByCategory(cacheKey);
        if (cachedAnnouncements.isNotEmpty) {
          print(
            '✅ Using category cache for key: $cacheKey (${cachedAnnouncements.length} items)',
          );
          return cachedAnnouncements;
        }
      }

      // Fallback: Filter general cache by current filters (for offline support)
      // This ensures offline mode works while keeping tabs separate
      final generalCache = cacheService.getCachedAnnouncementsByCategory(
        cacheKey,
      );
      if (generalCache.isEmpty) {
        // Try to filter from all cached announcements
        final allCached = cacheService.getCachedAnnouncements();
        if (allCached.isNotEmpty) {
          // Extract filters from cache key
          final filters = _extractFiltersFromCacheKey(cacheKey);
          final filtered = _filterAnnouncementsByKey(allCached, filters);

          if (filtered.isNotEmpty) {
            print(
              '⚠️ Using filtered general cache for key: $cacheKey (${filtered.length} items)',
            );
            return filtered;
          }
        }
      }

      print('⚠️ No cache available for key: $cacheKey');
    } catch (e) {
      print('❌ Error getting cached announcements: $e');
    }
    return [];
  }

  /// Extract filters from cache key
  Map<String, String?> _extractFiltersFromCacheKey(String cacheKey) {
    // Cache key format: announcements_${department}_${timeFilter}_${userLevel}
    final parts = cacheKey.split('_');
    return {
      'department': parts.length > 1 && parts[1] != 'all' ? parts[1] : null,
      'timeFilter': parts.length > 2 && parts[2] != 'all' ? parts[2] : null,
      'userLevel': parts.length > 3 && parts[3] != 'all' ? parts[3] : null,
    };
  }

  /// Filter announcements by extracted filters
  List<AnnouncementData> _filterAnnouncementsByKey(
    List<AnnouncementData> announcements,
    Map<String, String?> filters,
  ) {
    return announcements.where((ann) {
      // Filter by department
      if (filters['department'] != null && filters['department'] != 'all') {
        if (ann.department != filters['department']) {
          return false;
        }
      }

      // Filter by time (today)
      if (filters['timeFilter'] == 'today') {
        try {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // Parse the date string (format: "DD/MM/YYYY" or similar)
          final dateParts = ann.date.split('/');
          if (dateParts.length == 3) {
            final annDay = int.parse(dateParts[0]);
            final annMonth = int.parse(dateParts[1]);
            final annYear = int.parse(dateParts[2]);
            final annDate = DateTime(annYear, annMonth, annDay);

            if (!annDate.isAtSameMomentAs(today)) {
              return false;
            }
          }
        } catch (e) {
          // If date parsing fails, skip this filter
          print('⚠️ Could not parse date for filtering: ${ann.date}');
        }
      }

      // Filter by level (if applicable)
      if (filters['userLevel'] != null && ann.level != null) {
        if (ann.level != filters['userLevel']) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Cache announcements with a specific key
  void _cacheAnnouncements(
    String cacheKey,
    List<AnnouncementData> announcements,
  ) {
    try {
      final cacheService = CacheService.instance;
      cacheService.cacheAnnouncementsByCategory(cacheKey, announcements);
      print(
        '✅ Cached ${announcements.length} announcements for key: $cacheKey',
      );
    } catch (e) {
      print('❌ Error caching announcements: $e');
    }
  }

  /// Fetch announcements in background for next time
  void _fetchAnnouncementsInBackground(
    String? department,
    String? timeFilter,
    String? userLevel,
    bool includeScheduledAndExpired,
    int limit,
    String cacheKey,
  ) async {
    try {
      final announcements = await _repo.fetchAnnouncements(
        department: department,
        timeFilter: timeFilter,
        userLevel: userLevel,
        includeScheduledAndExpired: includeScheduledAndExpired,
        limit: limit,
        startAfterDocument: null,
      );

      // Update cache with fresh data
      _cacheAnnouncements(cacheKey, announcements);
      print('✅ Background refresh completed for key: $cacheKey');
    } catch (e) {
      print('❌ Background refresh failed: $e');
    }
  }

  /// Force refresh announcements (bypass cache)
  Future<void> forceRefresh() async {
    await fetchAnnouncements(
      department: state.currentDepartmentFilter,
      timeFilter: state.currentTimeFilter,
      userLevel: state.currentUserLevel,
      forceRefresh: true,
    );
  }
}
