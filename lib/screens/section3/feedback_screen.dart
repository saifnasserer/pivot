import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';

class FeedbackScreen extends StatefulWidget {
  static const String id = 'feedback_screen';

  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _suggestionController = TextEditingController();
  String _selectedCategory = 'تعليق عام';
  bool _isSubmitting = false;
  bool _isFeedbackValid = false;
  bool _isSuggestionValid = false;

  final List<String> _categories = [
    'تعليق عام',
    'مشكلة تقنية',
    'اقتراح تحسين',
    'شكوى',
    'استفسار',
    'أخرى',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  String? _validateFeedback(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال التعليق';
    }
    if (value.trim().length < 10) {
      return 'يجب أن يكون التعليق أكثر من 10 أحرف';
    }
    if (value.trim().length > 1000) {
      return 'يجب أن يكون التعليق أقل من 1000 حرف';
    }
    return null;
  }

  String? _validateSuggestion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال الاقتراح';
    }
    if (value.trim().length < 10) {
      return 'يجب أن يكون الاقتراح أكثر من 10 أحرف';
    }
    if (value.trim().length > 1000) {
      return 'يجب أن يكون الاقتراح أقل من 1000 حرف';
    }
    return null;
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userProfile =
          Provider.of<UserProfileProvider>(context, listen: false).userProfile;

      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final feedbackData = {
        'userId': user.uid,
        'userEmail': user.email,
        'userName': userProfile?.name ?? 'مستخدم مجهول',
        'userRole': userProfile?.role ?? 'غير محدد',
        'category': _selectedCategory,
        'feedback': _feedbackController.text.trim(),
        'suggestion': _suggestionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'appVersion': '1.0.0',
        'platform': Theme.of(context).platform.name,
      };

      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال الملاحظات بنجاح! شكراً لك'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      _feedbackController.clear();
      _suggestionController.clear();
      setState(() {
        _selectedCategory = 'تعليق عام';
        _isFeedbackValid = false;
        _isSuggestionValid = false;
      });

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إرسال الملاحظات: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
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
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: Responsive.padding(context, size: Space.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: Responsive.padding(context, size: Space.large),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.feedback_outlined,
                        size: 48,
                        color: Colors.blue,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      Text(
                        'نحن نريد سماع رأيك!',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
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

                SizedBox(height: Responsive.space(context, size: Space.large)),

                Text(
                  'نوع الملاحظة',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: Responsive.padding(
                        context,
                        size: Space.medium,
                      ),
                      prefixIcon: Icon(Icons.category, color: Colors.blue),
                    ),
                    items:
                        _categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                ),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                Text(
                  'التعليق (اختياري)',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                CustomTextField(
                  controller: _feedbackController,
                  hint: 'اكتب تعليقك هنا...',
                  maxLines: 4,
                  isValid: _isFeedbackValid,
                  onChanged: (value) {
                    setState(() {
                      _isFeedbackValid = _validateFeedback(value) == null;
                    });
                  },
                ),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                Text(
                  'الاقتراح (اختياري)',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                CustomTextField(
                  controller: _suggestionController,
                  hint: 'اكتب اقتراحك هنا...',
                  maxLines: 4,
                  isValid: _isSuggestionValid,
                  onChanged: (value) {
                    setState(() {
                      _isSuggestionValid = _validateSuggestion(value) == null;
                    });
                  },
                ),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton.icon(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    icon:
                        _isSubmitting
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Icon(Icons.send, color: Colors.white),
                    label: Text(
                      _isSubmitting ? 'جاري الإرسال...' : 'إرسال الملاحظات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.space(context, size: Space.medium),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                Container(
                  padding: Responsive.padding(context, size: Space.medium),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      Text(
                        'ملاحظات مهمة',
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
                      Text(
                        '• سيتم مراجعة ملاحظاتك من قبل فريق التطوير\n• قد نتواصل معك عبر البريد الإلكتروني للمزيد من التفاصيل\n• شكراً لك على مساعدتنا في تحسين التطبيق',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
