import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pivot/services/permission_service.dart';
import 'package:pivot/features/profile/providers/edit_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class ProfileImageSection extends StatefulWidget {
  final EditProfileState state;
  final WidgetRef widgetRef;

  const ProfileImageSection({
    super.key,
    required this.state,
    required this.widgetRef,
  });

  @override
  State<ProfileImageSection> createState() => _ProfileImageSectionState();
}

class _ProfileImageSectionState extends State<ProfileImageSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });
    _animationController.forward();

    try {
      // Request permission first
      final granted =
          await PermissionService.requestPhotosPermissionWithRationale(context);
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يجب منح صلاحية الوصول للصور لاختيار صورة الملف الشخصي',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      // Pick image from gallery only with highly optimized settings
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600, // Further reduced for faster processing
        maxHeight: 600, // Further reduced for faster processing
        imageQuality: 70, // Reduced for smaller initial file size
        requestFullMetadata: false, // Skip metadata for faster processing
      );

      if (pickedFile == null) return;

      // Show loading indicator with better messaging
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'جاري معالجة وتحسين الصورة...',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Update loading message for compression
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'جاري ضغط الصورة للرفع السريع...',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 10), // Longer duration for compression
          ),
        );
      }

      // Compress image directly (no compute function)
      final compressedFile = await _compressImage(pickedFile.path);
      if (compressedFile != null) {
        // Update the provider with the compressed image
        widget.widgetRef
            .read(editProfileProvider.notifier)
            .updateProfileImage(File(compressedFile.path));

        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم اختيار الصورة بنجاح. احفظ التغييرات لتحديث الصورة',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('فشل في معالجة الصورة'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        String errorMessage = 'حدث خطأ أثناء اختيار الصورة';

        // Check for specific Firebase Storage authorization errors
        if (e.toString().contains('unauthorized') ||
            e.toString().contains('permission')) {
          errorMessage =
              'فشل في رفع الصورة. يرجى التحقق من إعدادات Firebase Storage أو المحاولة لاحقاً';
        } else if (e.toString().contains('network') ||
            e.toString().contains('timeout')) {
          errorMessage =
              'فشل في الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى';
        } else if (e.toString().contains('size') ||
            e.toString().contains('large')) {
          errorMessage = 'حجم الصورة كبير جداً. يرجى اختيار صورة أصغر';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _animationController.reverse();
    }
  }

  Future<XFile?> _compressImage(String imagePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // More aggressive compression for faster uploads
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: 50, // Further reduced for faster uploads
        minWidth: 256, // Optimized size for profile images
        minHeight: 256, // Optimized size for profile images
        format: CompressFormat.jpeg,
        keepExif: false, // Remove EXIF data to reduce file size
        autoCorrectionAngle:
            false, // Skip auto-correction for faster processing
        rotate: 0, // No rotation for faster processing
        inSampleSize: 2, // Downsample by 2 for faster processing
      );

      if (result != null) {
        // Verify the compressed file size
        final file = File(result.path);
        final fileSize = await file.length();

        // If file is still too large (> 500KB), compress again with lower quality
        if (fileSize > 500 * 1024) {
          final result2 = await FlutterImageCompress.compressAndGetFile(
            result.path,
            targetPath.replaceAll('.jpg', '_2.jpg'),
            quality: 35, // Very aggressive compression
            minWidth: 200,
            minHeight: 200,
            format: CompressFormat.jpeg,
            keepExif: false,
          );

          if (result2 != null) {
            // Delete the first compressed file
            await file.delete();
            return result2;
          }
        }

        return result;
      } else {
        return null;
      }
    } catch (e) {
      print('Image compression error: $e');
      return null;
    }
  }

  Widget _getProfileImageChild() {
    // Show picked image if available
    if (widget.state.profileImage != null) {
      return Image.file(
        widget.state.profileImage!,
        width: 132,
        height: 132,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultIcon();
        },
      );
    }

    // Show network image if available with optimized caching
    if (widget.state.userProfile?.profileImageUrl != null &&
        widget.state.userProfile!.profileImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.state.userProfile!.profileImageUrl!,
        width: 132,
        height: 132,
        fit: BoxFit.cover,
        // Optimized caching settings
        memCacheWidth: 132, // Cache at display size
        memCacheHeight: 132, // Cache at display size
        fadeInDuration: Duration(milliseconds: 200), // Smooth fade-in
        placeholder:
            (context, url) => Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green[600]!,
                    ),
                  ),
                ),
              ),
            ),
        errorWidget: (context, url, error) => _buildDefaultIcon(),
        // Use placeholder while loading
        imageBuilder:
            (context, imageProvider) => Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
      );
    }

    // Default icon
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 132,
      height: 132,
      color: Colors.grey[100],
      child: Icon(Icons.person_rounded, color: Colors.grey[400], size: 64),
    );
  }

  bool _hasImage() {
    return widget.state.profileImage != null ||
        (widget.state.userProfile?.profileImageUrl != null &&
            widget.state.userProfile!.profileImageUrl!.isNotEmpty);
  }

  Future<void> _removeImage() async {
    // Show confirmation dialog using UnifiedDialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return UnifiedDialog(
          title: 'حذف صورة الملف الشخصي',
          subtitle: 'هل أنت متأكد من حذف الصورة؟',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.medium),
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Expanded(
                      child: Text(
                        'سيتم تطبيق الحذف عند حفظ التغييرات',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.orange[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.medium),
                      vertical: Responsive.space(context, size: Space.small),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                    ),
                  ),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Delete button with red gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[400]!, Colors.red[600]!],
                    ),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.delete_outline,
                      size: Responsive.space(context, size: Space.medium),
                    ),
                    label: Text(
                      'حذف',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.large,
                        ),
                        vertical: Responsive.space(context, size: Space.small),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    // If user confirmed, remove the image
    if (confirmed == true && mounted) {
      widget.widgetRef.read(editProfileProvider.notifier).removeProfileImage();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تم إزالة الصورة. احفظ التغييرات لتأكيد الحذف النهائي',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // Profile image container
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green[100]!, Colors.green[50]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(child: _getProfileImageChild()),
                    ),
                  ),
                ),
              );
            },
          ),

          // Action buttons below the image
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Change photo button
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.medium),
                    vertical: Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          _isLoading
                              ? [Colors.grey[300]!, Colors.grey[400]!]
                              : [Colors.green[400]!, Colors.green[600]!],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_isLoading ? Colors.grey : Colors.green)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isLoading
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Icon(
                            Icons.photo_library_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                      SizedBox(width: 6),
                      Text(
                        _isLoading ? 'جاري التحميل...' : 'تغيير الصورة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Remove button (only show if there's an image)
              if (_hasImage()) ...[
                SizedBox(width: Responsive.space(context, size: Space.small)),
                GestureDetector(
                  onTap: _isLoading ? null : _removeImage,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red[300]!, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red[600],
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
