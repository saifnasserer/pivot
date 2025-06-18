import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/models/custom_dropdown.dart';
import 'package:pivot/providers/settings_provider.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  static const String id = 'edit_profile';
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
  final FocusNode passwordFocusNode = FocusNode();
  String? _year, _department, _section, _gender;
  bool _isNameValid = true,
      _isPasswordValid = true,
      _isYearValid = true,
      _isDepartmentValid = true,
      _isSectionValid = true,
      _isGenderValid = true;

  List<String> _availableDepartments = [];
  List<String> _availableSections = [];

  late TextEditingController _nameController;
  String _password = '';

  bool _isPasswordVisible = false;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    nameFocusNode.dispose();
    yearFocusNode.dispose();
    departFocusNode.dispose();
    sectionFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    if (croppedFile == null) return;

    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      croppedFile.path,
      targetPath,
      quality: 80,
    );

    if (compressedFile != null) {
      setState(() {
        _imageFile = File(compressedFile.path);
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'الاسم مطلوب';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value != null && value.isNotEmpty && value.length < 6) {
      return 'الباسورد يجب أن يكون 6 أحرف على الأقل';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final sectionCounts = settingsProvider.sectionCounts;

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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: Responsive.space(context, size: Space.large) * 5,
                      backgroundColor: Colors.black,
                      backgroundImage:
                          _imageFile != null
                              ? (kIsWeb
                                      ? NetworkImage(_imageFile!.path)
                                      : FileImage(File(_imageFile!.path)))
                                  as ImageProvider
                              : (widget.userProfile.profileImageUrl != null &&
                                      widget
                                          .userProfile
                                          .profileImageUrl!
                                          .isNotEmpty
                                  ? CachedNetworkImageProvider(
                                    widget.userProfile.profileImageUrl!,
                                  )
                                  : null),
                      child:
                          (_imageFile == null &&
                                  (widget.userProfile.profileImageUrl == null ||
                                      widget
                                          .userProfile
                                          .profileImageUrl!
                                          .isEmpty))
                              ? Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 60,
                              )
                              : null,
                    ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: Icon(Icons.camera_alt, color: Colors.black),
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
                    setState(() {
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
                    setState(() {
                      _gender = newValue;
                      _isGenderValid = newValue != null;
                    });
                  },
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                CustomDropdown(
                  color: Color(0xfff7f7f7),
                  value: _year,
                  items: FormOptions.academicYears,
                  hint: 'اختر الفرقة',
                  isValid: _isYearValid,
                  onChanged: (value) {
                    setState(() {
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
                    setState(() {
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
                    setState(() {
                      _section = newValue;
                      _isSectionValid = newValue != null;
                    });
                    FocusScope.of(context).requestFocus(passwordFocusNode);
                  },
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                CustomTextField(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: Responsive.text(context, size: TextSize.medium),
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  focusNode: passwordFocusNode,
                  hint: 'الباسورد الجديد',
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: !_isPasswordVisible,
                  onChanged: (value) {
                    setState(() {
                      _password = value;
                      if (value.isNotEmpty) {
                        _isPasswordValid = _validatePassword(value) == null;
                      } else {
                        _isPasswordValid = true; // Optional field
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
                SizedBox(height: Responsive.space(context, size: Space.large)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        _isUploading
                            ? const Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Uploading your image...'),
                              ],
                            )
                            : Column(
                              children: [
                                CircularButton(
                                  onPressed: () async {
                                    bool isFormValid =
                                        _isNameValid &&
                                        _isYearValid &&
                                        _isDepartmentValid &&
                                        _isSectionValid &&
                                        _isPasswordValid &&
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
                                            );

                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'تم حفظ التغييرات بنجاح',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to save changes: $e',
                                              ),
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'يرجى ملء البيانات بشكل صحيح',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icons.save,
                                ),
                                const SizedBox(height: 8),
                                const Text('حفظ'),
                              ],
                            ),
                      ],
                    ),
                    Column(
                      children: [
                        CircularButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icons.cancel,
                          backgroundColor: Colors.red,
                        ),
                        const SizedBox(height: 8),
                        const Text('إلغاء'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
