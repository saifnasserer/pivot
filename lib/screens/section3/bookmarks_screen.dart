import 'package:flutter/material.dart';
import 'package:pivot/providers/bookmarks.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:pivot/screens/section3/profile_widgets/bookmark_card.dart';
import 'package:provider/provider.dart';
import 'package:pivot/widgets/no_internet_message.dart';
import 'package:pivot/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simplified BookmarksScreen with permanent search bar
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    // Clear search when screen is initialized
    _clearSearch();

    // Listen for focus changes
    _searchFocusNode.addListener(_onSearchFocusChanged);
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

  // Fetches announcements and re-orders them to match the bookmarking order.
  Future<List<AnnouncementData>> _fetchBookmarkedAnnouncements(
    List<String> ids,
  ) async {
    if (ids.isEmpty) {
      return [];
    }

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

    return sortedAnnouncements;
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

  Widget _buildBookmarksList(
    List<AnnouncementData> bookmarkedItems,
    Bookmarks bookmarksProvider,
  ) {
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
          onRemove: () {
            if (bookmark.id != null && bookmark.id!.isNotEmpty) {
              bookmarksProvider.toggleBookmark(bookmark.id!);
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
            child: Consumer<Bookmarks>(
              builder: (context, bookmarksProvider, child) {
                // Show loading state
                if (bookmarksProvider.isLoading) {
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
                if (bookmarksProvider.error != null) {
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
                          bookmarksProvider.error!,
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
                          onPressed: () => bookmarksProvider.refreshBookmarks(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                // Reverse the list of IDs to show the most recently bookmarked first.
                final bookmarkIds =
                    bookmarksProvider.bookmarkIds.reversed.toList();

                if (bookmarkIds.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    // Search bar
                    _buildSearchBar(),

                    // Bookmarks list
                    Expanded(
                      child: FutureBuilder<List<AnnouncementData>>(
                        future: _fetchBookmarkedAnnouncements(bookmarkIds),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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

                          return _buildBookmarksList(
                            filteredBookmarks,
                            bookmarksProvider,
                          );
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
