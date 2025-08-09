import 'dart:io';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pivot/responsive.dart';
import 'package:pivot/services/permission_service.dart';
import 'edit_profile_provider.dart';

class ProfileImageSection extends StatefulWidget {
  final EditProfileProvider provider;
  final BuildContext context;

  const ProfileImageSection({
    super.key,
    required this.provider,
    required this.context,
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
          await PermissionService.requestPhotosPermissionWithRationale(
            widget.context,
          );
      if (!granted) {
        if (widget.context.mounted) {
          ScaffoldMessenger.of(widget.context).showSnackBar(
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

      // Pick image from gallery only
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      // Show loading indicator
      if (widget.context.mounted) {
        ScaffoldMessenger.of(widget.context).showSnackBar(
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
                Text('جاري معالجة الصورة...'),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Compress image directly (no compute function)
      final compressedFile = await _compressImage(pickedFile.path);
      if (compressedFile != null) {
        // Update the provider with the compressed image
        widget.provider.updateProfileImage(File(compressedFile.path));

        if (widget.context.mounted) {
          ScaffoldMessenger.of(widget.context).showSnackBar(
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
        if (widget.context.mounted) {
          ScaffoldMessenger.of(widget.context).showSnackBar(
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
      debugPrint('Error picking image: $e');
      if (widget.context.mounted) {
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

        ScaffoldMessenger.of(widget.context).showSnackBar(
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
      debugPrint('Starting image compression for: $imagePath');

      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: 70, // Higher quality for profile images
        minWidth: 400,
        minHeight: 400,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final file = File(result.path);
        final size = await file.length();
        debugPrint('Image compressed successfully: ${size / 1024}KB');
        return result;
      } else {
        debugPrint('Image compression failed');
        return null;
      }
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }

  ImageProvider? _getProfileImage() {
    if (widget.provider.profileImage != null) {
      return FileImage(widget.provider.profileImage!);
    }
    return null;
  }

  Widget _getProfileImageChild() {
    // Show picked image if available
    if (widget.provider.profileImage != null) {
      return ClipOval(
        child: Image.file(
          widget.provider.profileImage!,
          width: Responsive.space(widget.context, size: Space.large) * 10,
          height: Responsive.space(widget.context, size: Space.large) * 10,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading picked image: $error');
            return _buildDefaultIcon();
          },
        ),
      );
    }

    // Show network image if available
    if (widget.provider.userProfile?.profileImageUrl != null &&
        widget.provider.userProfile!.profileImageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.provider.userProfile!.profileImageUrl!,
          width: Responsive.space(widget.context, size: Space.large) * 10,
          height: Responsive.space(widget.context, size: Space.large) * 10,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                width: Responsive.space(widget.context, size: Space.large) * 10,
                height:
                    Responsive.space(widget.context, size: Space.large) * 10,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey[600]!,
                    ),
                  ),
                ),
              ),
          errorWidget: (context, url, error) => _buildDefaultIcon(),
        ),
      );
    }

    // Default icon
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: Responsive.space(widget.context, size: Space.large) * 10,
      height: Responsive.space(widget.context, size: Space.large) * 10,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: Colors.grey[600],
        size: Responsive.space(widget.context, size: Space.large) * 3,
      ),
    );
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
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      // Main profile image
                      Container(
                        width:
                            Responsive.space(context, size: Space.large) * 12,
                        height:
                            Responsive.space(context, size: Space.large) * 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: _getProfileImageChild(),
                          ),
                        ),
                      ),

                      // Camera button
                      GestureDetector(
                        onTap: _isLoading ? null : _pickImage,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.all(
                            Responsive.space(context, size: Space.small),
                          ),
                          decoration: BoxDecoration(
                            color: _isLoading ? Colors.grey[400] : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey[600]!,
                                      ),
                                    ),
                                  )
                                  : Icon(
                                    Icons.photo_library,
                                    color: Colors.black87,
                                    size: 20,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Helper text
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          Text(
            'اضغط على أيقونة المعرض لتغيير الصورة',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
