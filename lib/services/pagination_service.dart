import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling paginated queries to reduce Firebase reads
class PaginationService {
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Get paginated query with cursor-based pagination
  static Query getPaginatedQuery({
    required Query baseQuery,
    DocumentSnapshot? lastDocument,
    int pageSize = defaultPageSize,
  }) {
    Query query = baseQuery.limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query;
  }

  /// Get paginated query with offset-based pagination (less efficient)
  /// Note: Firestore doesn't support offset, use cursor-based pagination instead
  static Query getOffsetPaginatedQuery({
    required Query baseQuery,
    int offset = 0,
    int pageSize = defaultPageSize,
  }) {
    // Firestore doesn't support offset, return limited query
    return baseQuery.limit(pageSize);
  }

  /// Process paginated results
  static PaginatedResult<T> processPaginatedResults<T>({
    required List<DocumentSnapshot> documents,
    required T Function(DocumentSnapshot) fromSnapshot,
    int pageSize = defaultPageSize,
  }) {
    final items = documents.map(fromSnapshot).toList();
    final hasMore = documents.length == pageSize;
    final lastDocument = documents.isNotEmpty ? documents.last : null;

    return PaginatedResult<T>(
      items: items,
      hasMore: hasMore,
      lastDocument: lastDocument,
      totalCount: items.length,
    );
  }

  /// Get next page query
  static Query? getNextPageQuery({
    required Query baseQuery,
    DocumentSnapshot? lastDocument,
    int pageSize = defaultPageSize,
  }) {
    if (lastDocument == null) return null;

    return getPaginatedQuery(
      baseQuery: baseQuery,
      lastDocument: lastDocument,
      pageSize: pageSize,
    );
  }
}

/// Result class for paginated data
class PaginatedResult<T> {
  final List<T> items;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final int totalCount;

  PaginatedResult({
    required this.items,
    required this.hasMore,
    this.lastDocument,
    required this.totalCount,
  });

  /// Check if there are more pages
  bool get hasNextPage => hasMore && lastDocument != null;

  /// Get next page query
  Query? getNextPageQuery(
    Query baseQuery, {
    int pageSize = PaginationService.defaultPageSize,
  }) {
    return PaginationService.getNextPageQuery(
      baseQuery: baseQuery,
      lastDocument: lastDocument,
      pageSize: pageSize,
    );
  }
}

/// Mixin for providers that need pagination
mixin PaginationMixin<T> {
  final List<T> _allItems = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  List<T> get allItems => _allItems;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// Load initial page
  Future<void> loadInitialPage({
    required Query baseQuery,
    required T Function(DocumentSnapshot) fromSnapshot,
    int pageSize = PaginationService.defaultPageSize,
  }) async {
    _allItems.clear();
    _lastDocument = null;
    _hasMore = true;
    _isLoadingMore = false;

    await _loadPage(
      baseQuery: baseQuery,
      fromSnapshot: fromSnapshot,
      pageSize: pageSize,
    );
  }

  /// Load next page
  Future<void> loadNextPage({
    required Query baseQuery,
    required T Function(DocumentSnapshot) fromSnapshot,
    int pageSize = PaginationService.defaultPageSize,
  }) async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    await _loadPage(
      baseQuery: baseQuery,
      fromSnapshot: fromSnapshot,
      pageSize: pageSize,
    );
    _isLoadingMore = false;
  }

  /// Internal method to load a page
  Future<void> _loadPage({
    required Query baseQuery,
    required T Function(DocumentSnapshot) fromSnapshot,
    required int pageSize,
  }) async {
    final query = PaginationService.getPaginatedQuery(
      baseQuery: baseQuery,
      lastDocument: _lastDocument,
      pageSize: pageSize,
    );

    final snapshot = await query.get();
    final result = PaginationService.processPaginatedResults(
      documents: snapshot.docs,
      fromSnapshot: fromSnapshot,
      pageSize: pageSize,
    );

    _allItems.addAll(result.items);
    _lastDocument = result.lastDocument;
    _hasMore = result.hasMore;
  }

  /// Refresh data (reload from beginning)
  Future<void> refresh({
    required Query baseQuery,
    required T Function(DocumentSnapshot) fromSnapshot,
    int pageSize = PaginationService.defaultPageSize,
  }) async {
    await loadInitialPage(
      baseQuery: baseQuery,
      fromSnapshot: fromSnapshot,
      pageSize: pageSize,
    );
  }

  /// Clear all data
  void clear() {
    _allItems.clear();
    _lastDocument = null;
    _hasMore = true;
    _isLoadingMore = false;
  }
}
