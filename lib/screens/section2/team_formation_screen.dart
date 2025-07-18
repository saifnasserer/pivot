import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/models/team_find_card.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/team_member.dart';
import 'package:pivot/providers/team_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:pivot/screens/models/custom_text_field.dart';
import 'package:pivot/models/user_profile.dart';

class TeamFormationScreen extends StatefulWidget {
  // = 'team_formation';
  final String? teamName;
  final String? teamYear;

  const TeamFormationScreen({super.key, this.teamName, this.teamYear});

  @override
  State<TeamFormationScreen> createState() => _TeamFormationScreenState();
}

class _TeamFormationScreenState extends State<TeamFormationScreen> {
  // For the add dialog
  final _formKey = GlobalKey<FormState>();
  String newName = '';
  List<String> newSkills = [];
  String skillInput = '';
  List<String> newPreviousProjects = [];
  String projectLinkInput = '';
  String newPurpose = '';
  String newWhatsapp = '';
  String? newLinkedin;
  UserProfile? currentUserProfile;
  late UserProfileProvider _userProfileProvider;

  // Add search state
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // For skills and project links, use controllers for input fields
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _projectLinkController = TextEditingController();

  List<Map<String, String>> purposes = [];

  final List<String> years = FormOptions.academicYears;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    _loadUserProfile();
  }

  void _loadUserProfile() {
    try {
      setState(() {
        currentUserProfile = _userProfileProvider.userProfile;
      });
    } catch (e) {
      //debugprint('Error loading user profile: $e');
    }
  }

  @override
  void dispose() {
    _skillController.dispose();
    _projectLinkController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    newName = '';
    newSkills = [];
    skillInput = '';
    _skillController.clear();
    newPreviousProjects = [];
    projectLinkInput = '';
    _projectLinkController.clear();
    newPurpose = '';
    newWhatsapp = '';
    newLinkedin = null;

    showDialog(
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
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                                controller: _skillController,
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
                                    setState(() {
                                      newSkills.add(v.trim());
                                      _skillController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                final v = _skillController.text;
                                if (v.trim().isNotEmpty &&
                                    !newSkills.contains(v.trim())) {
                                  setState(() {
                                    newSkills.add(v.trim());
                                    _skillController.clear();
                                  });
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
                                    onDeleted:
                                        () => setState(
                                          () => newSkills.remove(skill),
                                        ),
                                  ),
                                )
                                .toList(),
                      ),
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
                                controller: _projectLinkController,
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
                                  final formKey = Form.of(context);
                                  if (formKey.validate() &&
                                      !newPreviousProjects.contains(v)) {
                                    setState(() {
                                      newPreviousProjects.add(v);
                                      _projectLinkController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                final v = _projectLinkController.text;
                                if (Uri.tryParse(v)?.hasAbsolutePath == true &&
                                    !newPreviousProjects.contains(v)) {
                                  setState(() {
                                    newPreviousProjects.add(v);
                                    _projectLinkController.clear();
                                  });
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
                                        () => setState(
                                          () =>
                                              newPreviousProjects.remove(link),
                                        ),
                                  ),
                                )
                                .toList(),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      // WhatsApp
                      CustomTextField(
                        hint: 'رقم واتساب',
                        suffixIcon: Icon(Icons.phone),
                        onChanged: (v) => newWhatsapp = v,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'مطلوب';
                          }
                          if (!v.startsWith('0')) {
                            return 'يجب أن يبدأ الرقم بـ 0';
                          }
                          if (v.length != 11) {
                            return 'يجب أن يتكون الرقم من 11 رقم';
                          }
                          if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                            return 'يجب أن يحتوي على أرقام فقط';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      // LinkedIn (optional)
                      CustomTextField(
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
                      if (_formKey.currentState!.validate()) {
                        final provider = context.read<TeamProvider>();
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يجب تسجيل الدخول أولاً'),
                                backgroundColor: Colors.black,
                              ),
                            );
                          }
                          return;
                        }
                        try {
                          final member = TeamMember(
                            id: const Uuid().v4(),
                            name: currentUserProfile?.name ?? '',
                            skills: newSkills,
                            previousProjects: newPreviousProjects,
                            purpose: widget.teamName ?? newPurpose,
                            whatsappNumber: newWhatsapp,
                            linkedinProfile: newLinkedin,
                            userId: user.uid,
                            createdAt: DateTime.now(),
                            teamName: widget.teamName ?? newPurpose,
                          );
                          await provider.addTeamMember(member);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم إضافتك بنجاح'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
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
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final provider = Provider.of<TeamProvider>(context);
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final hasJoinedTeam =
        currentUser != null &&
        provider.teamMembers.any(
          (member) =>
              member.userId == currentUser.uid &&
              member.teamName == widget.teamName,
        );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اسم أو مهارة...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
                : widget.teamName != null
                ? Column(
                  children: [
                    Text(
                      widget.teamName!,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )
                : const Text(
                  'تكوين فريق',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      floatingActionButton:
          !hasJoinedTeam
              ? FloatingActionButton.extended(
                onPressed: _showAddDialog,
                label: Row(
                  children: [
                    Text(
                      'ضيف نفسك',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                      ),
                    ),
                    Icon(Icons.add, color: Colors.white),
                  ],
                ),
                backgroundColor: Colors.black,
              )
              : null,
      body: Consumer<TeamProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    provider.error!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final teamMembers = provider.teamMembers;
          final filteredMembers =
              teamMembers
                  .where(
                    (member) =>
                        member.teamName == widget.teamName &&
                        (_searchQuery.isEmpty ||
                            member.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            member.skills.any(
                              (skill) => skill.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                            )),
                  )
                  .toList();

          if (filteredMembers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animation/nothing.json',
                    width: Responsive.space(context, size: Space.large) * 10,
                    height: Responsive.space(context, size: Space.large) * 10,
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'لا توجد نتائج بحث عن "$_searchQuery" في الأسماء أو المهارات'
                        : 'مفيش ناس حالياً ، ضيف نفسك',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            itemCount: filteredMembers.length,
            itemBuilder: (context, index) {
              final member = filteredMembers[index];
              final currentUser = FirebaseAuth.instance.currentUser;
              final isCurrentUserCard = currentUser?.uid == member.userId;

              return FutureBuilder<UserProfile?>(
                future: userProfileProvider.getUserProfileById(member.userId),
                builder: (context, snapshot) {
                  return TeamFindCard(
                    name: member.name,
                    skills: member.skills,
                    previousProjects:
                        member.previousProjects
                            .map(
                              (url) => {
                                'title': Uri.parse(url).host,
                                'url': url,
                              },
                            )
                            .toList(),
                    whatsappNumber: member.whatsappNumber,
                    linkedinProfile: member.linkedinProfile,
                    profilePicUrl: snapshot.data?.profileImageUrl,
                    department: snapshot.data?.department ?? '',
                    showDelete: isCurrentUserCard,
                    onDelete:
                        isCurrentUserCard
                            ? () async {
                              // Show confirmation dialog
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text(
                                        'متأكد؟',
                                        textAlign: TextAlign.center,
                                      ),
                                      actions: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: Text('إلغاء'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: Responsive.space(
                                                    context,
                                                    size: Space.medium,
                                                  ),
                                                  vertical: Responsive.space(
                                                    context,
                                                    size: Space.small,
                                                  ),
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Responsive.space(
                                                          context,
                                                          size: Space.large,
                                                        ),
                                                      ),
                                                ),
                                                child: Text(
                                                  'حذف',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                              );

                              if (shouldDelete == true) {
                                try {
                                  await provider.deleteTeamMember(member.id);
                                  if (context.mounted) {
                                    // Check if context is still valid
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم الحذف'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    // Check if context is still valid
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'حدث خطأ أثناء الحذف: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                            : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
