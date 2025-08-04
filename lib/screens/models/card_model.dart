import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/providers/bookmarks.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/widgets/comment_section.dart';

class CardModel extends StatefulWidget {
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
  });

  @override
  State<CardModel> createState() => _CardModelState();
}

class _CardModelState extends State<CardModel> {
  // State variables
  int _currentPage = 0;
  List<Widget> _contentPages = [];
  double _availableHeight = 0;
  bool _isExpanded = false;
  bool _isLinksExpanded = false;
  bool _isImagesExpanded = false;
  final PageController _cardPageController = PageController();

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

  void _generateContentPages(double availableHeight) {
    _contentPages.clear();
    _availableHeight = availableHeight;

    debugPrint('CardModel: Available height for content: $availableHeight');

    // Calculate fixed elements heights (title is in main layout, date is in content)
    final titleHeight = _calculateTitleHeight();
    final dateHeight = _calculateDateHeight();
    final footerHeight = _calculateFooterHeight();
    final padding =
        Responsive.space(context, size: Space.large) * 2; // Card padding

    // Calculate available space for content (date is now part of content distribution)
    final contentHeight =
        availableHeight - titleHeight - footerHeight - padding;

    debugPrint(
      'CardModel: Fixed elements - Title: $titleHeight, Footer: $footerHeight, Padding: $padding',
    );
    debugPrint('CardModel: Available content height: $contentHeight');

    // Create ONLY variable content widgets (description, images, links) + date
    final List<Widget> variableContentWidgets = [];

    // Description (variable height - this is what we distribute)
    variableContentWidgets.add(_buildDescription());

    // Images
    if (widget.imageUrls.isNotEmpty) {
      variableContentWidgets.add(
        SizedBox(height: Responsive.space(context, size: Space.medium)),
      );
      variableContentWidgets.add(_buildImageGallery(context));
    }

    // Links
    if (widget.links.isNotEmpty) {
      variableContentWidgets.add(
        SizedBox(height: Responsive.space(context, size: Space.medium)),
      );
      variableContentWidgets.add(_buildLinksList(context));
    }

    // Date widget (now part of content distribution)
    variableContentWidgets.add(
      SizedBox(height: Responsive.space(context, size: Space.small)),
    );
    variableContentWidgets.add(_buildDate());

    // Distribute ONLY variable content using the calculated content height
    final variableContentPages = _distributeContentWithFixedHeight(
      variableContentWidgets,
      contentHeight,
    );

    // Create final pages with ONLY variable content (no title/date)
    _contentPages =
        variableContentPages.map((variableContentPage) {
          return _buildFullPage(variableContentPage);
        }).toList();

    debugPrint(
      'CardModel: Generated ${_contentPages.length} pages for card ${widget.id}',
    );
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildFullPage(Widget variableContent) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Only variable content (description, images, links) - date is already included in variableContent
          Expanded(
            child: SingleChildScrollView(
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling within page
              child: variableContent,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTitleHeight() {
    // Title has max 2 lines
    final fontSize = Responsive.text(context, size: TextSize.heading);
    final lineHeight = fontSize * 1.2; // Approximate line height
    final maxLines = 2;
    return lineHeight * maxLines +
        Responsive.space(context, size: Space.medium);
  }

  double _calculateDateHeight() {
    // Date container has fixed height
    return Responsive.space(context, size: Space.large) * 1.5;
  }

  double _calculateFooterHeight() {
    // Footer now only includes buttons since page indicator moved to header
    final buttonsHeight = Responsive.space(context, size: Space.large) * 2.5;
    final footerPadding = Responsive.space(context, size: Space.medium);
    final bottomMargin = Responsive.space(context, size: Space.large);
    return buttonsHeight + footerPadding + bottomMargin;
  }

  List<Widget> _distributeContentWithFixedHeight(
    List<Widget> widgets,
    double maxContentHeight,
  ) {
    if (widgets.isEmpty) return [];

    final List<Widget> pages = [];
    final List<Widget> currentPageWidgets = [];
    double currentHeight = 0;

    // Use a larger safety margin to prevent overflow
    final safetyMargin = Responsive.space(context, size: Space.large);
    final effectiveMaxHeight = maxContentHeight - safetyMargin;

    debugPrint(
      'CardModel: Distributing content with maxContentHeight: $maxContentHeight, effectiveMaxHeight: $effectiveMaxHeight',
    );

    for (int i = 0; i < widgets.length; i++) {
      final widget = widgets[i];
      final widgetHeight = _calculateWidgetHeight(widget);

      debugPrint(
        'CardModel: Widget $i height: $widgetHeight, currentHeight: $currentHeight',
      );

      // If adding this widget would exceed the content height, start a new page
      if (currentHeight + widgetHeight > effectiveMaxHeight &&
          currentPageWidgets.isNotEmpty) {
        debugPrint(
          'CardModel: Starting new page at widget $i, currentHeight: $currentHeight',
        );
        pages.add(_buildContentPage(currentPageWidgets));
        currentPageWidgets.clear();
        currentHeight = 0;
      }

      currentPageWidgets.add(widget);
      currentHeight += widgetHeight;
    }

    // Add the last page
    if (currentPageWidgets.isNotEmpty) {
      debugPrint(
        'CardModel: Adding final page with ${currentPageWidgets.length} widgets, height: $currentHeight',
      );
      pages.add(_buildContentPage(currentPageWidgets));
    }

    // Ensure we always have at least one page
    if (pages.isEmpty) {
      debugPrint(
        'CardModel: No pages created, creating single page with all widgets',
      );
      pages.add(_buildContentPage(widgets));
    }

    debugPrint('CardModel: Created ${pages.length} pages');
    return pages;
  }

  double _calculateWidgetHeight(Widget widget) {
    if (widget is SizedBox) {
      return widget.height ?? 0;
    } else if (widget is Text) {
      // Calculate text height based on content
      final text = widget.data ?? '';
      final fontSize = Responsive.text(context, size: TextSize.medium);
      final maxWidth =
          Responsive.width(context) -
          (Responsive.space(context, size: Space.large) * 4);

      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: widget.style?.fontWeight ?? FontWeight.normal,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.rtl,
        maxLines: null,
      );

      textPainter.layout(maxWidth: maxWidth);
      return textPainter.height + Responsive.space(context, size: Space.small);
    } else if (widget is Container) {
      return Responsive.space(context, size: Space.large) * 1.2;
    } else if (widget is Column) {
      return Responsive.space(context, size: Space.large) * 1.5;
    } else if (widget is Row) {
      return Responsive.space(context, size: Space.large) * 0.8;
    } else if (widget is ListView) {
      return Responsive.space(context, size: Space.large) * 1.5;
    } else {
      return Responsive.space(context, size: Space.large) * 0.6;
    }
  }

  Widget _buildContentPage(List<Widget> widgets) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children:
            widgets.map((widget) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: Responsive.space(context, size: Space.small),
                ),
                child: widget,
              );
            }).toList(),
      ),
    );
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

        // Large calendar icon
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.description,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: Responsive.text(context, size: TextSize.medium),
      ),
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
        constraints: BoxConstraints(
          maxHeight: Responsive.height(context) * 0.8, // 80% of screen height
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available height as 80% of screen height
            final screenHeight = Responsive.height(context);
            final totalCardHeight = screenHeight * 0.8;

            // Calculate available height for content area
            final cardPadding =
                Responsive.space(context, size: Space.large) * 2;
            final headerHeight =
                Responsive.space(context, size: Space.large) * 2;
            final pageIndicatorHeight =
                _contentPages.length > 1
                    ? Responsive.space(context, size: Space.large)
                    : 0;
            final footerHeight =
                Responsive.space(context, size: Space.large) * 3;
            final safetyMargin = Responsive.space(context, size: Space.large);

            final availableHeight =
                totalCardHeight -
                cardPadding -
                headerHeight -
                pageIndicatorHeight -
                footerHeight -
                safetyMargin;

            debugPrint(
              'CardModel: Screen height: $screenHeight, Total card height: $totalCardHeight, Available height: $availableHeight',
            );

            // Generate content pages if not already generated or if height changed
            if (_contentPages.isEmpty || _availableHeight != availableHeight) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _generateContentPages(availableHeight);
                }
              });
            }

            return Padding(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.large),
              ),
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

                  // Title and Date (fixed elements)
                  _buildTitle(),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  // Date moved to end of content
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),

                  // Horizontal paging content area
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

                  // Static footer area
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
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
                            vertical: Responsive.space(
                              context,
                              size: Space.small,
                            ),
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
                                width: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
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
                                width: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
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

                                  // Try to access the provider safely
                                  Bookmarks? bookmarks;
                                  try {
                                    bookmarks = Provider.of<Bookmarks>(
                                      context,
                                      listen: false,
                                    );
                                  } catch (e) {
                                    debugPrint(
                                      'Bookmarks provider not available: $e',
                                    );
                                    return IconButton(
                                      onPressed: null,
                                      icon: const Icon(
                                        Icons.bookmark_border,
                                        color: Colors.grey,
                                      ),
                                      splashRadius: 24,
                                    );
                                  }

                                  // If provider is null or disposed, return fallback
                                  if (bookmarks == null) {
                                    return IconButton(
                                      onPressed: null,
                                      icon: const Icon(
                                        Icons.bookmark_border,
                                        color: Colors.grey,
                                      ),
                                      splashRadius: 24,
                                    );
                                  }

                                  // Use Consumer only if provider is available
                                  return Consumer<Bookmarks>(
                                    builder: (
                                      context,
                                      bookmarksConsumer,
                                      child,
                                    ) {
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

                                      try {
                                        final bool isBookmarked =
                                            bookmarksConsumer.isBookmarked(
                                              widget.id!,
                                            );

                                        return IconButton(
                                          onPressed: () {
                                            // Final mounted check before action
                                            if (!mounted) return;

                                            try {
                                              bookmarksConsumer.toggleBookmark(
                                                widget.id!,
                                              );
                                            } catch (e) {
                                              debugPrint(
                                                'Bookmarks toggle error: $e',
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            isBookmarked
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            color: Colors.black,
                                          ),
                                          splashRadius: 24,
                                        );
                                      } catch (e) {
                                        debugPrint(
                                          'Bookmarks consumer error: $e',
                                        );
                                        return IconButton(
                                          onPressed: null,
                                          icon: const Icon(
                                            Icons.bookmark_border,
                                            color: Colors.grey,
                                          ),
                                          splashRadius: 24,
                                        );
                                      }
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
            );
          },
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
