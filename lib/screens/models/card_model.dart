import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/widgets/comment_section.dart';
import 'package:pivot/features/bookmarks/providers/bookmarks_provider.dart';

class CardModel extends ConsumerStatefulWidget {
  final String? id;
  final String title;
  final String date;
  final Color color;
  final String description;
  final List<String> tags;
  final String? imageUrl;
  final String? doctorName;
  final bool isDoctorCard;
  final List<String> imageUrls;
  final List<Map<String, String>> links;
  final DateTime? publishAt;
  final DateTime? expireAt;
  final double? availableHeight; // New parameter for available height

  const CardModel({
    super.key,
    required this.id,
    required this.title,
    required this.date,
    required this.color,
    required this.description,
    required this.tags,
    this.imageUrl,
    this.doctorName,
    this.isDoctorCard = false,
    this.imageUrls = const [],
    this.links = const [],
    this.publishAt,
    this.expireAt,
    this.availableHeight, // New parameter
  });

  @override
  ConsumerState<CardModel> createState() => _CardModelState();
}

class _CardModelState extends ConsumerState<CardModel> {
  // State variables
  int _currentPage = 0;
  List<Widget> _contentPages = [];
  final PageController _cardPageController = PageController();
  bool _bookmarksLoadAttempted = false;

  @override
  void initState() {
    super.initState();
    _cardPageController.addListener(() {
      final page = _cardPageController.page?.round() ?? 0;
      if (page != _currentPage && mounted) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  // Simple text splitting based on available height
  List<Widget> _splitTextIntoChunks(
    String text,
    double maxHeight,
    double maxWidth,
  ) {
    final List<Widget> textChunks = [];
    final fontSize = Responsive.text(context, size: TextSize.medium);

    final textStyle = TextStyle(fontSize: fontSize, height: 1.2);

    // Check if entire text fits
    final fullTextSpan = TextSpan(text: text, style: textStyle);
    final fullTextPainter = TextPainter(
      text: fullTextSpan,
      textDirection: TextDirection.rtl,
      maxLines: null,
    );
    fullTextPainter.layout(maxWidth: maxWidth);

    if (fullTextPainter.height <= maxHeight) {
      return [Text(text, textAlign: TextAlign.right, style: textStyle)];
    }

    // Split by words
    final words = text.split(' ');
    String currentChunk = '';

    for (final word in words) {
      final testChunk = currentChunk.isEmpty ? word : '$currentChunk $word';

      final testSpan = TextSpan(text: testChunk, style: textStyle);
      final testPainter = TextPainter(
        text: testSpan,
        textDirection: TextDirection.rtl,
        maxLines: null,
      );
      testPainter.layout(maxWidth: maxWidth);

      if (testPainter.height > maxHeight && currentChunk.isNotEmpty) {
        textChunks.add(
          Text(
            currentChunk.trim(),
            textAlign: TextAlign.right,
            style: textStyle,
          ),
        );
        currentChunk = word;
      } else {
        currentChunk = testChunk;
      }
    }

    if (currentChunk.isNotEmpty) {
      textChunks.add(
        Text(currentChunk.trim(), textAlign: TextAlign.right, style: textStyle),
      );
    }

    return textChunks;
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Page indicator (only if multiple pages)
        if (_contentPages.length > 1)
          Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.space(context, size: Space.small),
            ),
            child: _buildUltraCompactPageIndicator(),
          ),

        // Title text
        Text(
          widget.title,
          textAlign: TextAlign.right,
          maxLines: 2,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.heading),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDate() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Date text bar flowing out from calendar
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.small) * 1.5,
            vertical: Responsive.space(context, size: Space.small) * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
          ),
          child: Text(
            widget.date,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.8),
              fontSize: Responsive.text(context, size: TextSize.small) * 0.9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Builds the horizontally scrolling image gallery
  Widget _buildImageGallery(BuildContext context) {
    return Container(
      height: Responsive.space(context, size: Space.large) * 2,
      margin: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // To support RTL
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = widget.imageUrls[index];
          return Padding(
            padding: EdgeInsets.only(
              left: Responsive.space(context, size: Space.small),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => FullScreenImageViewer(imageUrl: imageUrl),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                child: Hero(
                  tag: imageUrl,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: Responsive.space(context, size: Space.large) * 2,
                    height: Responsive.space(context, size: Space.large) * 2,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          width: Responsive.space(context, size: Space.large),
                          height: Responsive.space(context, size: Space.large),
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          width: Responsive.space(context, size: Space.large),
                          height: Responsive.space(context, size: Space.large),
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Builds the list of tappable links
  Widget _buildLinksList(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            widget.links.map((link) {
              return Padding(
                padding: EdgeInsets.only(
                  top: Responsive.space(context, size: Space.small),
                ),
                child: InkWell(
                  onTap: () async {
                    final urlString = link['url'];
                    if (urlString == null || urlString.isEmpty) return;

                    // Ensure the URL has a scheme (https preferred, convert http to https)
                    String formattedUrl = urlString;
                    if (!formattedUrl.startsWith('https://')) {
                      formattedUrl = formattedUrl.replaceFirst(
                        RegExp(r'^http://'),
                        'https://',
                      );
                      if (!formattedUrl.startsWith('https://')) {
                        formattedUrl = 'https://$formattedUrl';
                      }
                    }

                    final url = Uri.parse(formattedUrl);

                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تعذر فتح الرابط: $urlString')),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          Responsive.space(context, size: Space.small) * 1.5,
                      vertical:
                          Responsive.space(context, size: Space.small) * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          link['title'] ?? 'رابط',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.small),
                        ),
                        Icon(
                          Icons.link,
                          color: Colors.black.withOpacity(0.6),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // Enhanced ultra-compact indicator with better styling
  Widget _buildUltraCompactPageIndicator() {
    if (_contentPages.length <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Enhanced dots with better visual feedback
        ...List.generate(_contentPages.length, (index) {
          final reversedIndex = _contentPages.length - 1 - index;
          final isActive = _currentPage == reversedIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 12 : 6,
            height: 6,
            decoration: BoxDecoration(
              color:
                  isActive
                      ? Colors.black.withOpacity(0.8)
                      : Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(3),
              boxShadow:
                  isActive
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ]
                      : null,
            ),
          );
        }),

        SizedBox(width: Responsive.space(context, size: Space.small)),

        // Enhanced page counter
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.tiny),
            vertical: Responsive.space(context, size: Space.tiny) / 2,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.tiny),
            ),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
          ),
          child: Text(
            '${_currentPage + 1}/${_contentPages.length}',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small) * 0.7,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isScheduled =
        widget.publishAt != null && widget.publishAt!.isAfter(now);
    final isExpired = widget.expireAt != null && widget.expireAt!.isBefore(now);

    // Calculate available height for content
    final availableHeight =
        widget.availableHeight ?? Responsive.height(context) * 0.8;

    // Calculate content height (subtract title, footer, and padding)
    final titleHeight =
        Responsive.text(context, size: TextSize.heading) * 2.4 +
        Responsive.space(context, size: Space.medium);
    final footerHeight = Responsive.space(context, size: Space.large) * 3;
    final padding = Responsive.space(context, size: Space.large) * 2;
    final contentHeight =
        availableHeight - titleHeight - footerHeight - padding;

    // Generate content pages if not already generated
    if (_contentPages.isEmpty) {
      final maxWidth =
          Responsive.width(context) -
          (Responsive.space(context, size: Space.large) * 4);

      // Split description into chunks
      final descriptionChunks = _splitTextIntoChunks(
        widget.description,
        contentHeight * 0.8, // Use 80% of content height for description
        maxWidth,
      );

      // Create pages
      final List<Widget> pages = [];

      // Add description chunks
      for (final chunk in descriptionChunks) {
        pages.add(
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [chunk],
            ),
          ),
        );
      }

      // Add images and links to the last page
      if (widget.imageUrls.isNotEmpty || widget.links.isNotEmpty) {
        final lastPage = pages.isNotEmpty ? pages.last : Container();
        final List<Widget> lastPageChildren = [];

        if (lastPage is Container && lastPage.child is Column) {
          final column = lastPage.child as Column;
          lastPageChildren.addAll(column.children);
        }

        if (widget.imageUrls.isNotEmpty) {
          lastPageChildren.add(
            SizedBox(height: Responsive.space(context, size: Space.medium)),
          );
          lastPageChildren.add(_buildImageGallery(context));
        }

        if (widget.links.isNotEmpty) {
          lastPageChildren.add(
            SizedBox(height: Responsive.space(context, size: Space.medium)),
          );
          lastPageChildren.add(_buildLinksList(context));
        }

        // Add date to the last page
        lastPageChildren.add(
          SizedBox(height: Responsive.space(context, size: Space.small)),
        );
        lastPageChildren.add(_buildDate());

        if (pages.isNotEmpty) {
          pages[pages.length - 1] = Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: lastPageChildren,
            ),
          );
        }
      } else {
        // Add date to the last page if no images/links
        if (pages.isNotEmpty) {
          final lastPage = pages.last;
          if (lastPage is Container && lastPage.child is Column) {
            final column = lastPage.child as Column;
            final children = List<Widget>.from(column.children);
            children.add(
              SizedBox(height: Responsive.space(context, size: Space.small)),
            );
            children.add(_buildDate());

            pages[pages.length - 1] = Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            );
          }
        }
      }

      _contentPages = pages;
    }

    return Container(
      margin: EdgeInsets.all(Responsive.space(context, size: Space.small)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        color:
            isExpired
                ? Colors.grey.withOpacity(0.15)
                : widget.color.withValues(alpha: 0.15),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: availableHeight),
        child: Padding(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Visual indicator for scheduled/expired
              if (isScheduled)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.schedule, color: Colors.blue, size: 18),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      'مجدول',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                      ),
                    ),
                  ],
                ),
              if (isExpired)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.event_busy, color: Colors.grey, size: 18),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      'منتهي',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                      ),
                    ),
                  ],
                ),

              // Title
              _buildTitle(),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Content area
              Expanded(
                child:
                    _contentPages.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : PageView(
                          controller: _cardPageController,
                          scrollDirection: Axis.horizontal,
                          reverse: true, // RTL support
                          children: _contentPages,
                        ),
              ),

              // Footer
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
                        vertical: Responsive.space(context, size: Space.small),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (!mounted) return;

                              String shareText = '';
                              shareText += '\n\n${widget.title}';

                              if (widget.description.isNotEmpty) {
                                shareText += '\n\n${widget.description}';
                              }

                              if (widget.links.isNotEmpty) {
                                shareText += '\n\nالروابط:';
                                for (var link in widget.links) {
                                  shareText +=
                                      '\n- ${link['title']}: ${link['url']}';
                                }
                              }

                              if (mounted) {
                                await Share.share(shareText);
                              }
                            },
                            icon: const Icon(Icons.share),
                            splashRadius: 24,
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          IconButton(
                            onPressed: () {
                              if (!mounted) return;

                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                enableDrag: true,
                                isDismissible: true,
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(
                                      Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                  ),
                                ),
                                builder:
                                    (context) => DraggableScrollableSheet(
                                      initialChildSize: 0.9,
                                      minChildSize: 0.5,
                                      maxChildSize: 0.95,
                                      expand: false,
                                      builder:
                                          (context, scrollController) =>
                                              CommentSection(
                                                announcementId: widget.id!,
                                                scrollController:
                                                    scrollController,
                                              ),
                                    ),
                              );
                            },
                            icon: const Icon(Icons.question_mark_rounded),
                            splashRadius: 24,
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Builder(
                            builder: (context) {
                              // Check if widget is mounted first
                              if (!mounted) {
                                return IconButton(
                                  onPressed: null,
                                  icon: const Icon(
                                    Icons.bookmark_border,
                                    color: Colors.grey,
                                  ),
                                  splashRadius: 24,
                                );
                              }

                              // Use Riverpod Consumer for bookmarks
                              return Consumer(
                                builder: (context, ref, child) {
                                  // Final mounted check
                                  if (!mounted) {
                                    return IconButton(
                                      onPressed: null,
                                      icon: const Icon(
                                        Icons.bookmark_border,
                                        color: Colors.grey,
                                      ),
                                      splashRadius: 24,
                                    );
                                  }

                                  final bookmarksState = ref.watch(
                                    bookmarksProvider,
                                  );
                                  final bool isBookmarked = bookmarksState
                                      .bookmarks
                                      .contains(widget.id);

                                  // Debug: Print bookmark state when it changes
                                  if (widget.id != null &&
                                      bookmarksState.bookmarks.isNotEmpty) {
                                    print(
                                      'Bookmark state for ${widget.id}: $isBookmarked (${bookmarksState.bookmarks.length} total bookmarks)',
                                    );
                                  }

                                  // Bookmarks will automatically update UI through ref.watch

                                  // Load bookmarks if not loaded yet (only once per widget lifecycle)
                                  if (!_bookmarksLoadAttempted &&
                                      bookmarksState.bookmarks.isEmpty &&
                                      !bookmarksState.isLoading &&
                                      bookmarksState.error == null) {
                                    _bookmarksLoadAttempted = true;
                                    // Use a post-frame callback to avoid setState during build
                                    WidgetsBinding.instance.addPostFrameCallback((
                                      _,
                                    ) async {
                                      if (mounted) {
                                        try {
                                          await ref
                                              .read(bookmarksProvider.notifier)
                                              .getUserBookmarks();
                                        } catch (e) {
                                          // Ignore errors if widget is disposed
                                          if (mounted) {
                                            print(
                                              'Error loading bookmarks: $e',
                                            );
                                          }
                                        }
                                      }
                                    });
                                  }

                                  return IconButton(
                                    onPressed:
                                        bookmarksState.isLoading
                                            ? null
                                            : () async {
                                              // Final mounted check before action
                                              if (!mounted) return;

                                              try {
                                                // Load bookmarks if not loaded yet (only on first button press)
                                                if (bookmarksState
                                                    .bookmarks
                                                    .isEmpty) {
                                                  await ref
                                                      .read(
                                                        bookmarksProvider
                                                            .notifier,
                                                      )
                                                      .getUserBookmarks();
                                                }

                                                await ref
                                                    .read(
                                                      bookmarksProvider
                                                          .notifier,
                                                    )
                                                    .toggleBookmark(widget.id!);

                                                // Show feedback to user
                                                if (mounted) {
                                                  final newState = ref.read(
                                                    bookmarksProvider,
                                                  );
                                                  final isNowBookmarked =
                                                      newState.bookmarks
                                                          .contains(widget.id);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        isNowBookmarked
                                                            ? 'تم إضافة المفضلة'
                                                            : 'تم إزالة المفضلة',
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'NotoSansArabic',
                                                        ),
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                      backgroundColor:
                                                          isNowBookmarked
                                                              ? Colors.green
                                                                  .withOpacity(
                                                                    0.8,
                                                                  )
                                                              : Colors.orange
                                                                  .withOpacity(
                                                                    0.8,
                                                                  ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                // Show error message to user
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'حدث خطأ في تحديث المفضلة',
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'NotoSansArabic',
                                                        ),
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 3,
                                                      ),
                                                      backgroundColor: Colors
                                                          .red
                                                          .withOpacity(0.8),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                    icon:
                                        bookmarksState.isLoading
                                            ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      Colors.black.withOpacity(
                                                        0.6,
                                                      ),
                                                    ),
                                              ),
                                            )
                                            : Icon(
                                              isBookmarked
                                                  ? Icons.bookmark
                                                  : Icons.bookmark_border,
                                              color:
                                                  isBookmarked
                                                      ? Colors.black
                                                      : Colors.black,
                                            ),
                                    splashRadius: 24,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Offset>? _animation;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.addListener(() {
      if (_animation != null && mounted) {
        setState(() {
          _dragOffset = _animation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // Only allow dragging when not scaled
    if (_transformationController.value.getMaxScaleOnAxis() <= 1.0 && mounted) {
      setState(() {
        _dragOffset += details.delta;
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_transformationController.value.getMaxScaleOnAxis() > 1.0) {
      return; // Don't dismiss if zoomed
    }

    final screenHeight = MediaQuery.of(context).size.height;
    // Dismiss if dragged down far enough or with enough velocity
    if ((details.primaryVelocity ?? 0) > 500 ||
        _dragOffset.dy > screenHeight / 4) {
      Navigator.of(context).pop();
    } else {
      // Animate back to center
      _animation = Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate background opacity based on drag distance
    final double opacity = (1.0 -
            (_dragOffset.dy.abs() / (MediaQuery.of(context).size.height / 2)))
        .clamp(0.4, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(opacity),
      body: Stack(
        children: [
          GestureDetector(
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: Transform.translate(
              offset: _dragOffset,
              child: Center(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: widget.imageUrl,
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      placeholder:
                          (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                      errorWidget:
                          (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: Responsive.space(context, size: Space.medium),
            left: Responsive.space(context, size: Space.medium),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 24.0,
              ),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttachmentListWidget extends StatelessWidget {
  final List<Map<String, String>> attachments;
  const AttachmentListWidget({super.key, required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        const Text('المرفقات:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...attachments.map(
          (att) => ListTile(
            leading: const Icon(Icons.attach_file),
            title: Text(att['title'] ?? ''),
            onTap: () async {
              final url = att['url'];
              if (url != null && await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
