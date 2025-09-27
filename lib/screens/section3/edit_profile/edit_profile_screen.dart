import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivot/data/form_options.dart';
import 'edit_profile_provider.dart';
import 'profile_image_section.dart';
import 'basic_info_section.dart';
import 'educational_details_section.dart';
import 'password_section.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/data_deletion_dialog.dart';
import 'action_buttons.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedYear;
  String? _selectedDepartment;
  String? _selectedSection;
  String? _selectedGender;

  List<String> _availableDepartments = [];
  List<String> _availableSections = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditProfileProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Check for unsaved changes before navigation
  Future<bool> _onWillPop(EditProfileProvider provider) async {
    if (!provider.hasUnsavedChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('تغييرات غير محفوظة'),
            content: const Text(
              'لديك تغييرات غير محفوظة. هل تريد المتابعة دون حفظ؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('متابعة'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  @override
  void didChangeMetrics() {
    // Force rebuild when system UI metrics change (notification bar, keyboard, etc.)
    setState(() {});
  }

  void _initializeFormData(EditProfileProvider provider) {
    if (!_isInitialized && provider.userProfile != null) {
      _nameController.text = provider.userProfile!.name;
      _selectedYear = provider.userProfile!.level;
      _selectedDepartment = provider.userProfile!.department;
      _selectedSection = provider.userProfile!.section;
      _selectedGender = provider.userProfile!.gender;

      _availableDepartments = FormOptions.getDepartmentsForYear(
        provider.userProfile!.level,
      );
      _updateAvailableSections(provider);

      _isInitialized = true;
      setState(() {});
    }
  }

  void _updateAvailableSections(EditProfileProvider provider) {
    if (_selectedDepartment != null &&
        provider.sectionCounts.containsKey(_selectedDepartment)) {
      final count = provider.sectionCounts[_selectedDepartment]!;
      _availableSections = List<String>.generate(count, (i) => '${i + 1}');
    } else {
      _availableSections = [];
    }
  }

  void _updateBasicInfo(EditProfileProvider provider) {
    provider.updateBasicInfo(_nameController.text, _selectedGender ?? '');
  }

  void _updateEducationalInfo(EditProfileProvider provider) {
    provider.updateEducationalInfo(
      _selectedYear ?? '',
      _selectedDepartment ?? '',
      _selectedSection ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditProfileProvider>(
      builder: (context, editProfileProvider, child) {
        // Initialize form data if not already set
        if (editProfileProvider.userProfile != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeFormData(editProfileProvider);
          });
        }

        // Show error message if any
        if (editProfileProvider.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(editProfileProvider.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
            editProfileProvider.clearError();
          });
        }

        // Show success message only when user actually saves
        if (editProfileProvider.hasSaved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حفظ التغييرات بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
              editProfileProvider.clearSaveStatus();
              Navigator.pop(context);
            }
          });
        }

        if (editProfileProvider.isLoading &&
            editProfileProvider.userProfile == null) {
          return _buildLoadingScreen();
        } else if (editProfileProvider.userProfile != null) {
          return _buildMainScreen(editProfileProvider);
        } else if (editProfileProvider.errorMessage != null) {
          return _buildErrorScreen(editProfileProvider);
        } else {
          // Show loading while waiting for initial data
          return _buildLoadingScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'تعديل الملف الشخصي',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorScreen(EditProfileProvider provider) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(provider),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل البيانات',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.loadProfile(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen(EditProfileProvider provider) {
    _updateAvailableSections(provider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            final shouldPop = await _onWillPop(provider);
            if (shouldPop && mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: _buildAppBar(provider),
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.medium),
                ),
                child: Column(
                  children: [
                    // Progress indicator
                    _buildProgressIndicator(provider),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    ProfileImageSection(provider: provider, context: context),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),
                    BasicInfoSection(
                      provider: provider,
                      nameController: _nameController,
                      selectedGender: _selectedGender,
                      onGenderChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                        _updateBasicInfo(provider);
                      },
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    EducationalDetailsSection(
                      provider: provider,
                      selectedYear: _selectedYear,
                      selectedDepartment: _selectedDepartment,
                      selectedSection: _selectedSection,
                      availableDepartments: _availableDepartments,
                      availableSections: _availableSections,
                      onYearChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                          _selectedDepartment = null;
                          _selectedSection = null;
                          _availableDepartments =
                              FormOptions.getDepartmentsForYear(value);
                          _updateAvailableSections(provider);
                        });
                        _updateEducationalInfo(provider);
                      },
                      onDepartmentChanged: (value) {
                        setState(() {
                          _selectedDepartment = value;
                          _selectedSection = null;
                          _updateAvailableSections(provider);
                        });
                        _updateEducationalInfo(provider);
                      },
                      onSectionChanged: (String? newValue) {
                        setState(() {
                          _selectedSection = newValue;
                        });
                        _updateEducationalInfo(provider);
                      },
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    PasswordSection(
                      currentPasswordController: _currentPasswordController,
                      newPasswordController: _newPasswordController,
                      confirmPasswordController: _confirmPasswordController,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),

                    ActionButtons(
                      provider: provider,
                      currentPasswordController: _currentPasswordController,
                      newPasswordController: _newPasswordController,
                      confirmPasswordController: _confirmPasswordController,
                    ),

                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),

                    // Data Deletion Section
                    _buildDataDeletionSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataDeletionSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.delete_forever,
                color: Colors.red[700],
                size: Responsive.text(context, size: TextSize.heading),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Expanded(
                child: Text(
                  'حذف جميع البيانات',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: Responsive.space(context, size: Space.small)),

          Text(
            'يمكنك حذف جميع بياناتك وحسابك نهائياً. هذا الإجراء لا يمكن التراجع عنه.',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.red[600],
              height: 1.4,
            ),
          ),

          SizedBox(height: Responsive.space(context, size: Space.medium)),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const DataDeletionDialog(),
                );
              },
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: Text(
                'حذف جميع البيانات',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.text(context, size: TextSize.medium),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.space(context, size: Space.medium),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCompletionMessage(EditProfileProvider provider) {
    bool hasProfilePicture =
        provider.userProfile?.profileImageUrl != null &&
        provider.userProfile!.profileImageUrl!.isNotEmpty;

    if (hasProfilePicture) {
      return 'أكمل جميع الحقول المطلوبة لتحسين ملفك الشخصي';
    } else {
      return 'أضف صورة شخصية لتحقيق 100% من اكتمال الملف الشخصي';
    }
  }

  Widget _buildProgressIndicator(EditProfileProvider provider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_turned_in,
                color: Colors.blue[600],
                size: 20,
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'اكتمال الملف الشخصي',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${(provider.completionPercentage * 100).round()}%',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          LinearProgressIndicator(
            value: provider.completionPercentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              provider.completionPercentage == 1.0
                  ? Colors.green
                  : Colors.blue[600]!,
            ),
            minHeight: 8,
          ),
          if (provider.completionPercentage < 1.0) ...[
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              _getCompletionMessage(provider),
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(EditProfileProvider provider) {
    return AppBar(
      title: Text(
        'تعديل الملف الشخصي',
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.heading),
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      actions: [
        if (provider.hasUnsavedChanges)
          Container(
            margin: EdgeInsets.only(
              right: Responsive.space(context, size: Space.small),
            ),
            child: Icon(Icons.circle, color: Colors.orange, size: 12),
          ),
      ],
    );
  }
}
