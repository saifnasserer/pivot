import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enhanced BookmarkCard with animations and improved design
class BookmarkCard extends StatefulWidget {
  final AnnouncementData bookmark;
  final VoidCallback? onRemove;
  final VoidCallback? onShare;
  final VoidCallback? onCardTap; // Add callback for card tap
  final bool showRemoveButton;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    this.onRemove,
    this.onShare,
    this.onCardTap, // Add the new parameter
    this.showRemoveButton = true,
  });

  @override
  State<BookmarkCard> createState() => _BookmarkCardState();
}

class _BookmarkCardState extends State<BookmarkCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start entrance animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Safe getter for bookmark color with fallback
  Color get _safeBookmarkColor {
    try {
      return widget.bookmark.color;
    } catch (e) {
      print('Error accessing bookmark color: $e');
      return Colors.blue; // Fallback color
    }
  }

  void _showBookmarkBadge(BuildContext context) {
    // Call the onCardTap callback if provided
    widget.onCardTap?.call();

    // Add null safety checks before showing dialog
    try {
      // Validate bookmark data before showing dialog
      if (widget.bookmark.title.isEmpty ||
          widget.bookmark.description.isEmpty ||
          widget.bookmark.id == null) {
        print('Invalid bookmark data, cannot show dialog');
        return;
      }
    } catch (e) {
      print('Error validating bookmark data: $e');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.medium),
            vertical: Responsive.space(context, size: Space.large),
          ),
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Enhanced header with gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _safeBookmarkColor.withOpacity(0.2),
                            _safeBookmarkColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.large,
                        ),
                        vertical: Responsive.space(context, size: Space.medium),
                      ),
                      child: Row(
                        children: [
                          // Action buttons
                          if (widget.showRemoveButton &&
                              widget.onRemove != null)
                            _buildActionButton(
                              icon: Icons.bookmark_remove,
                              color: Colors.red.shade400,
                              tooltip: 'إزالة من المحفظات',
                              onPressed: () {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  widget.onRemove?.call();
                                }
                              },
                            ),

                          if (widget.onShare != null) ...[
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            _buildActionButton(
                              icon: Icons.share,
                              color: Colors.blue.shade400,
                              tooltip: 'مشاركة',
                              onPressed: widget.onShare!,
                            ),
                          ],

                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),

                          // Title
                          Expanded(
                            child: Text(
                              widget.bookmark.title,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize:
                                    Responsive.text(
                                      context,
                                      size: TextSize.heading,
                                    ) *
                                    1.1,
                                fontWeight: FontWeight.bold,
                                color: Colors.black.withOpacity(0.9),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content area
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(
                            context,
                            size: Space.large,
                          ),
                          vertical: Responsive.space(
                            context,
                            size: Space.medium,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Date with enhanced styling
                            _buildDateSection(),

                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Divider(thickness: 1, color: Colors.grey.shade200),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),

                            // Description
                            Text(
                              widget.bookmark.description,
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                color: Colors.black.withOpacity(0.85),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.right,
                            ),

                            // Images
                            if (widget.bookmark.imageUrls.isNotEmpty) ...[
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              _buildImageGallery(context),
                            ],

                            // Links
                            if (widget.bookmark.links.isNotEmpty) ...[
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              _buildLinksList(context),
                            ],

                            // Tags
                            if (widget.bookmark.tags.isNotEmpty) ...[
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              _buildTagsSection(),
                            ],

                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Enhanced close button
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    tooltip: 'إغلاق',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.small),
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      decoration: BoxDecoration(
        color: widget.bookmark.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: widget.bookmark.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.calendar_today, size: 16, color: widget.bookmark.color),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Text(
            widget.bookmark.date,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: widget.bookmark.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'العلامات:',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        Wrap(
          spacing: Responsive.space(context, size: Space.small),
          runSpacing: Responsive.space(context, size: Space.small),
          alignment: WrapAlignment.end,
          children:
              widget.bookmark.tags.map((tag) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        Responsive.space(context, size: Space.small) * 1.5,
                    vertical:
                        Responsive.space(context, size: Space.small) * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: widget.bookmark.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.bookmark.color.withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.bookmark.color.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize:
                          Responsive.text(context, size: TextSize.small) * 0.95,
                      fontWeight: FontWeight.w500,
                      color: widget.bookmark.color,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildLinksList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'الروابط:',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        ...widget.bookmark.links.map((link) {
          return Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: InkWell(
              onTap: () async {
                final urlString = link['url'];
                if (urlString == null || urlString.isEmpty) return;

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
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تعذر فتح الرابط: $urlString')),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.bookmark.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.bookmark.color.withOpacity(0.3),
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
                        color: widget.bookmark.color,
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Icon(Icons.link, color: widget.bookmark.color, size: 18),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    if (widget.bookmark.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'الصور:',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        SizedBox(
          height: Responsive.space(context, size: Space.large) * 3,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: widget.bookmark.imageUrls.length,
            itemBuilder: (context, index) {
              final imageUrl = widget.bookmark.imageUrls[index];
              return Container(
                margin: const EdgeInsets.only(left: 8.0),
                width: Responsive.space(context, size: Space.large) * 3,
                height: Responsive.space(context, size: Space.large) * 3,
                child: GestureDetector(
                  onTap: () {
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  FullScreenImageViewer(imageUrl: imageUrl),
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Hero(
                      tag: imageUrl,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: Responsive.space(context, size: Space.large) * 3,
                        height:
                            Responsive.space(context, size: Space.large) * 3,
                        placeholder:
                            (context, url) => Container(
                              width:
                                  Responsive.space(context, size: Space.large) *
                                  3,
                              height:
                                  Responsive.space(context, size: Space.large) *
                                  3,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              width:
                                  Responsive.space(context, size: Space.large) *
                                  3,
                              height:
                                  Responsive.space(context, size: Space.large) *
                                  3,
                              color: Colors.grey.shade200,
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTap: () => _showBookmarkBadge(context),
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              child: MouseRegion(
                onEnter: (_) {
                  setState(() => _isHovered = true);
                  _animationController.forward();
                },
                onExit: (_) {
                  setState(() => _isHovered = false);
                  _animationController.reverse();
                },
                child: Container(
                  margin: EdgeInsets.symmetric(
                    vertical: Responsive.space(context, size: Space.small),
                    horizontal: Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.bookmark.color.withOpacity(
                          _isHovered ? 0.5 : 0.4,
                        ),
                        widget.bookmark.color.withOpacity(
                          _isHovered ? 0.2 : 0.1,
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.medium),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.bookmark.color.withOpacity(
                          _isHovered ? 0.3 : 0.2,
                        ),
                        blurRadius: _isHovered ? 12 : 8,
                        offset: Offset(0, _isHovered ? 6 : 4),
                      ),
                    ],
                    border: Border.all(
                      color: widget.bookmark.color.withOpacity(
                        _isHovered ? 0.4 : 0.2,
                      ),
                      width: _isHovered ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      Responsive.space(context, size: Space.medium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.bookmark.title,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.heading,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                                vertical:
                                    Responsive.space(
                                      context,
                                      size: Space.small,
                                    ) *
                                    0.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                widget.bookmark.date,
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Icon(
                              Icons.bookmark,
                              color: widget.bookmark.color.withValues(
                                alpha: 0.8,
                              ),
                              size: _isHovered ? 24 : 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Extracted dialog for details view
class BookmarkDetailsDialog extends StatelessWidget {
  final dynamic model; // Can be a bookmark or announcement
  final Color color;
  final VoidCallback? onRemove;
  final String title;
  final String date;
  final String description;
  final List<String> imageUrls;
  final List<Map<String, String>> links;
  final List<String> tags;

  const BookmarkDetailsDialog({
    super.key,
    required this.model,
    required this.color,
    required this.title,
    required this.date,
    required this.description,
    required this.imageUrls,
    required this.links,
    required this.tags,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.large),
      ),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with color and icon
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.13),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.large),
                    vertical: Responsive.space(context, size: Space.medium),
                  ),
                  child: Row(
                    children: [
                      if (onRemove != null)
                        Material(
                          color: Colors.transparent,
                          child: IconButton(
                            icon: Icon(
                              Icons.bookmark_remove,
                              color: Colors.redAccent,
                              size: 26,
                            ),
                            tooltip: 'إزالة',
                            onPressed: onRemove,
                          ),
                        ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize:
                                Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ) *
                                1.1,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable content area
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.large),
                      vertical: Responsive.space(context, size: Space.medium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.tiny,
                              ),
                            ),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        Divider(thickness: 1, color: Colors.grey[200]),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            color: Colors.black.withOpacity(0.85),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        if (imageUrls.isNotEmpty) ...[
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          // You can reuse _buildImageGallery logic here if needed
                        ],
                        if (links.isNotEmpty) ...[
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          // You can reuse _buildLinksList logic here if needed
                        ],
                        if (tags.isNotEmpty) ...[
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          Wrap(
                            spacing: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                            runSpacing: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                            alignment: WrapAlignment.end,
                            children:
                                tags.map((tag) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          Responsive.space(
                                            context,
                                            size: Space.small,
                                          ) *
                                          1.5,
                                      vertical:
                                          Responsive.space(
                                            context,
                                            size: Space.small,
                                          ) *
                                          0.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: color.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize:
                                            Responsive.text(
                                              context,
                                              size: TextSize.small,
                                            ) *
                                            0.95,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black.withOpacity(0.8),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating close button
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
