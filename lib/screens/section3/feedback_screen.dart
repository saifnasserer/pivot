import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:pivot/widgets/no_internet_message.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedCategory = 'فيدباك عام';
  bool _isSubmitting = false;
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  // ValueNotifiers for validation state - prevents full rebuilds
  final ValueNotifier<bool> _isFeedbackValid = ValueNotifier<bool>(false);

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'فيدباك عام',
      'icon': Icons.feedback_outlined,
      'color': Colors.blue,
    },
    {
      'name': 'مشكلة تقنية',
      'icon': Icons.bug_report_outlined,
      'color': Colors.red,
    },
    {
      'name': 'شكوى',
      'icon': Icons.report_problem_outlined,
      'color': Colors.purple,
    },
    {'name': 'استفسار', 'icon': Icons.help_outline, 'color': Colors.green},
    {'name': 'أخرى', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _feedbackController.dispose();
    _isFeedbackValid.dispose();
    _selectedImage?.delete();
    super.dispose();
  }

  String? _validateFeedback(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال رأيك';
    }
    if (value.trim().length < 10) {
      return 'يجب أن يكون الرأي أكثر من 10 أحرف';
    }
    if (value.trim().length > 1000) {
      return 'يجب أن يكون الرأي أقل من 1000 حرف';
    }
    return null;
  }

  void _onFeedbackChanged(String value) {
    final isValidNow = _validateFeedback(value) == null;
    if (_isFeedbackValid.value != isValidNow) {
      _isFeedbackValid.value = isValidNow;
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final isSelected = _selectedCategory == category['name'];

    return GestureDetector(
      onTap: () => _onCategorySelected(category['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? category['color'] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? category['color'] : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? category['color'] : Colors.grey).withOpacity(
                0.1,
              ),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['icon'],
              size: 32,
              color: isSelected ? Colors.white : category['color'],
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              category['name'],
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    required Function(String) onChanged,
    required ValueNotifier<bool> isValidNotifier,
    int maxLines = 4,
    bool isOptional = false,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: isValidNotifier,
      builder: (context, isValid, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isValid ? Colors.green : Colors.grey[200]!,
              width: isValid ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: Responsive.text(context, size: TextSize.medium),
              ),
              suffixIcon:
                  isOptional
                      ? Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        margin: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'اختياري',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                      : null,
            ),
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.black87,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NoInternetMessage(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'إرسال ملاحظات',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: Responsive.padding(context, size: Space.large),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      Container(
                        padding: Responsive.padding(context, size: Space.large),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue[50]!, Colors.white],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(
                                Responsive.space(context, size: Space.medium),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.feedback_outlined,
                                size: 32,
                                color: Colors.blue[700],
                              ),
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Text(
                              'عايزين نسمع رأيك!',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Text(
                              'ساعدنا في تحسين التطبيق من خلال إرسال ملاحظاتك واقتراحاتك',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Category Selection
                      Text(
                        'نوع الملاحظة',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                          mainAxisSpacing: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          return _buildCategoryCard(_categories[index]);
                        },
                      ),

                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Feedback Field
                      Text(
                        'رأيك *',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),

                      _buildEnhancedTextField(
                        controller: _feedbackController,
                        hint: 'اكتب رأيك هنا...',
                        validator: _validateFeedback,
                        onChanged: _onFeedbackChanged,
                        isValidNotifier: _isFeedbackValid,
                      ),

                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Image Upload Section
                      Text(
                        'إرفاق صورة (اختياري)',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),

                      // Image Upload Button
                      if (_selectedImage == null) ...[
                        Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[50],
                          ),
                          child: InkWell(
                            onTap: _isUploadingImage ? null : _pickImage,
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isUploadingImage)
                                  Column(
                                    children: [
                                      const CircularProgressIndicator(),
                                      SizedBox(
                                        height: Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                      ),
                                      Text(
                                        'جاري رفع الصورة...',
                                        style: TextStyle(
                                          fontSize: Responsive.text(
                                            context,
                                            size: TextSize.small,
                                          ),
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.small,
                                    ),
                                  ),
                                  Text(
                                    'اضغط لإضافة صورة',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Display Uploaded Image
                      if (_selectedImage != null) ...[
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        Text(
                          'الصورة المرفوعة',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                              _uploadedImageUrl = null;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('حذف الصورة'),
                        ),
                      ],

                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Submit Button - Uses ValueListenableBuilder to avoid rebuilds
                      ValueListenableBuilder<bool>(
                        valueListenable: _isFeedbackValid,
                        builder: (context, isFeedbackValid, child) {
                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                                  _isSubmitting || !isFeedbackValid
                                      ? null
                                      : _submitFeedback,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isFeedbackValid
                                        ? Colors.black
                                        : Colors.grey,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child:
                                  _isSubmitting
                                      ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: Responsive.space(
                                              context,
                                              size: Space.small,
                                            ),
                                          ),
                                          Text(
                                            'جاري الإرسال...',
                                            style: TextStyle(
                                              fontSize: Responsive.text(
                                                context,
                                                size: TextSize.medium,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.send, size: 20),
                                          SizedBox(
                                            width: Responsive.space(
                                              context,
                                              size: Space.small,
                                            ),
                                          ),
                                          Text(
                                            'إرسال الملاحظات',
                                            style: TextStyle(
                                              fontSize: Responsive.text(
                                                context,
                                                size: TextSize.medium,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );
      final userProfile = userProfileProvider.loggedInUserProfile;

      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final feedbackData = {
        'userId': user.uid,
        'userName': userProfile.name,
        'userEmail': userProfile.email,
        'category': _selectedCategory,
        'feedback': _feedbackController.text.trim(),
        'imageUrl': _uploadedImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إرسال ملاحظاتك بنجاح! شكراً لك',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء إرسال الملاحظات. يرجى المحاولة مرة أخرى',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يجب تسجيل الدخول أولاً لرفع الصور'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    // Check permissions first
    final hasPermission =
        await PermissionService.requestPhotosPermissionWithRationale(context);
    if (!hasPermission) return;

    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _isUploadingImage = true;
      });

      try {
        // Compress the image
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          pickedFile.path,
          minWidth: 1024,
          minHeight: 1024,
          quality: 80,
        );

        if (compressedBytes != null) {
          final fileName =
              'feedback_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = FirebaseStorage.instance.ref().child(
            'feedback/$fileName',
          );

          final uploadTask = ref.putData(compressedBytes);
          final snapshot = await uploadTask;

          if (snapshot.state == TaskState.success) {
            final downloadUrl = await snapshot.ref.getDownloadURL();
            setState(() {
              _selectedImage = File(pickedFile.path);
              _uploadedImageUrl = downloadUrl;
              _isUploadingImage = false;
            });
          } else {
            throw Exception('Upload failed');
          }
        } else {
          throw Exception('Image compression failed');
        }
      } catch (e) {
        setState(() {
          _isUploadingImage = false;
        });
        if (mounted) {
          String errorMessage =
              'حدث خطأ أثناء رفع الصورة. يرجى المحاولة مرة أخرى';

          // Provide more specific error messages
          if (e.toString().contains('Permission denied') ||
              e.toString().contains('403')) {
            errorMessage =
                'لا توجد صلاحية لرفع الصورة. يرجى التأكد من تسجيل الدخول';
          } else if (e.toString().contains('network') ||
              e.toString().contains('connection')) {
            errorMessage =
                'خطأ في الاتصال. يرجى التحقق من الإنترنت والمحاولة مرة أخرى';
          } else if (e.toString().contains('storage')) {
            errorMessage = 'خطأ في التخزين. يرجى المحاولة مرة أخرى';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
}
