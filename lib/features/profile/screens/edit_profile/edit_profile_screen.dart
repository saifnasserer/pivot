import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/features/profile/providers/edit_profile_provider.dart';
import 'profile_image_section.dart';
import 'basic_info_section.dart';
import 'educational_details_section.dart';
import 'password_section.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/data_deletion_dialog.dart';
import 'action_buttons.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
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
      ref.read(editProfileProvider.notifier).loadProfile();
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
  Future<bool> _onWillPop(EditProfileState state) async {
    if (!state.hasUnsavedChanges) {
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

  void _initializeFormData(EditProfileState state) {
    if (!_isInitialized && state.userProfile != null) {
      _nameController.text = state.userProfile!.name;
      _selectedYear = state.userProfile!.level;
      _selectedDepartment = state.userProfile!.department;
      _selectedSection = state.userProfile!.section;
      _selectedGender = state.userProfile!.gender;

      _availableDepartments = FormOptions.getDepartmentsForYear(
        state.userProfile!.level,
      );
      _updateAvailableSections(state);

      _isInitialized = true;
      setState(() {});
    }
  }

  void _updateAvailableSections(EditProfileState state) {
    if (_selectedDepartment != null &&
        state.sectionCounts.containsKey(_selectedDepartment)) {
      final count = state.sectionCounts[_selectedDepartment]!;
      _availableSections = List<String>.generate(count, (i) => '${i + 1}');
    } else {
      _availableSections = [];
    }
  }

  void _updateBasicInfo() {
    ref
        .read(editProfileProvider.notifier)
        .updateBasicInfo(_nameController.text, _selectedGender ?? '');
  }

  void _updateEducationalInfo() {
    ref
        .read(editProfileProvider.notifier)
        .updateEducationalInfo(
          _selectedYear ?? '',
          _selectedDepartment ?? '',
          _selectedSection ?? '',
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileProvider);

    // Initialize form data if not already set
    if (state.userProfile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeFormData(state);
      });
    }

    // Show error message if any
    if (state.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(editProfileProvider.notifier).clearError();
      });
    }

    // Show success message only when user actually saves
    if (state.hasSaved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ التغييرات بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          ref.read(editProfileProvider.notifier).clearSaveStatus();
          Navigator.pop(context);
        }
      });
    }

    if (state.isLoading && state.userProfile == null) {
      return _buildLoadingScreen();
    } else if (state.userProfile != null) {
      return _buildMainScreen(state);
    } else if (state.errorMessage != null) {
      return _buildErrorScreen(state);
    } else {
      // Show loading while waiting for initial data
      return _buildLoadingScreen();
    }
  }

  Widget _buildLoadingScreen() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
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
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(EditProfileState state) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(state),
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
                onPressed:
                    () => ref.read(editProfileProvider.notifier).loadProfile(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen(EditProfileState state) {
    _updateAvailableSections(state);

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
            final shouldPop = await _onWillPop(state);
            if (shouldPop && mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(state),
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.medium),
                  vertical: Responsive.space(context, size: Space.large),
                ),
                child: Column(
                  children: [
                    // Profile image with completion indicator
                    ProfileImageSection(state: state, widgetRef: ref),
                    SizedBox(
                      height: Responsive.space(context, size: Space.tiny),
                    ),
                    _buildCompactProgressIndicator(state),
                    SizedBox(
                      height: Responsive.space(context, size: Space.xlarge),
                    ),

                    // All fields in one clean flow
                    BasicInfoSection(
                      state: state,
                      nameController: _nameController,
                      selectedGender: _selectedGender,
                      onGenderChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                        _updateBasicInfo();
                      },
                    ),

                    // Simple divider
                    SizedBox(
                      height: Responsive.space(context, size: Space.xlarge),
                    ),
                    Container(
                      height: 1,
                      color: Colors.grey[200],
                      margin: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.large,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.xlarge),
                    ),

                    EducationalDetailsSection(
                      state: state,
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
                          _updateAvailableSections(state);
                        });
                        _updateEducationalInfo();
                      },
                      onDepartmentChanged: (value) {
                        setState(() {
                          _selectedDepartment = value;
                          _selectedSection = null;
                          _updateAvailableSections(state);
                        });
                        _updateEducationalInfo();
                      },
                      onSectionChanged: (String? newValue) {
                        setState(() {
                          _selectedSection = newValue;
                        });
                        _updateEducationalInfo();
                      },
                    ),

                    // Simple divider
                    SizedBox(
                      height: Responsive.space(context, size: Space.xlarge),
                    ),
                    Container(
                      height: 1,
                      color: Colors.grey[200],
                      margin: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.large,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.xlarge),
                    ),

                    PasswordSection(
                      state: state,
                      widgetRef: ref,
                      currentPasswordController: _currentPasswordController,
                      newPasswordController: _newPasswordController,
                      confirmPasswordController: _confirmPasswordController,
                    ),

                    SizedBox(
                      height: Responsive.space(context, size: Space.xlarge),
                    ),

                    ActionButtons(
                      state: state,
                      widgetRef: ref,
                      currentPasswordController: _currentPasswordController,
                      newPasswordController: _newPasswordController,
                      confirmPasswordController: _confirmPasswordController,
                    ),

                    SizedBox(
                      height: Responsive.space(context, size: Space.xlarge),
                    ),

                    // Data Deletion Section
                    _buildDataDeletionSection(),

                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
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
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const DataDeletionDialog(),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                  SizedBox(width: Responsive.space(context, size: Space.small)),
                  Expanded(
                    child: Text(
                      'حذف الحساب والبيانات',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.red[300],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProgressIndicator(EditProfileState state) {
    final percentage = (state.completionPercentage * 100).round();
    final isComplete = state.completionPercentage == 1.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'اكتمال الملف',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: Responsive.space(context, size: Space.tiny)),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: isComplete ? Colors.green[600] : Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.space(context, size: Space.tiny)),
        Container(
          width: 120,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerRight,
            widthFactor: state.completionPercentage,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isComplete
                          ? [Colors.green[400]!, Colors.green[600]!]
                          : [Colors.blue[400]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(EditProfileState state) {
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
        if (state.hasUnsavedChanges)
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
