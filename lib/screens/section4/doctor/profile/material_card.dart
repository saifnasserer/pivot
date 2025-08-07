import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter/services.dart';
import 'package:pivot/models/material_link.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivot/screens/section4/doctor/profile/pdf_viewer_screen.dart';
import 'package:pivot/screens/section4/doctor/profile/video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MaterialCard extends StatelessWidget {
  final MaterialLink materialLink;
  final bool canEdit;
  final UserProfile? loggedInUser;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Function(double)? onRate;

  const MaterialCard({
    super.key,
    required this.materialLink,
    this.canEdit = false,
    this.loggedInUser,
    this.onTap,
    this.onDelete,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail - Full width
            _buildThumbnail(context),
            // Content - Compact
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, size: Space.small),
                vertical: Responsive.space(context, size: Space.tiny),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + Title
                  _buildTitleRow(context),
                  SizedBox(height: Responsive.space(context, size: Space.tiny)),
                  // Rating
                  _buildRatingRow(context),
                  SizedBox(height: Responsive.space(context, size: Space.tiny)),
                  // Date + Actions
                  _buildBottomRow(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final thumbnailUrl = _getThumbnailUrl();

    return Container(
      width: double.infinity,
      height: Responsive.height(context) * 0.25, // Use responsive height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          topRight: Radius.circular(
            Responsive.space(context, size: Space.medium),
          ),
        ),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          topRight: Radius.circular(
            Responsive.space(context, size: Space.medium),
          ),
        ),
        child:
            thumbnailUrl != null
                ? CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => _buildPlaceholderThumbnail(context),
                  errorWidget:
                      (context, url, error) =>
                          _buildPlaceholderThumbnail(context),
                )
                : _buildPlaceholderThumbnail(context),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail(BuildContext context) {
    return Container(
      width: double.infinity,
      height: Responsive.height(context) * 0.25, // Use responsive height
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Special styling for PDFs
            if (materialLink.type == MaterialType.pdf) ...[
              Container(
                width: Responsive.width(context) * 0.15, // Responsive width
                height: Responsive.height(context) * 0.12, // Responsive height
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.small),
                  ),
                  border: Border.all(color: Colors.red.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: Responsive.space(context, size: Space.small),
                      offset: const Offset(0, 3),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Document lines to simulate text
                    Positioned(
                      top: Responsive.space(context, size: Space.small),
                      left: Responsive.space(context, size: Space.small),
                      right: Responsive.space(context, size: Space.small),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          3,
                          (index) => Container(
                            height: 2,
                            width: (index + 1) * 0.3, // Different line lengths
                            margin: EdgeInsets.only(
                              bottom: Responsive.space(
                                context,
                                size: Space.tiny,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // PDF icon and label
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(
                              Responsive.space(context, size: Space.tiny),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.tiny),
                              ),
                            ),
                            child: Icon(
                              Icons.picture_as_pdf,
                              size: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                              color: Colors.red.shade600,
                            ),
                          ),
                          SizedBox(
                            height: Responsive.space(context, size: Space.tiny),
                          ),
                          Text(
                            'PDF',
                            style: TextStyle(
                              fontSize:
                                  Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ) *
                                  0.8,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Icon(
                materialLink.typeIcon,
                size: Responsive.text(
                  context,
                  size: TextSize.heading,
                ), // Responsive icon size
                color: Colors.grey.shade400,
              ),
            ],
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              materialLink.typeDisplayName,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      children: [
        Icon(
          materialLink.typeIcon,
          size: Responsive.text(
            context,
            size: TextSize.small,
          ), // Responsive icon size
          color: Colors.grey.shade600,
        ),
        SizedBox(width: Responsive.space(context, size: Space.small)),
        Expanded(
          child: Text(
            materialLink.displayTitle,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow(BuildContext context) {
    final userRating =
        loggedInUser != null
            ? materialLink.getUserRating(loggedInUser!.id)
            : null;
    final hasRated =
        loggedInUser != null
            ? materialLink.hasUserRated(loggedInUser!.id)
            : false;

    return Row(
      children: [
        // Average rating display
        Row(
          children: [
            Icon(
              Icons.star,
              size: Responsive.text(context, size: TextSize.small),
              color: Colors.yellow.shade700,
            ),
            SizedBox(width: Responsive.space(context, size: Space.tiny)),
            Text(
              '${materialLink.averageRatingCalculated.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            if (materialLink.totalRatingsCalculated > 0) ...[
              SizedBox(width: Responsive.space(context, size: Space.tiny)),
              Text(
                '(${materialLink.totalRatingsCalculated})',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        const Spacer(),
        // Interactive rating stars (only for logged in users)
        if (loggedInUser != null && onRate != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              final isFilled = userRating != null && userRating >= starValue;

              return GestureDetector(
                onTap: () => onRate!(starValue),
                child: Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  size: Responsive.text(context, size: TextSize.small),
                  color:
                      isFilled ? Colors.yellow.shade700 : Colors.grey.shade400,
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      children: [
        // Date
        Expanded(
          child: Text(
            _formatDate(materialLink.createdAt),
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.grey.shade500,
            ),
          ),
        ),
        // Action Icons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _handleTap(context),
              icon: Icon(
                _getActionIcon(),
                size: Responsive.text(
                  context,
                  size: TextSize.small,
                ), // Responsive icon size
                color: Colors.grey.shade600,
              ),
              tooltip: _getActionTooltip(),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: Responsive.space(
                  context,
                  size: Space.large,
                ), // Responsive touch target
                minHeight: Responsive.space(context, size: Space.large),
              ),
            ),
            IconButton(
              onPressed: () => _copyToClipboard(context),
              icon: Icon(
                Icons.copy,
                size: Responsive.text(
                  context,
                  size: TextSize.small,
                ), // Responsive icon size
                color: Colors.grey.shade600,
              ),
              tooltip: 'نسخ الرابط',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: Responsive.space(
                  context,
                  size: Space.large,
                ), // Responsive touch target
                minHeight: Responsive.space(context, size: Space.large),
              ),
            ),
            if (canEdit)
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  size: Responsive.text(
                    context,
                    size: TextSize.small,
                  ), // Responsive icon size
                  color: Colors.red.shade400,
                ),
                tooltip: 'حذف المادة',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: Responsive.space(
                    context,
                    size: Space.large,
                  ), // Responsive touch target
                  minHeight: Responsive.space(context, size: Space.large),
                ),
              ),
          ],
        ),
      ],
    );
  }

  IconData _getActionIcon() {
    switch (materialLink.type) {
      case MaterialType.video:
        return Icons.play_circle_outline;
      case MaterialType.pdf:
        return Icons.picture_as_pdf;
      case MaterialType.image:
        return Icons.image;
      default:
        return Icons.open_in_new;
    }
  }

  String _getActionTooltip() {
    switch (materialLink.type) {
      case MaterialType.video:
        return 'تشغيل الفيديو';
      case MaterialType.pdf:
        return 'عرض PDF';
      case MaterialType.image:
        return 'عرض الصورة';
      default:
        return 'فتح الرابط';
    }
  }

  String? _getThumbnailUrl() {
    return materialLink.bestThumbnail;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'منذ $weeks أسابيع';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: materialLink.url))
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم نسخ الرابط إلى الحافظة'),
              duration: Duration(seconds: 2),
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في نسخ الرابط: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }

    // Enhanced content handling based on type
    switch (materialLink.type) {
      case MaterialType.pdf:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(materialLink: materialLink),
          ),
        );
        break;
      case MaterialType.video:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(materialLink: materialLink),
          ),
        );
        break;
      case MaterialType.image:
        _showImageFullScreen(context);
        break;
      default:
        _launchURL(context, materialLink.url);
        break;
    }
  }

  void _showImageFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  materialLink.displayTitle,
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    onPressed: () => _launchURL(context, materialLink.url),
                  ),
                ],
              ),
              body: Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: materialLink.url,
                    fit: BoxFit.contain,
                    placeholder:
                        (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                    errorWidget:
                        (context, url, error) => const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri? url = Uri.tryParse(urlString);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر فتح الرابط: $urlString')));
      }
    }
  }
}
