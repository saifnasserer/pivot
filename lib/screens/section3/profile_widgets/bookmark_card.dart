import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarkCard extends StatelessWidget {
  final AnnouncementData bookmark;

  const BookmarkCard({super.key, required this.bookmark});

  void _showBookmarkBadge(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
          ),
          title: Text(
            bookmark.title,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.black.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.right,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  bookmark.date,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                Text(
                  bookmark.description,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                _buildImageGallery(context),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                _buildLinksList(context),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Wrap(
                  spacing: Responsive.space(context, size: Space.small),
                  runSpacing: Responsive.space(context, size: Space.small),
                  alignment: WrapAlignment.end,
                  children:
                      bookmark.tags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                Responsive.space(context, size: Space.small) *
                                1.5,
                            vertical:
                                Responsive.space(context, size: Space.small) *
                                0.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xffe1e0da,
                            ).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: bookmark.color.withValues(alpha: 0.5),
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
                                  0.9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', textAlign: TextAlign.center),
            ),
          ],
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

                    // Ensure the URL has a scheme (http or https)
                    String formattedUrl = urlString;
                    if (!formattedUrl.startsWith('http://') &&
                        !formattedUrl.startsWith('https://')) {
                      formattedUrl = 'https://$formattedUrl';
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
                        const SizedBox(width: 8),
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
