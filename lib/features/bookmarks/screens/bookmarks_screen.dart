import 'package:flutter/material.dart';
import 'package:pivot/features/bookmarks/screens/bookmark_card.dart';
import 'package:pivot/features/home/screens/adminstration/models/announcement_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/widgets/no_internet_message.dart';
import 'package:pivot/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/features/bookmarks/providers/bookmarks_provider.dart';

/// Simplified BookmarksScreen with permanent search bar
class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchActive = false;
  bool _bookmarksLoaded = false;

  // Local-first: Cache fetched announcements
  List<AnnouncementData>? _cachedAnnouncements;
  List<String>? _cachedBookmarkIds;

  @override
  void initState() {
    super.initState();
    // Clear search when screen is initialized
    _clearSearch();

    // Listen for focus changes
    _searchFocusNode.addListener(_onSearchFocusChanged);

    // Load bookmarks when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_bookmarksLoaded) {
        _loadBookmarks();
      }
    });
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      _onSearchFocusLost();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear search when screen becomes visible again
    if (ModalRoute.of(context)?.isCurrent == true) {
      // Screen is now current, ensure search is cleared
      if (_isSearchActive && _searchQuery.isEmpty) {
        _clearSearch();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _isSearchActive = false;
      _searchController.clear();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _isSearchActive = value.isNotEmpty;
    });
  }

  void _onSearchFocusLost() {
    // Only deactivate if search is empty
    if (_searchQuery.isEmpty) {
      setState(() {
        _isSearchActive = false;
      });
    }
  }

  Future<void> _loadBookmarks() async {
    if (!mounted || _bookmarksLoaded) return;

    try {
      setState(() {
        _bookmarksLoaded = true;
      });

      await ref.read(bookmarksProvider.notifier).getUserBookmarks();
    } catch (e) {
      // Reset the flag on error so we can retry
      if (mounted) {
        setState(() {
          _bookmarksLoaded = false;
        });
      }
    }
  }

  // Local-first: Smart fetch that uses cache when possible
  Future<List<AnnouncementData>> _fetchBookmarkedAnnouncementsSmart(
    List<String> ids,
  ) async {
    if (ids.isEmpty) {
      return [];
    }

    // Check if we can use cached data
    final bool cacheValid =
        _cachedAnnouncements != null &&
        _cachedBookmarkIds != null &&
        _listEquals(ids, _cachedBookmarkIds!);

    if (cacheValid) {
      print(
        '✅ BookmarksTab: Using cached announcements (${_cachedAnnouncements!.length} items) - Zero reads',
      );
      return _cachedAnnouncements!;
    }

    // Cache miss or bookmark IDs changed - fetch from Firestore
    print('🔄 BookmarksTab: Fetching ${ids.length} bookmarked items...');

    final announcementsRef = FirebaseFirestore.instance.collection(
      'announcements',
    );
    final List<AnnouncementData> fetchedAnnouncements = [];

    // Chunk the IDs into lists of 10 to respect Firestore's 'whereIn' limit.
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final querySnapshot =
          await announcementsRef
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
      for (var doc in querySnapshot.docs) {
        try {
          final announcement = AnnouncementData.fromFirestore(doc);
          fetchedAnnouncements.add(announcement);
        } catch (e) {
          // Skip this announcement if it can't be parsed
        }
      }
    }

    // Re-order the fetched announcements to match the order of the bookmark IDs.
    final announcementsMap = {
      for (var announcement in fetchedAnnouncements)
        announcement.id: announcement,
    };
    final sortedAnnouncements =
        ids
            .map((id) => announcementsMap[id])
            .where((announcement) => announcement != null)
            .cast<AnnouncementData>()
            .toList();

    // Update cache
    setState(() {
      _cachedAnnouncements = sortedAnnouncements;
      _cachedBookmarkIds = List.from(ids);
    });

    print('✅ BookmarksTab: Cached ${sortedAnnouncements.length} items');

    return sortedAnnouncements;
  }

  // Helper to compare lists
  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  List<AnnouncementData> _filterBookmarks(List<AnnouncementData> bookmarks) {
    if (_searchQuery.isEmpty) {
      return bookmarks;
    }

    final query = _searchQuery.toLowerCase();
    return bookmarks.where((bookmark) {
      try {
        return (bookmark.title).toLowerCase().contains(query) ||
            (bookmark.description).toLowerCase().contains(query) ||
            bookmark.tags.any((tag) => tag.toLowerCase().contains(query));
      } catch (e) {
        // If there's any error accessing bookmark properties, exclude it from results
        return false;
      }
    }).toList();
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        // Prevent the tap from bubbling up to the parent GestureDetector
        // This ensures tapping the search bar doesn't trigger "tap outside"
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
          vertical: Responsive.space(context, size: Space.small),
        ),
        decoration: BoxDecoration(
          color: _isSearchActive ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          border: Border.all(
            color:
                _isSearchActive ? Colors.blue.shade300 : Colors.grey.shade300,
            width: _isSearchActive ? 2 : 1,
          ),
          boxShadow:
              _isSearchActive
                  ? [
                    BoxShadow(
                      color: Colors.blue.shade100,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'البحث في المحفوظات...',
            hintTextDirection: TextDirection.rtl,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: Responsive.text(context, size: TextSize.medium),
            ),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                      onPressed: _clearSearch,
                    )
                    : Icon(Icons.search, color: Colors.grey.shade500),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(
              Responsive.space(context, size: Space.small),
            ),
          ),
          onChanged: _onSearchChanged,
          onTap: () {
            if (!_isSearchActive) {
              setState(() {
                _isSearchActive = true;
              });
            }
          },
          onSubmitted: (value) {
            // Deactivate search when user submits (presses enter)
            _onSearchFocusLost();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      message = 'لا توجد نتائج للبحث: "$_searchQuery"';
      icon = Icons.search_off;
    } else {
      message = 'لا توجد محفوظات بعد';
      icon = Icons.bookmark_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.large),
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey.shade400),
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          Text(
            message,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            ElevatedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('مسح البحث'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade400,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookmarksList(List<AnnouncementData> bookmarkedItems) {
    final filteredItems = _filterBookmarks(bookmarkedItems);

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.space(context, size: Space.medium),
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final bookmark = filteredItems[index];

        // Add null safety check
        try {
          if (bookmark.title.isEmpty || bookmark.description.isEmpty) {
            return const SizedBox.shrink(); // Skip invalid bookmarks
          }
        } catch (e) {
          return const SizedBox.shrink(); // Skip invalid bookmarks
        }

        return BookmarkCard(
          bookmark: bookmark,
          onRemove: () async {
            if (bookmark.id != null && bookmark.id!.isNotEmpty) {
              try {
                await ref
                    .read(bookmarksProvider.notifier)
                    .toggleBookmark(bookmark.id!);

                // Clear cache to force refresh
                setState(() {
                  _cachedAnnouncements = null;
                  _cachedBookmarkIds = null;
                });

                // Show feedback
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم إزالة من المفضلة',
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.orange.withOpacity(0.8),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'حدث خطأ في إزالة المفضلة',
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                      duration: const Duration(seconds: 3),
                      backgroundColor: Colors.red.withOpacity(0.8),
                    ),
                  );
                }
              }
            }
          },
          onCardTap: () {
            // Clear search when card is tapped to prevent null issues
            if (_isSearchActive) {
              _clearSearch();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop && _isSearchActive) {
          // Clear search when navigating back
          _clearSearch();
        }
      },
      child: FocusScope(
        onFocusChange: (hasFocus) {
          // This will be called when focus changes in the entire scope
          if (!hasFocus && _searchFocusNode.hasFocus) {
            _searchFocusNode.unfocus();
          }
        },
        child: GestureDetector(
          onTap: () {
            // Remove focus from search when tapping outside
            if (_searchFocusNode.hasFocus) {
              _searchFocusNode.unfocus();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: NoInternetMessage(
            child: Consumer(
              builder: (context, ref, child) {
                final bookmarksState = ref.watch(bookmarksProvider);

                // Listen for bookmark changes and refresh cache
                ref.listen(bookmarksProvider, (previous, next) {
                  if (previous?.bookmarks != next.bookmarks) {
                    // Bookmarks changed, clear cache to force refresh
                    setState(() {
                      _cachedAnnouncements = null;
                      _cachedBookmarkIds = null;
                    });
                  }
                });

                // Show loading state
                if (bookmarksState.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل المحفوظات...'),
                      ],
                    ),
                  );
                }

                // Show error state
                if (bookmarksState.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade400,
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        Text(
                          bookmarksState.error!,
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        ElevatedButton(
                          onPressed:
                              () =>
                                  ref
                                      .read(bookmarksProvider.notifier)
                                      .getUserBookmarks(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                // Reverse the list of IDs to show the most recently bookmarked first.
                final bookmarkIds = bookmarksState.bookmarks.reversed.toList();

                if (bookmarkIds.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    // Search bar
                    _buildSearchBar(),

                    // Bookmarks list with local-first caching
                    Expanded(
                      child: FutureBuilder<List<AnnouncementData>>(
                        future: _fetchBookmarkedAnnouncementsSmart(bookmarkIds),
                        builder: (context, snapshot) {
                          // Show cached data immediately while loading fresh data
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // If we have cached data, show it immediately
                            if (_cachedAnnouncements != null &&
                                _cachedAnnouncements!.isNotEmpty) {
                              return _buildBookmarksList(_cachedAnnouncements!);
                            }
                            // Otherwise show loading spinner (first time load)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red.shade400,
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.medium,
                                    ),
                                  ),
                                  Text(
                                    'حدث خطأ أثناء تحميل المحفوظات',
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return _buildEmptyState();
                          }

                          final bookmarkedItems = snapshot.data!;
                          // Defensive: filter out nulls and invalid items
                          final filteredBookmarks =
                              bookmarkedItems.where((b) {
                                try {
                                  // Test access to critical properties
                                  final hasValidTitle = b.title.isNotEmpty;
                                  final hasValidDescription =
                                      b.description.isNotEmpty;
                                  final hasValidColor =
                                      b.colorValue !=
                                      0; // Basic color validation
                                  return hasValidTitle &&
                                      hasValidDescription &&
                                      hasValidColor;
                                } catch (e) {
                                  return false;
                                }
                              }).toList();

                          return _buildBookmarksList(filteredBookmarks);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
