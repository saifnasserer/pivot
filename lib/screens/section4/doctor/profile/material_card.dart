import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter/services.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/screens/section4/doctor/profile/pdf_viewer_screen.dart';
import 'package:pivot/screens/section4/doctor/profile/video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/material_link.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MaterialCard extends StatefulWidget {
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
  State<MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<MaterialCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Debug logging for user data
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Card(
                margin: EdgeInsets.only(
                  bottom: Responsive.space(context, size: Space.small),
                ),
                elevation: _isHovered ? 8 : 2,
                shadowColor: Colors.black.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
                child: InkWell(
                  onTap: () => _handleTap(context),
                  onHover: _onHover,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Enhanced Thumbnail with overlay
                      _buildEnhancedThumbnail(context),
                      // Content with better spacing
                      _buildEnhancedContent(context),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedThumbnail(BuildContext context) {
    final thumbnailUrl = _getThumbnailUrl();

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: Responsive.height(context) * 0.25,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                Responsive.space(context, size: Space.large),
              ),
              topRight: Radius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
            color: Colors.grey.shade100,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                Responsive.space(context, size: Space.large),
              ),
              topRight: Radius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
            child:
                thumbnailUrl != null
                    ? CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => _buildEnhancedPlaceholder(context),
                      errorWidget:
                          (context, url, error) =>
                              _buildEnhancedPlaceholder(context),
                    )
                    : _buildEnhancedPlaceholder(context),
          ),
        ),
        // Play overlay for videos
        if (widget.materialLink.type == MaterialType.video)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  topRight: Radius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    size: Responsive.text(context, size: TextSize.heading),
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMaterialTypeBadge(BuildContext context) {
    final typeColors = {
      MaterialType.video: Colors.red,
      MaterialType.pdf: Colors.orange,
      MaterialType.document: Colors.blue,
      MaterialType.image: Colors.green,
      MaterialType.link: Colors.purple,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
        vertical: Responsive.space(context, size: Space.tiny),
      ),
      decoration: BoxDecoration(
        color: typeColors[widget.materialLink.type]?.withOpacity(0.9),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.materialLink.typeIcon, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text(
            widget.materialLink.typeDisplayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: Responsive.height(context) * 0.25,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade200, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            Responsive.space(context, size: Space.large),
          ),
          topRight: Radius.circular(
            Responsive.space(context, size: Space.large),
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.materialLink.typeIcon,
                size: Responsive.text(context, size: TextSize.heading),
                color: _getTypeColor(widget.materialLink.type),
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              widget.materialLink.typeDisplayName,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(MaterialType type) {
    switch (type) {
      case MaterialType.video:
        return Colors.red.shade600;
      case MaterialType.pdf:
        return Colors.orange.shade600;
      case MaterialType.document:
        return Colors.blue.shade600;
      case MaterialType.image:
        return Colors.green.shade600;
      case MaterialType.link:
        return Colors.purple.shade600;
    }
  }

  Widget _buildEnhancedContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced title with better typography
          _buildEnhancedTitle(context),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          // Description if available
          if (widget.materialLink.description?.isNotEmpty == true)
            _buildDescription(context),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          // Enhanced bottom row with date, rating, and actions
          _buildEnhancedBottomRow(context),
        ],
      ),
    );
  }

  Widget _buildEnhancedTitle(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.tiny)),
          decoration: BoxDecoration(
            color: _getTypeColor(widget.materialLink.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.small),
            ),
          ),
          child: Icon(
            widget.materialLink.typeIcon,
            size: Responsive.text(context, size: TextSize.small),
            color: _getTypeColor(widget.materialLink.type),
          ),
        ),
        SizedBox(width: Responsive.space(context, size: Space.small)),
        Expanded(
          child: Text(
            widget.materialLink.displayTitle,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      widget.materialLink.description!,
      style: TextStyle(
        fontSize: Responsive.text(context, size: TextSize.small),
        color: Colors.grey.shade600,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEnhancedBottomRow(BuildContext context) {
    final userRating =
        widget.loggedInUser != null
            ? widget.materialLink.getUserRating(widget.loggedInUser!.id)
            : null;

    return Row(
      children: [
        // Date and Rating in one row
        Expanded(
          child: Row(
            children: [
              // Date display
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.small),
                  vertical: Responsive.space(context, size: Space.tiny),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.medium),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(widget.materialLink.createdAt),
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              // Clickable rating
              _buildClickableRating(context, userRating),
            ],
          ),
        ),
        // Action buttons
        _buildEnhancedActionButtons(context),
      ],
    );
  }

  Widget _buildClickableRating(BuildContext context, double? userRating) {
    return GestureDetector(
      onTap: () {
        if (widget.loggedInUser != null && widget.onRate != null) {
          _showRatingDialog(context, userRating);
        } else {}
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.small),
          vertical: Responsive.space(context, size: Space.tiny),
        ),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          border: Border.all(color: Colors.amber.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.shade200.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              userRating != null ? Icons.star : Icons.star_border,
              size: 14,
              color:
                  userRating != null
                      ? Colors.amber.shade600
                      : Colors.amber.shade400,
            ),
            SizedBox(width: 4),
            Text(
              userRating != null
                  ? '${userRating.toInt()}'
                  : widget.materialLink.averageRatingCalculated.toStringAsFixed(
                    1,
                  ),
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                fontWeight: FontWeight.bold,
                color:
                    userRating != null
                        ? Colors.amber.shade700
                        : Colors.amber.shade600,
              ),
            ),
            if (widget.materialLink.totalRatingsCalculated > 0 &&
                userRating == null) ...[
              SizedBox(width: 2),
              Text(
                '(${widget.materialLink.totalRatingsCalculated})',
                style: TextStyle(fontSize: 10, color: Colors.amber.shade600),
              ),
            ],
            if (widget.loggedInUser != null &&
                widget.onRate != null &&
                userRating == null) ...[
              SizedBox(width: 4),
              Icon(Icons.touch_app, size: 10, color: Colors.amber.shade400),
            ],
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, double? currentRating) {
    double selectedRating = currentRating ?? 0.0;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return UnifiedDialog(
                title: 'تقييم المحتوى',
                subtitle: widget.materialLink.title,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    // Interactive stars with live movement
                    _buildInteractiveStars(context, selectedRating, (rating) {
                      setState(() {
                        selectedRating = rating;
                      });
                      HapticFeedback.lightImpact();
                    }),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    // Rating text
                    Text(
                      selectedRating > 0
                          ? '${selectedRating.toInt()} نجوم'
                          : 'اختر التقييم',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.bold,
                        color:
                            selectedRating > 0
                                ? Colors.amber.shade700
                                : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                onCancel: () => Navigator.of(context).pop(),
                onConfirm:
                    selectedRating > 0
                        ? () {
                          Navigator.of(context).pop();
                          if (widget.onRate != null) {
                            widget.onRate!(selectedRating);
                          } else {}
                        }
                        : null,
                confirmText: 'تقييم',
                confirmIcon: Icons.star,
              );
            },
          ),
    );
  }

  Widget _buildInteractiveStars(
    BuildContext context,
    double selectedRating,
    Function(double) onRatingChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final starValue = index + 1.0;
          final isFilled = selectedRating >= starValue;

          return Expanded(
            child: GestureDetector(
              onTap: () => onRatingChanged(starValue),
              onPanUpdate: (details) {
                // Calculate which star the user is hovering over
                final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(
                  details.globalPosition,
                );
                final starWidth = renderBox.size.width / 5;
                final starIndex = (localPosition.dx / starWidth).floor();
                final newRating = (starIndex + 1).clamp(1, 5).toDouble();

                if (newRating != selectedRating) {
                  onRatingChanged(newRating);
                }
              },
              onPanEnd: (details) {
                // Keep the rating when user stops dragging
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.small),
                ),
                child: Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  size: Responsive.text(context, size: TextSize.heading),
                  color:
                      isFilled ? Colors.amber.shade600 : Colors.grey.shade400,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEnhancedActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context,
          icon: _getActionIcon(),
          tooltip: _getActionTooltip(),
          color: _getTypeColor(widget.materialLink.type),
          onPressed: () => _handleTap(context),
        ),
        SizedBox(width: Responsive.space(context, size: Space.small)),
        _buildActionButton(
          context,
          icon: Icons.copy,
          tooltip: 'نسخ الرابط',
          color: Colors.grey.shade600,
          onPressed: () => _copyToClipboard(context),
        ),
        if (widget.canEdit) ...[
          SizedBox(width: Responsive.space(context, size: Space.small)),
          _buildActionButton(
            context,
            icon: Icons.delete_outline,
            tooltip: 'حذف المادة',
            color: Colors.red.shade400,
            onPressed: widget.onDelete,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color),
        tooltip: tooltip,
        padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
        constraints: BoxConstraints(
          minWidth: Responsive.space(context, size: Space.large),
          minHeight: Responsive.space(context, size: Space.large),
        ),
      ),
    );
  }

  IconData _getActionIcon() {
    switch (widget.materialLink.type) {
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
    switch (widget.materialLink.type) {
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
    return widget.materialLink.bestThumbnail;
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
    Clipboard.setData(ClipboardData(text: widget.materialLink.url))
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
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    // Enhanced content handling based on type
    switch (widget.materialLink.type) {
      case MaterialType.pdf:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => PdfViewerScreen(materialLink: widget.materialLink),
          ),
        );
        break;
      case MaterialType.video:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) =>
                    VideoPlayerScreen(materialLink: widget.materialLink),
          ),
        );
        break;
      case MaterialType.image:
        _showImageFullScreen(context);
        break;
      default:
        _launchURL(context, widget.materialLink.url);
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
                  widget.materialLink.displayTitle,
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    onPressed:
                        () => _launchURL(context, widget.materialLink.url),
                  ),
                ],
              ),
              body: Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: widget.materialLink.url,
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
