import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:pivot/widgets/no_internet_message.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _suggestionController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedCategory = 'فيدباك عام';
  bool _isSubmitting = false;
  bool _isFeedbackValid = false;
  bool _isSuggestionValid = false;
  bool _showSuggestionField = false;

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
      'name': 'اقتراح تحسين',
      'icon': Icons.lightbulb_outline,
      'color': Colors.orange,
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
    _suggestionController.dispose();
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

  String? _validateSuggestion(String? value) {
    if (_showSuggestionField && (value == null || value.trim().isEmpty)) {
      return 'الرجاء إدخال اقتراحك';
    }
    if (value != null && value.trim().length > 500) {
      return 'يجب أن يكون الاقتراح أقل من 500 حرف';
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
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('تم إرسال الملاحظات بنجاح! شكراً لك')),
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

      _feedbackController.clear();
      _suggestionController.clear();
      setState(() {
        _selectedCategory = 'فيدباك عام';
        _isFeedbackValid = false;
        _isSuggestionValid = false;
        _showSuggestionField = false;
      });

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('فشل إرسال الملاحظات: $e')),
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final isSelected = _selectedCategory == category['name'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category['name'];
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
        decoration: BoxDecoration(
          color: isSelected ? category['color'].withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? category['color'] : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
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
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.small),
              ),
              decoration: BoxDecoration(
                color: isSelected ? category['color'] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category['icon'],
                color: isSelected ? Colors.white : category['color'],
                size: 24,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              category['name'],
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                fontWeight: FontWeight.w600,
                color: isSelected ? category['color'] : Colors.black87,
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
    int maxLines = 4,
    bool isOptional = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: NoInternetMessage(
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
          body: FadeTransition(
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
                        onChanged: (value) {
                          final isValidNow = _validateFeedback(value) == null;
                          if (_isFeedbackValid != isValidNow) {
                            setState(() {
                              _isFeedbackValid = isValidNow;
                            });
                          }
                        },
                      ),

                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Suggestion Toggle
                      Row(
                        children: [
                          Switch(
                            value: _showSuggestionField,
                            onChanged: (value) {
                              setState(() {
                                _showSuggestionField = value;
                                if (!value) {
                                  _suggestionController.clear();
                                  _isSuggestionValid = false;
                                }
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Text(
                            'إضافة اقتراح تحسين',
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      if (_showSuggestionField) ...[
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        Text(
                          'اقتراحك',
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
                          controller: _suggestionController,
                          hint: 'اكتب اقتراحك هنا...',
                          validator: _validateSuggestion,
                          onChanged: (value) {
                            final isValidNow =
                                _validateSuggestion(value) == null;
                            if (_isSuggestionValid != isValidNow) {
                              setState(() {
                                _isSuggestionValid = isValidNow;
                              });
                            }
                          },
                          isOptional: true,
                        ),
                      ],

                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Submit Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child:
                              _isSubmitting
                                  ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
}
