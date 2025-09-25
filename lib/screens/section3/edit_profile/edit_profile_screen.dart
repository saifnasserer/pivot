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

        if (editProfileProvider.isLoading) {
          return _buildLoadingScreen();
        } else if (editProfileProvider.userProfile != null) {
          return _buildMainScreen(editProfileProvider);
        } else {
          return _buildErrorScreen(editProfileProvider);
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
        appBar: _buildAppBar(),
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
        appBar: _buildAppBar(),
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
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              child: Column(
                children: [
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

  PreferredSizeWidget _buildAppBar() {
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
    );
  }
}
