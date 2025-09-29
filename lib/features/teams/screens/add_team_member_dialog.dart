import 'package:flutter/material.dart';
import 'package:pivot/models/team_member.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:uuid/uuid.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';


Future<void> showAddTeamMemberDialog(
  BuildContext context, {
  String? preselectedTeamName,
  required List<Map<String, String>> purposes,
  required Function(TeamMember) onAdd,
  required UserProfile? currentUserProfile,
}) async {
  final formKey = GlobalKey<FormState>();
  List<String> newSkills = [];
  final TextEditingController skillController = TextEditingController();
  List<String> newPreviousProjects = [];
  final TextEditingController projectLinkController = TextEditingController();
  String newPurpose = '';
  String newWhatsapp = '';
  String? newLinkedin;
  String newTeamName = preselectedTeamName ?? '';

  await showDialog(
    context: context,
    builder:
        (context) => StatefulBuilder(
          builder: (context, setState) {
            return UnifiedDialog(
              title: 'ضيف نفسك',
              subtitle: 'أدخل بياناتك للانضمام للفريق',
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Team Name Dropdown
                      UnifiedDropdownField<String>(
                        hint: 'اختر اسم الفريق',
                        value: newTeamName.isEmpty ? null : newTeamName,
                        items: purposes.map((p) => p['name']!).toList(),
                        itemToString: (item) => item,
                        onChanged:
                            preselectedTeamName != null
                                ? null
                                : (v) {
                                  setState(() {
                                    newTeamName = v ?? '';
                                  });
                                },
                        validator:
                            (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Skills Section
                      UnifiedSectionHeader(
                        title: 'المهارات',
                        icon: Icons.psychology,
                      ),

                      // Skills Input
                      Row(
                        children: [
                          Expanded(
                            child: UnifiedFormField(
                              hint: 'أضف مهارة',
                              controller: skillController,
                              onChanged: (v) {},
                              onFieldSubmitted: (v) {
                                if (v.trim().isNotEmpty &&
                                    !newSkills.contains(v.trim())) {
                                  setState(() {
                                    newSkills.add(v.trim());
                                    skillController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.black),
                            onPressed: () {
                              final v = skillController.text;
                              if (v.trim().isNotEmpty &&
                                  !newSkills.contains(v.trim())) {
                                setState(() {
                                  newSkills.add(v.trim());
                                  skillController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),

                      // Skills Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children:
                            newSkills
                                .map(
                                  (skill) => UnifiedChip(
                                    label: skill,
                                    onDelete: () {
                                      setState(() {
                                        newSkills.remove(skill);
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Previous Projects Section
                      UnifiedSectionHeader(
                        title: 'المشاريع السابقة',
                        icon: Icons.work,
                      ),

                      // Projects Input
                      Row(
                        children: [
                          Expanded(
                            child: UnifiedFormField(
                              hint: 'رابط مشروع سابق',
                              controller: projectLinkController,
                              onChanged: (v) {},
                              onFieldSubmitted: (v) {
                                if (Uri.tryParse(v)?.hasAbsolutePath == true &&
                                    !newPreviousProjects.contains(v)) {
                                  setState(() {
                                    newPreviousProjects.add(v);
                                    projectLinkController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.black),
                            onPressed: () {
                              final v = projectLinkController.text;
                              if (Uri.tryParse(v)?.hasAbsolutePath == true &&
                                  !newPreviousProjects.contains(v)) {
                                setState(() {
                                  newPreviousProjects.add(v);
                                  projectLinkController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),

                      // Projects Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children:
                            newPreviousProjects
                                .map(
                                  (link) => UnifiedChip(
                                    label: link,
                                    onDelete: () {
                                      setState(() {
                                        newPreviousProjects.remove(link);
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Purpose Dropdown
                      UnifiedDropdownField<String>(
                        hint: 'بتدور علي تيم ايه؟',
                        value: newPurpose.isEmpty ? null : newPurpose,
                        items: purposes.map((p) => p['name']!).toList(),
                        itemToString: (item) => item,
                        onChanged: (v) {
                          setState(() {
                            newPurpose = v ?? '';
                          });
                        },
                        validator:
                            (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // WhatsApp
                      UnifiedFormField(
                        hint: 'رقم واتساب',
                        suffixIcon: Icon(Icons.phone, color: Colors.black),
                        onChanged: (v) => newWhatsapp = v,
                        validator:
                            (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // LinkedIn (optional)
                      UnifiedFormField(
                        hint: 'رابط لينكدإن (اختياري)',
                        onChanged: (v) => newLinkedin = v,
                        validator:
                            (v) =>
                                v != null &&
                                        v.isNotEmpty &&
                                        !v.startsWith('http')
                                    ? 'رابط غير صحيح'
                                    : null,
                      ),
                    ],
                  ),
                ),
              ),
              confirmText: 'إضافة',
              confirmIcon: Icons.person_add,
              onConfirm: () async {
                if (formKey.currentState!.validate()) {
                  final user = currentUserProfile;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('يجب تسجيل الدخول أولاً'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  try {
                    final member = TeamMember(
                      id: const Uuid().v4(),
                      name: user.name,
                      skills: newSkills,
                      previousProjects: newPreviousProjects,
                      purpose: newPurpose,
                      whatsappNumber: newWhatsapp,
                      linkedinProfile: newLinkedin,
                      userId: user.id,
                      createdAt: DateTime.now(),
                      teamName: newTeamName,
                    );
                    await onAdd(member);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('حدث خطأ: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
            );
          },
        ),
  );
}
