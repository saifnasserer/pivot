import 'package:flutter/material.dart';
import 'package:pivot/models/team_member.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:pivot/responsive.dart';
import 'package:uuid/uuid.dart';

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
        (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
            title: Text(
              'ضيف نفسك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.text(context, size: TextSize.heading),
              ),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Team Name Dropdown
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: 'اختر اسم الفريق',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                            borderSide: BorderSide(color: Color(0xFFF7F7F7)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: newTeamName.isEmpty ? null : newTeamName,
                        items:
                            purposes
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p['name'],
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        p['name']!,
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            preselectedTeamName != null
                                ? null
                                : (v) => newTeamName = v ?? '',
                        validator:
                            (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                        isExpanded: true,
                        alignment: Alignment.centerRight,
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    // Skills
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: skillController,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: 'أضف مهارة',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFFF7F7F7),
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onFieldSubmitted: (v) {
                                if (v.trim().isNotEmpty &&
                                    !newSkills.contains(v.trim())) {
                                  newSkills.add(v.trim());
                                  skillController.clear();
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              final v = skillController.text;
                              if (v.trim().isNotEmpty &&
                                  !newSkills.contains(v.trim())) {
                                newSkills.add(v.trim());
                                skillController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children:
                          newSkills
                              .map(
                                (skill) => Chip(
                                  label: Text(skill),
                                  onDeleted: () => newSkills.remove(skill),
                                ),
                              )
                              .toList(),
                    ),
                    // Previous Projects
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: projectLinkController,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: 'رابط مشروع سابق',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFFF7F7F7),
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onFieldSubmitted: (v) {
                                if (Uri.tryParse(v)?.hasAbsolutePath == true &&
                                    !newPreviousProjects.contains(v)) {
                                  newPreviousProjects.add(v);
                                  projectLinkController.clear();
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              final v = projectLinkController.text;
                              if (Uri.tryParse(v)?.hasAbsolutePath == true &&
                                  !newPreviousProjects.contains(v)) {
                                newPreviousProjects.add(v);
                                projectLinkController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children:
                          newPreviousProjects
                              .map(
                                (link) => Chip(
                                  label: Text(
                                    link,
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ),
                                    ),
                                  ),
                                  onDeleted:
                                      () => newPreviousProjects.remove(link),
                                ),
                              )
                              .toList(),
                    ),
                    // Purpose Dropdown
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: 'بتدور علي تيم ايه؟',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                            borderSide: BorderSide(color: Color(0xFFF7F7F7)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: newPurpose.isEmpty ? null : newPurpose,
                        items:
                            purposes
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p['name'],
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        p['name']!,
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => newPurpose = v ?? '',
                        validator:
                            (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                        isExpanded: true,
                        alignment: Alignment.centerRight,
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.space(context)),
                    // WhatsApp
                    CustomTextField(
                      hint: 'رقم واتساب',
                      suffixIcon: Icon(Icons.phone),
                      onChanged: (v) => newWhatsapp = v,
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: Responsive.space(context)),
                    // LinkedIn (optional)
                    CustomTextField(
                      hint: 'رابط لينكدإن (اختياري)',
                      onChanged: (v) => newLinkedin = v,
                      validator:
                          (v) =>
                              v != null && v.isNotEmpty && !v.startsWith('http')
                                  ? 'رابط غير صحيح'
                                  : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final user = currentUserProfile;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يجب تسجيل الدخول أولاً'),
                            backgroundColor: Colors.black,
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
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    'إضافة',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
  );
}
