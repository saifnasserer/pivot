import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pivot/providers/bookmarks.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final PageController? pageController;

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
    this.pageController,
  });

  @override
  State<CardModel> createState() => _CardModelState();
}

class _CardModelState extends State<CardModel> {
  bool _isTitleExpanded = false;
  final ScrollController _scrollController = ScrollController();
  bool _isPageChanging = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      debugPrint(
        '[CardModel] ScrollController position: '
        'pixels: ${_scrollController.position.pixels}, '
        'min: ${_scrollController.position.minScrollExtent}, '
        'max: ${_scrollController.position.maxScrollExtent}',
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerPageChange(bool next) {
    if (_isPageChanging || widget.pageController == null) return;
    setState(() {
      _isPageChanging = true;
    });
    if (next) {
      widget.pageController!.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      widget.pageController!.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isPageChanging = false);
    });
  }

  // Builds the horizontally scrolling image gallery
  Widget _buildImageGallery(BuildContext context) {
    return Container(
      height: Responsive.space(context, size: Space.large) * 3,
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
                    width: Responsive.space(context, size: Space.large) * 3,
                    height: Responsive.space(context, size: Space.large) * 3,
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

                    //debugprint('Attempting to launch URL: $formattedUrl');
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
      child: Padding(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Visual indicator for scheduled/expired
            if (isScheduled)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.schedule, color: Colors.blue, size: 18),
                  SizedBox(width: Responsive.space(context, size: Space.small)),
                  Text(
                    'مجدول',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: Responsive.text(context, size: TextSize.small),
                    ),
                  ),
                ],
              ),
            if (isExpired)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.event_busy, color: Colors.grey, size: 18),
                  SizedBox(width: Responsive.space(context, size: Space.small)),
                  Text(
                    'منتهي',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: Responsive.text(context, size: TextSize.small),
                    ),
                  ),
                ],
              ),
            // Scrollable content area
            Expanded(
              child: NotificationListener<OverscrollNotification>(
                onNotification: (notification) {
                  // Let parent PageView handle the gesture at the edge
                  if ((notification.overscroll < 0 &&
                          notification.metrics.pixels <=
                              notification.metrics.minScrollExtent) ||
                      (notification.overscroll > 0 &&
                          notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent)) {
                    return false; // Let the notification bubble up
                  }
                  return true; // Consume other notifications
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  primary: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _isTitleExpanded
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.title,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize:
                                      Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ) *
                                      1.2,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              InkWell(
                                onTap:
                                    () => setState(
                                      () => _isTitleExpanded = false,
                                    ),
                                child: Text(
                                  'عرض أقل',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          )
                          : AutoSizeText(
                            widget.title,
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            minFontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.heading,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                            overflowReplacement: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                InkWell(
                                  onTap:
                                      () => setState(
                                        () => _isTitleExpanded = true,
                                      ),
                                  child: Text(
                                    '...عرض المزيد',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ),
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                          vertical: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Text(
                              widget.date,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ) *
                                    0.9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      Text(
                        widget.description,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                        ),
                      ),
                      // Image Gallery
                      if (widget.imageUrls.isNotEmpty)
                        _buildImageGallery(context),
                      // Links List
                      if (widget.links.isNotEmpty) _buildLinksList(context),
                    ],
                  ),
                ),
              ),
            ),
            // Static footer area
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
                      horizontal: Responsive.space(context, size: Space.medium),
                      vertical: Responsive.space(context, size: Space.small),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
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

                            Share.share(shareText);
                          },
                          icon: const Icon(Icons.share),
                          splashRadius: 24,
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.small),
                        ),
                        Consumer<Bookmarks>(
                          builder: (context, bookmarks, child) {
                            final bool isBookmarked = bookmarks.isBookmarked(
                              widget.id!,
                            );
                            return IconButton(
                              onPressed: () {
                                // Optimize bookmark toggle with immediate feedback
                                bookmarks.toggleBookmark(widget.id!);
                              },
                              icon: Icon(
                                isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.black,
                              ),
                              splashRadius: 24,
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
      if (_animation != null) {
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
    if (_transformationController.value.getMaxScaleOnAxis() <= 1.0) {
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
