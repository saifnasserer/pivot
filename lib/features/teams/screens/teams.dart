import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/features/teams/providers/teams_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/features/teams/screens/team_formation_screen.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/team_member.dart';
import 'package:gradient_borders/gradient_borders.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  final List<String> years = FormOptions.academicYears;
  UserProfile? currentUserProfile;
  String? selectedYearFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    try {
      final profile = ref.read(userProfileProvider).userProfile;
      setState(() {
        currentUserProfile = profile;
      });
    } catch (e) {
      //debugprint('Error loading user profile: $e');
    }
  }

  bool _isAdmin() {
    final role = currentUserProfile?.role ?? '';
    return role == 'Admin' || role == 'Super Admin';
  }

  List<TeamMember> _filterTeams(List<TeamMember> teams) {
    if (currentUserProfile == null) return [];

    if (_isAdmin()) {
      return selectedYearFilter != null
          ? teams.where((team) => team.year == selectedYearFilter).toList()
          : teams;
    } else {
      final userYear = currentUserProfile?.level ?? '';

      final studentYear = userYear;

      //debugprint('User Level: $userYear');
      //debugprint('Mapped Year: $studentYear');
      //debugprint(
      //   'Available Teams: ${teams.map((t) => "${t.name} - ${t.year}").join(", ")}',
      // );

      final filteredTeams =
          teams.where((team) => team.year == studentYear).toList();

      //debugprint(
      // 'Filtered Teams: ${filteredTeams.map((t) => "${t.name} - ${t.year}").join(", ")}',
      // );

      return filteredTeams;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'تكوين فريق',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.text(context, size: TextSize.heading),
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_isAdmin()) ...[
            DropdownButtonHideUnderline(
              child: Container(
                margin: EdgeInsets.only(
                  right: Responsive.space(context, size: Space.small),
                ),
                child: DropdownButton<String>(
                  value: null, // Always null to prevent text display
                  hint: Container(), // Empty container to show only icon
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'الكل',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...years.map(
                      (year) => DropdownMenuItem<String>(
                        value: year,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            year,
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  onChanged:
                      (value) => setState(() => selectedYearFilter = value),
                  icon: Icon(
                    Icons.filter_list_outlined,
                    size: Responsive.space(context, size: Space.medium),
                    color:
                        selectedYearFilter != null
                            ? Colors.blue[600]!
                            : Colors.grey[600],
                  ),
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: Responsive.text(context, size: TextSize.small),
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                right: Responsive.space(context, size: Space.small),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: Colors.black87,
                  size: Responsive.text(context, size: TextSize.medium),
                ),
                tooltip: 'تعديل التيمات',
                onPressed: _showEditTeamsDialog,
              ),
            ),
          ],
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final teamsState = ref.watch(teamsProvider);

          if (teamsState.isLoading || currentUserProfile == null) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
          }

          if (teamsState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    teamsState.error!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final filteredTeams = _filterTeams(teamsState.teamMembers);

          if (filteredTeams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    _isAdmin()
                        ? 'لا توجد فرق${selectedYearFilter != null ? ' في السنة $selectedYearFilter' : ''}'
                        : 'لا توجد فرق متاحة لسنتك الدراسية',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.small),
              vertical: Responsive.space(context, size: Space.small),
            ),
            itemCount: filteredTeams.length,
            itemBuilder: (context, index) {
              final team = filteredTeams[index];
              return Container(
                margin: EdgeInsets.only(
                  bottom: Responsive.space(context, size: Space.large),
                ),
                decoration: BoxDecoration(
                  gradient: null,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border:
                      team.isPinned
                          ? GradientBoxBorder(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                            ),
                            width: 2,
                          )
                          : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => TeamFormationScreen(
                                teamName: team.name,
                                teamYear: team.year,
                              ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(
                        Responsive.space(context, size: Space.medium),
                      ),
                      child: Row(
                        children: [
                          if (_isAdmin()) ...[
                            IconButton(
                              icon: Icon(
                                team.isPinned
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                size: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                                color:
                                    team.isPinned
                                        ? Color(0xFF4158D0)
                                        : Colors.grey[400],
                              ),
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(teamsProvider.notifier)
                                      .toggleTeamPin(team.id, !team.isPinned);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                          Icon(
                            Icons.arrow_back_ios,
                            size: Responsive.space(context, size: Space.medium),
                            color: Colors.grey[400],
                          ),
                          Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                team.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              Text(
                                team.year ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.large),
                              ),
                            ),
                            child: Icon(
                              Icons.group_outlined,
                              color:
                                  team.isPinned
                                      ? Color(0xFF4158D0)
                                      : Colors.black87,
                              size: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton:
          _isAdmin()
              ? FloatingActionButton(
                heroTag: 'teams_fab',
                onPressed: () {
                  final TextEditingController controller =
                      TextEditingController();
                  String? selectedYear;

                  showDialog(
                    context: context,
                    builder:
                        (context) => StatefulBuilder(
                          builder: (context, setState) {
                            return UnifiedDialog(
                              title: 'إضافة فريق جديد',
                              subtitle: 'أدخل معلومات الفريق',
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: 'اسم الفريق',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(
                                            Responsive.space(
                                              context,
                                              size: Space.large,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      hintText: 'اختر الفرقة',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          Responsive.space(
                                            context,
                                            size: Space.large,
                                          ),
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: Responsive.space(
                                          context,
                                          size: Space.large,
                                        ),
                                        vertical: Responsive.space(
                                          context,
                                          size: Space.large,
                                        ),
                                      ),
                                    ),
                                    initialValue: selectedYear,
                                    items:
                                        years
                                            .map(
                                              (y) => DropdownMenuItem(
                                                value: y,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(y),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged:
                                        (v) => setState(() => selectedYear = v),
                                    isExpanded: true,
                                    alignment: Alignment.centerRight,
                                    borderRadius: BorderRadius.circular(
                                      Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('إلغاء'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    final name = controller.text.trim();
                                    if (name.isNotEmpty &&
                                        selectedYear != null) {
                                      try {
                                        await ref
                                            .read(teamsProvider.notifier)
                                            .addTeamMember(
                                              TeamMember(
                                                id: '',
                                                name: name,
                                                skills: [],
                                                previousProjects: [],
                                                purpose: '',
                                                whatsappNumber: '',
                                                userId: '',
                                                createdAt: DateTime.now(),
                                                teamName: name,
                                                year: selectedYear,
                                              ),
                                            );
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('إضافة'),
                                ),
                              ],
                            );
                          },
                        ),
                  );
                },
                backgroundColor: Colors.black,
                elevation: 2,
                child: Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  void _showEditTeamsDialog() async {
    final TextEditingController controller = TextEditingController();
    String? selectedYear;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                    ),
                    title: const Text(
                      'تعديل التيمات',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final teamsState = ref.watch(teamsProvider);
                            return Column(
                              children:
                                  teamsState.teamMembers
                                      .map(
                                        (team) => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${team.name} - ${team.year}',
                                                textAlign: TextAlign.right,
                                                textDirection:
                                                    TextDirection.rtl,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () async {
                                                await ref
                                                    .read(
                                                      teamsProvider.notifier,
                                                    )
                                                    .deleteTeamMember(team.id);
                                              },
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                            );
                          },
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.large),
                        ),
                        TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'أضف تيم',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(
                                  Responsive.space(context, size: Space.large),
                                ),
                              ),
                            ),
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: 'اختر الفرقة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.large),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                              vertical: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                          ),
                          initialValue: selectedYear,
                          items:
                              years
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(y),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => selectedYear = v),
                          isExpanded: true,
                          alignment: Alignment.centerRight,
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () async {
                          final v = controller.text.trim();
                          if (v.isNotEmpty && selectedYear != null) {
                            try {
                              await ref
                                  .read(teamsProvider.notifier)
                                  .addTeamMember(
                                    TeamMember(
                                      id: '',
                                      name: v,
                                      skills: [],
                                      previousProjects: [],
                                      purpose: '',
                                      whatsappNumber: '',
                                      userId: '',
                                      createdAt: DateTime.now(),
                                      teamName: v,
                                      year: selectedYear,
                                    ),
                                  );
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: const Text('إضافة'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إغلاق'),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
