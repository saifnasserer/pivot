import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarkCard extends StatelessWidget {
  final AnnouncementData bookmark;
  final VoidCallback? onRemove;

  const BookmarkCard({super.key, required this.bookmark, this.onRemove});

  void _showBookmarkBadge(BuildContext context) {
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
                        color: bookmark.color.withOpacity(0.13),
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
                          if (onRemove != null)
                            Material(
                              color: Colors.transparent,
                              child: IconButton(
                                icon: Icon(
                                  Icons.bookmark_remove,
                                  color: Colors.redAccent,
                                  size: 26,
                                ),
                                tooltip: 'إزالة من المحفظات',
                                onPressed: () {
                                  onRemove!();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Expanded(
                            child: Text(
                              bookmark.title,
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

                          // Remove button (future use)
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.large,
                        ),
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
                                bookmark.date,
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
                            height: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                          ),
                          Divider(thickness: 1, color: Colors.grey[200]),
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                          ),
                          Text(
                            bookmark.description,
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                              color: Colors.black.withOpacity(0.85),
                            ),
                            textAlign: TextAlign.right,
                          ),
                          if (bookmark.imageUrls.isNotEmpty) ...[
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            _buildImageGallery(context),
                          ],
                          if (bookmark.links.isNotEmpty) ...[
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            _buildLinksList(context),
                          ],
                          if (bookmark.tags.isNotEmpty) ...[
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
                                  bookmark.tags.map((tag) {
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
                                        color: bookmark.color.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: bookmark.color.withOpacity(
                                            0.3,
                                          ),
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
                        ],
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLinksList(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            bookmark.links.map((link) {
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
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

                    debugPrint('Attempting to launch URL: $formattedUrl');
                    final url = Uri.parse(formattedUrl);

                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تعذر فتح الرابط: $urlString')),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bookmark.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
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

  Widget _buildImageGallery(BuildContext context) {
    if (bookmark.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: Responsive.space(context, size: Space.large) * 3,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: bookmark.imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = bookmark.imageUrls[index];
          return Container(
            margin: const EdgeInsets.only(left: 8.0),
            width: Responsive.space(context, size: Space.large) * 3,
            height: Responsive.space(context, size: Space.large) * 3,
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
                borderRadius: BorderRadius.circular(12.0),
                child: Hero(
                  tag: imageUrl,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: Responsive.space(context, size: Space.large) * 3,
                    height: Responsive.space(context, size: Space.large) * 3,
                    placeholder:
                        (context, url) => Container(
                          width:
                              Responsive.space(context, size: Space.large) * 3,
                          height:
                              Responsive.space(context, size: Space.large) * 3,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          width:
                              Responsive.space(context, size: Space.large) * 3,
                          height:
                              Responsive.space(context, size: Space.large) * 3,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBookmarkBadge(context),
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: Responsive.space(context, size: Space.small),
          horizontal: Responsive.space(context, size: Space.medium),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bookmark.color.withOpacity(0.4),
              bookmark.color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          boxShadow: [
            BoxShadow(
              color: bookmark.color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(
            Responsive.space(context, size: Space.medium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bookmark.title,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.small),
                      vertical:
                          Responsive.space(context, size: Space.small) * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bookmark.date,
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
                  Icon(
                    Icons.bookmark,
                    color: bookmark.color.withValues(alpha: 0.6),
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
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
