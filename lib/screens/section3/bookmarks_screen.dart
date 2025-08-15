import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pivot/providers/bookmarks.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:pivot/screens/section3/profile_widgets/bookmark_card.dart';
import 'package:provider/provider.dart';
import 'package:pivot/widgets/no_internet_message.dart';

/// Simplified BookmarksScreen with permanent search bar
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          print('Error parsing announcement ${doc.id}: $e');
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
        print('Error filtering bookmark: $e');
        return false;
      }
    }).toList();
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'سيرش',
          hintTextDirection: TextDirection.rtl,
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                  : const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(
            Responsive.space(context, size: Space.small),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
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
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
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
          print('Error accessing bookmark properties: $e');
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
            // Clear search when card is tapped with a small delay
            if (_searchQuery.isNotEmpty) {
              // Add a small delay to ensure UI updates properly
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                }
              });
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NoInternetMessage(
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
                      fontSize: Responsive.text(context, size: TextSize.medium),
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
          final bookmarkIds = bookmarksProvider.bookmarkIds.reversed.toList();

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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
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
                                b.colorValue != 0; // Basic color validation
                            return hasValidTitle &&
                                hasValidDescription &&
                                hasValidColor;
                          } catch (e) {
                            print('Invalid bookmark data: $e');
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
    );
  }
}
