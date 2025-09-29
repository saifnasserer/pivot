import 'package:pivot/features/bookmarks/services/bookmarks_service.dart';

class BookmarksRepository {
  final BookmarksService _bookmarksService;

  BookmarksRepository(this._bookmarksService);

  // Get user's bookmarks
  Future<List<String>> getUserBookmarks() async {
    return await _bookmarksService.getUserBookmarks();
  }

  // Check if item is bookmarked
  Future<bool> isBookmarked(String itemId) async {
    return await _bookmarksService.isBookmarked(itemId);
  }

  // Add bookmark
  Future<bool> addBookmark(String itemId) async {
    return await _bookmarksService.addBookmark(itemId);
  }

  // Remove bookmark
  Future<bool> removeBookmark(String itemId) async {
    return await _bookmarksService.removeBookmark(itemId);
  }

  // Toggle bookmark
  Future<bool> toggleBookmark(String itemId) async {
    return await _bookmarksService.toggleBookmark(itemId);
  }

  // Add multiple bookmarks
  Future<bool> addMultipleBookmarks(List<String> itemIds) async {
    return await _bookmarksService.addMultipleBookmarks(itemIds);
  }

  // Remove multiple bookmarks
  Future<bool> removeMultipleBookmarks(List<String> itemIds) async {
    return await _bookmarksService.removeMultipleBookmarks(itemIds);
  }

  // Clear all bookmarks
  Future<bool> clearAllBookmarks() async {
    return await _bookmarksService.clearAllBookmarks();
  }

  // Get bookmarked items with details
  Future<List<Map<String, dynamic>>> getBookmarkedItemsDetails() async {
    return await _bookmarksService.getBookmarkedItemsDetails();
  }

  // Search bookmarks
  Future<List<String>> searchBookmarks(String query) async {
    return await _bookmarksService.searchBookmarks(query);
  }

  // Get bookmarks by type
  Future<List<String>> getBookmarksByType(String type) async {
    return await _bookmarksService.getBookmarksByType(type);
  }

  // Get bookmarks statistics
  Future<Map<String, dynamic>> getBookmarksStatistics() async {
    return await _bookmarksService.getBookmarksStatistics();
  }

  // Export bookmarks
  Future<Map<String, dynamic>> exportBookmarks() async {
    return await _bookmarksService.exportBookmarks();
  }

  // Import bookmarks
  Future<bool> importBookmarks(List<String> bookmarkIds) async {
    return await _bookmarksService.importBookmarks(bookmarkIds);
  }

  // Sync bookmarks (merge with existing)
  Future<bool> syncBookmarks(List<String> newBookmarks) async {
    return await _bookmarksService.syncBookmarks(newBookmarks);
  }
}
