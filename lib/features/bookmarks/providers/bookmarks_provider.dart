import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/bookmarks/services/bookmarks_service.dart';
import 'package:pivot/features/bookmarks/repositories/bookmarks_repository.dart';

// Services
final bookmarksServiceProvider = Provider<BookmarksService>((ref) {
  return BookmarksService();
});

// Repositories
final bookmarksRepositoryProvider = Provider<BookmarksRepository>((ref) {
  final service = ref.watch(bookmarksServiceProvider);
  return BookmarksRepository(service);
});

// State classes
class BookmarksState {
  final bool isLoading;
  final String? error;
  final List<String> bookmarks;
  final List<Map<String, dynamic>> bookmarkedItems;
  final Map<String, dynamic>? statistics;
  final String searchQuery;
  final String? selectedType;
  final bool hasBookmarks;

  const BookmarksState({
    this.isLoading = false,
    this.error,
    this.bookmarks = const [],
    this.bookmarkedItems = const [],
    this.statistics,
    this.searchQuery = '',
    this.selectedType,
    this.hasBookmarks = false,
  });

  BookmarksState copyWith({
    bool? isLoading,
    String? error,
    List<String>? bookmarks,
    List<Map<String, dynamic>>? bookmarkedItems,
    Map<String, dynamic>? statistics,
    String? searchQuery,
    String? selectedType,
    bool? hasBookmarks,
  }) {
    return BookmarksState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      bookmarks: bookmarks ?? this.bookmarks,
      bookmarkedItems: bookmarkedItems ?? this.bookmarkedItems,
      statistics: statistics ?? this.statistics,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
      hasBookmarks: hasBookmarks ?? this.hasBookmarks,
    );
  }
}

// Notifier
class BookmarksNotifier extends StateNotifier<BookmarksState> {
  final BookmarksRepository _repository;

  BookmarksNotifier(this._repository) : super(const BookmarksState());

  // Get user bookmarks
  Future<void> getUserBookmarks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bookmarks = await _repository.getUserBookmarks();
      state = state.copyWith(
        isLoading: false,
        bookmarks: bookmarks,
        hasBookmarks: bookmarks.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get bookmarked items with details
  Future<void> getBookmarkedItemsDetails() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repository.getBookmarkedItemsDetails();
      state = state.copyWith(isLoading: false, bookmarkedItems: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Check if item is bookmarked
  Future<bool> isBookmarked(String itemId) async {
    try {
      return await _repository.isBookmarked(itemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Add bookmark
  Future<bool> addBookmark(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.addBookmark(itemId);
      if (success) {
        await getUserBookmarks(); // Refresh bookmarks
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Remove bookmark
  Future<bool> removeBookmark(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.removeBookmark(itemId);
      if (success) {
        await getUserBookmarks(); // Refresh bookmarks
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Toggle bookmark
  Future<bool> toggleBookmark(String itemId) async {
    // Optimistic update - update UI immediately
    final isCurrentlyBookmarked = state.bookmarks.contains(itemId);
    final updatedBookmarks = List<String>.from(state.bookmarks);

    if (isCurrentlyBookmarked) {
      updatedBookmarks.remove(itemId);
    } else {
      updatedBookmarks.add(itemId);
    }

    // Update state immediately for instant UI feedback
    state = state.copyWith(bookmarks: updatedBookmarks, error: null);

    // Run the actual operation in the background
    try {
      final success = await _repository.toggleBookmark(itemId);

      if (!success) {
        // Rollback on failure
        if (mounted) {
          state = state.copyWith(bookmarks: state.bookmarks);
          await getUserBookmarks(); // Refresh to get correct state
        }
      }

      return success;
    } catch (e) {
      // Rollback on error
      if (mounted) {
        state = state.copyWith(bookmarks: state.bookmarks, error: e.toString());
        await getUserBookmarks(); // Refresh to get correct state
      }
      return false;
    }
  }

  // Add multiple bookmarks
  Future<bool> addMultipleBookmarks(List<String> itemIds) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.addMultipleBookmarks(itemIds);
      if (success) {
        await getUserBookmarks(); // Refresh bookmarks
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Remove multiple bookmarks
  Future<bool> removeMultipleBookmarks(List<String> itemIds) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.removeMultipleBookmarks(itemIds);
      if (success) {
        await getUserBookmarks(); // Refresh bookmarks
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Clear all bookmarks
  Future<bool> clearAllBookmarks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.clearAllBookmarks();
      if (success) {
        await getUserBookmarks(); // Refresh bookmarks
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Search bookmarks
  Future<void> searchBookmarks(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final bookmarks = await _repository.searchBookmarks(query);
      state = state.copyWith(isLoading: false, bookmarks: bookmarks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get bookmarks by type
  Future<void> getBookmarksByType(String type) async {
    state = state.copyWith(isLoading: true, error: null, selectedType: type);
    try {
      final bookmarks = await _repository.getBookmarksByType(type);
      state = state.copyWith(isLoading: false, bookmarks: bookmarks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get bookmarks statistics
  Future<void> getBookmarksStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statistics = await _repository.getBookmarksStatistics();
      state = state.copyWith(isLoading: false, statistics: statistics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Export bookmarks
  Future<Map<String, dynamic>> exportBookmarks() async {
    try {
      return await _repository.exportBookmarks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {};
    }
  }

  // Import bookmarks
  Future<bool> importBookmarks(List<String> bookmarkIds) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.importBookmarks(bookmarkIds);
      if (success) {
        await getUserBookmarks(); // Refresh bookmarks
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Sync bookmarks
  Future<bool> syncBookmarks(List<String> newBookmarks) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.syncBookmarks(newBookmarks);
      if (success) {
        await getUserBookmarks(); // Refresh bookmarks
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Filter bookmarks locally
  void filterBookmarks({String? query, String? type}) {
    List<String> filtered = state.bookmarks;

    // Filter by search query
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      filtered =
          filtered.where((bookmark) {
            return bookmark.toLowerCase().contains(lowercaseQuery);
          }).toList();
    }

    // Filter by type
    if (type != null && type.isNotEmpty) {
      // This would need to be implemented based on the actual bookmark data
      // For now, we'll just filter by the query
    }

    state = state.copyWith(
      bookmarks: filtered,
      searchQuery: query ?? state.searchQuery,
      selectedType: type ?? state.selectedType,
    );
  }

  // Clear filters
  void clearFilters() {
    state = state.copyWith(searchQuery: '', selectedType: null);
  }
}

// Providers
final bookmarksProvider =
    AutoDisposeStateNotifierProvider<BookmarksNotifier, BookmarksState>((ref) {
      final repository = ref.watch(bookmarksRepositoryProvider);
      return BookmarksNotifier(repository);
    });

// Convenience providers for specific data
final bookmarksListProvider = AutoDisposeProvider<List<String>>((ref) {
  final state = ref.watch(bookmarksProvider);
  return state.bookmarks;
});

final bookmarkedItemsProvider = AutoDisposeProvider<List<Map<String, dynamic>>>(
  (ref) {
    final state = ref.watch(bookmarksProvider);
    return state.bookmarkedItems;
  },
);

final bookmarksStatisticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(bookmarksProvider);
  return state.statistics;
});

final bookmarksSearchQueryProvider = AutoDisposeProvider<String>((ref) {
  final state = ref.watch(bookmarksProvider);
  return state.searchQuery;
});

final bookmarksSelectedTypeProvider = AutoDisposeProvider<String?>((ref) {
  final state = ref.watch(bookmarksProvider);
  return state.selectedType;
});

final bookmarksHasBookmarksProvider = AutoDisposeProvider<bool>((ref) {
  final state = ref.watch(bookmarksProvider);
  return state.hasBookmarks;
});
