import 'dart:io' show File;
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/custom_dropdown.dart';
import 'package:pivot/providers/settings_provider.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'package:pivot/services/permission_service.dart';

class EditProfile extends StatefulWidget {
  // = 'edit_profile';
  final UserProfile userProfile;

  const EditProfile({super.key, required this.userProfile});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  bool _isUploading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode yearFocusNode = FocusNode();
  final FocusNode departFocusNode = FocusNode();
  final FocusNode sectionFocusNode = FocusNode();
  final FocusNode currentPasswordFocusNode = FocusNode();
  final FocusNode newPasswordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();
  String? _year, _department, _section, _gender;
  bool _isNameValid = true,
      _isYearValid = true,
      _isDepartmentValid = true,
      _isSectionValid = true,
      _isPasswordValid = true,
      _isCurrentPasswordValid = true,
      _isConfirmPasswordValid = true,
      _isGenderValid = true;

  List<String> _availableDepartments = [];
  List<String> _availableSections = [];

  late TextEditingController _nameController;
  String _password = '';
  String _currentPassword = '';
  String _confirmPassword = '';

  bool _isPasswordVisible = false;
  bool _isCurrentPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Performance optimization: Debounce timer for setState calls
  Timer? _debounceTimer;
  bool _needsRebuild = false;

  @override
  void initState() {
    super.initState();
    final user = widget.userProfile;
    _nameController = TextEditingController(text: user.name);

    _year = user.level;
    _department = user.department;
    _section = user.section;
    _gender = user.gender;

    _availableDepartments = FormOptions.getDepartmentsForYear(_year);
    _availableSections = [];

    if (!FormOptions.academicYears.contains(_year)) _year = null;
    if (!_availableDepartments.contains(_department)) _department = null;
    if (!_availableSections.contains(_section)) _section = null;
    if (!FormOptions.genders.contains(_gender)) _gender = null;

    _isNameValid = _validateName(user.name) == null;
    _isYearValid = _year != null;
    _isDepartmentValid = _department != null;
    _isSectionValid = _section != null;
    _isGenderValid = _gender != null;

    // Fetch section counts after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).fetchSectionCounts();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    nameFocusNode.dispose();
    yearFocusNode.dispose();
    departFocusNode.dispose();
    sectionFocusNode.dispose();
    currentPasswordFocusNode.dispose();
    newPasswordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();

    // Cancel debounce timer
    _debounceTimer?.cancel();

    // Clear sensitive data from memory
    _password = '';
    _currentPassword = '';
    _confirmPassword = '';

    super.dispose();
  }

  // Performance optimization: Debounced setState to prevent excessive rebuilds
  void _debouncedSetState(VoidCallback fn) {
    fn();
    _needsRebuild = true;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (_needsRebuild && mounted) {
        _needsRebuild = false;
        setState(() {});
      }
    });
  }

  Future<void> _pickImage() async {
    //debugprint('[EditProfile] Starting image pick process');
    bool granted = await PermissionService.requestPhotosPermissionWithRationale(
      context,
    );
    //debugprint('[EditProfile] Permission granted: $granted');
    if (!granted) return;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    //debugprint('[EditProfile] Picked file: \\${pickedFile?.path}');
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
    });

    // Compress image on background thread to prevent UI blocking
    try {
      final compressedFile = await compute(_compressImage, pickedFile.path);
      if (compressedFile != null && mounted) {
        setState(() {
          _imageFile = File(compressedFile.path);
        });
        //debugprint('[EditProfile] Image compressed and set in state');
      }
    } catch (e) {
      //debugprint('[EditProfile] Exception during compression: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء ضغط الصورة: $e')));
      }
    }
  }

  // Static method for background image compression
  static Future<XFile?> _compressImage(String imagePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      //debugprint('[EditProfile] Compressing image to: $targetPath');

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: 60,
        minWidth: 600,
        minHeight: 600,
        format: CompressFormat.jpeg,
      );
      //debugprint('[EditProfile] Compressed file: \\${compressedFile?.path}');
      return compressedFile;
    } catch (e) {
      //debugprint('[EditProfile] Compression error: $e');
      return null;
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'الاسم مطلوب';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }

    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (_password.isNotEmpty && (value == null || value.isEmpty)) {
      return 'كلمة المرور الحالية مطلوبة لتغيير كلمة المرور';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_password.isNotEmpty && (value == null || value.isEmpty)) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (_password.isNotEmpty && value != _password) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final sectionCounts = settingsProvider.sectionCounts;

    if (settingsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
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
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            child: Column(
              children: [
                // Profile Image Section
                _buildProfileImageSection(),
                SizedBox(height: Responsive.space(context, size: Space.large)),

                // Basic Information Section
                _buildBasicInfoSection(),
                SizedBox(height: Responsive.space(context, size: Space.medium)),

                // Educational Details Section
                _buildEducationalDetailsSection(sectionCounts),
                SizedBox(height: Responsive.space(context, size: Space.medium)),

                // Password Settings Section
                _buildPasswordSection(),
                SizedBox(height: Responsive.space(context, size: Space.large)),

                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: Responsive.space(context, size: Space.large) * 5,
            backgroundColor: Colors.black,
            backgroundImage: _getProfileImage(),
            child: _getProfileImageChild(),
          ),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: Responsive.padding(context, size: Space.small),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      return kIsWeb
          ? CachedNetworkImageProvider(_imageFile!.path)
          : FileImage(File(_imageFile!.path));
    } else if (widget.userProfile.profileImageUrl != null &&
        widget.userProfile.profileImageUrl!.isNotEmpty) {
      // Return null initially, will be handled by FutureBuilder
      return null;
    }
    return null;
  }

  Widget? _getProfileImageChild() {
    if (_imageFile != null) {
      return null; // Show the picked image
    } else if (widget.userProfile.profileImageUrl != null &&
        widget.userProfile.profileImageUrl!.isNotEmpty) {
      // Directly show the image
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.userProfile.profileImageUrl!,
          width: Responsive.space(context, size: Space.large) * 10,
          height: Responsive.space(context, size: Space.large) * 10,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          errorWidget:
              (context, url, error) =>
                  const Icon(Icons.person, color: Colors.white, size: 60),
        ),
      );
    }
    return const Icon(Icons.person, color: Colors.white, size: 60);
  }

  Widget _buildBasicInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, color: Colors.blue[600], size: 24),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'المعلومات الأساسية',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          CustomTextField(
            controller: _nameController,
            focusNode: nameFocusNode,
            hint: 'الاسم',
            keyboardType: TextInputType.name,
            onChanged: (value) {
              _debouncedSetState(() {
                _isNameValid = _validateName(value) == null;
              });
            },
            validator: (value) {
              return _validateName(value);
            },
            isValid: _isNameValid,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          CustomDropdown(
            color: Color(0xfff7f7f7),
            value: _gender,
            items: FormOptions.genders,
            hint: 'النوع',
            isValid: _isGenderValid,
            onChanged: (String? newValue) {
              _debouncedSetState(() {
                _gender = newValue;
                _isGenderValid = newValue != null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalDetailsSection(Map<String, int?> sectionCounts) {
    // Dynamically update sections based on the selected department
    if (_department != null && sectionCounts.containsKey(_department)) {
      _availableSections = List<String>.generate(
        sectionCounts[_department]!,
        (i) => '${i + 1}',
      );
    } else {
      _availableSections = [];
    }

    // If the currently selected section is no longer valid, reset it.
    if (!_availableSections.contains(_section)) {
      _section = null;
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, color: Colors.green[600], size: 24),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'التفاصيل الدراسية',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          CustomDropdown(
            color: Color(0xfff7f7f7),
            value: _year,
            items: FormOptions.academicYears,
            hint: 'اختر الفرقة',
            isValid: _isYearValid,
            onChanged: (value) {
              _debouncedSetState(() {
                _year = value;
                _isYearValid = value != null;
                _availableDepartments = FormOptions.getDepartmentsForYear(
                  _year,
                );
                if (!_availableDepartments.contains(_department)) {
                  _department = null;
                  _isDepartmentValid = false;
                }
                // Section is now handled by the build method, just reset it
                _section = null;
                _isSectionValid = false;
              });
              FocusScope.of(context).requestFocus(departFocusNode);
            },
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          CustomDropdown(
            color: Color(0xfff7f7f7),
            value: _department,
            items: _availableDepartments,
            hint: 'اختر القسم',
            isValid: _isDepartmentValid,
            onChanged: (value) {
              _debouncedSetState(() {
                _department = value;
                _isDepartmentValid = value != null;
                // Section is now handled by the build method, just reset it
                _section = null;
                _isSectionValid = false;
              });
              FocusScope.of(context).requestFocus(sectionFocusNode);
            },
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          CustomDropdown(
            color: Color(0xfff7f7f7),
            value: _section,
            items: _availableSections,
            hint: 'اختر السكشن',
            isValid: _isSectionValid,
            onChanged: (String? newValue) {
              _debouncedSetState(() {
                _section = newValue;
                _isSectionValid = newValue != null;
              });
              FocusScope.of(context).requestFocus(currentPasswordFocusNode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: Colors.orange[600], size: 24),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'إعدادات كلمة المرور',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),

          // Current Password Field
          CustomTextField(
            suffixIcon: IconButton(
              icon: Icon(
                _isCurrentPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                size: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey,
              ),
              onPressed: () {
                _debouncedSetState(() {
                  _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                });
              },
            ),
            focusNode: currentPasswordFocusNode,
            hint: 'كلمة المرور الحالية',
            keyboardType: TextInputType.visiblePassword,
            obscureText: !_isCurrentPasswordVisible,
            onChanged: (value) {
              _debouncedSetState(() {
                _currentPassword = value;
                _isCurrentPasswordValid =
                    _validateCurrentPassword(value) == null;
              });
            },
            validator: (value) {
              return _validateCurrentPassword(value);
            },
            isValid: _isCurrentPasswordValid,
            onEditingComplete: () => FocusScope.of(context).unfocus(),
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),

          // New Password Field
          CustomTextField(
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                size: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey,
              ),
              onPressed: () {
                _debouncedSetState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            focusNode: newPasswordFocusNode,
            hint: 'كلمة المرور الجديدة',
            keyboardType: TextInputType.visiblePassword,
            obscureText: !_isPasswordVisible,
            onChanged: (value) {
              _debouncedSetState(() {
                _password = value;
                if (value.isNotEmpty) {
                  _isPasswordValid = _validatePassword(value) == null;
                  // Re-validate confirm password when new password changes
                  _isConfirmPasswordValid =
                      _validateConfirmPassword(_confirmPassword) == null;
                } else {
                  _isPasswordValid = true; // Optional field
                  _isConfirmPasswordValid = true; // Reset confirm validation
                }
              });
            },
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                return _validatePassword(value);
              }
              return null; // No error if empty
            },
            isValid: _isPasswordValid,
            onEditingComplete: () => FocusScope.of(context).unfocus(),
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),

          // Confirm Password Field
          CustomTextField(
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                size: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey,
              ),
              onPressed: () {
                _debouncedSetState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            hint: 'تأكيد كلمة المرور الجديدة',
            keyboardType: TextInputType.visiblePassword,
            obscureText: !_isConfirmPasswordVisible,
            onChanged: (value) {
              _debouncedSetState(() {
                _confirmPassword = value;
                _isConfirmPasswordValid =
                    _validateConfirmPassword(value) == null;
              });
            },
            validator: (value) {
              return _validateConfirmPassword(value);
            },
            isValid: _isConfirmPasswordValid,
            onEditingComplete: () => FocusScope.of(context).unfocus(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child:
                _isUploading
                    ? Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        Text(
                          'يتم تحديث البيانات',
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
                    : ElevatedButton.icon(
                      onPressed: () async {
                        // Cancel any pending debounced updates before saving
                        _debounceTimer?.cancel();
                        _needsRebuild = false;

                        bool isFormValid =
                            _isNameValid &&
                            _isYearValid &&
                            _isDepartmentValid &&
                            _isSectionValid &&
                            _isPasswordValid &&
                            _isCurrentPasswordValid &&
                            _isConfirmPasswordValid &&
                            _isGenderValid;

                        if (isFormValid) {
                          setState(() {
                            _isUploading = true;
                          });

                          Map<String, dynamic> updatedData = {
                            'name': _nameController.text,
                            'gender': _gender,
                            'level': _year,
                            'department': _department,
                            'section': _section,
                          };
                          if (_password.isNotEmpty) {
                            updatedData['password'] = _password;
                            updatedData['currentPassword'] = _currentPassword;
                          }

                          try {
                            await context
                                .read<UserProfileProvider>()
                                .updateUserProfileData(
                                  widget.userProfile.id,
                                  updatedData,
                                  imageFile:
                                      _imageFile == null
                                          ? null
                                          : XFile(_imageFile!.path),
                                  context: context,
                                );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم حفظ التغييرات بنجاح',
                                    textAlign: TextAlign.center,
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (mounted) {
                              String errorMessage = _getSpecificErrorMessage(
                                e.toString(),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isUploading = false;
                              });
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'يرجى ملء جميع الحقول المطلوبة بشكل صحيح',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.check, color: Colors.white),
                      label: Text(
                        'حفظ التغييرات',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                      ),
                    ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.close, color: Colors.white),
              label: Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.space(context, size: Space.small),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSpecificErrorMessage(String errorMessage) {
    if (errorMessage.contains('requires-recent-login')) {
      return 'انتهت صلاحية الجلسة. يرجى إعادة تسجيل الدخول';
    } else if (errorMessage.contains('wrong-password')) {
      return 'كلمة المرور الحالية غير صحيحة';
    } else if (errorMessage.contains('weak-password')) {
      return 'كلمة المرور ضعيفة جداً';
    } else if (errorMessage.contains('operation-cancelled')) {
      return 'تم إلغاء العملية';
    } else if (errorMessage.contains('session-validation-failed')) {
      return 'فشل في التحقق من الجلسة';
    } else {
      return 'فشل في حفظ التغييرات';
    }
  }
}
