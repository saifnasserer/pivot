import 'package:flutter/material.dart';
import 'package:pivot/data/form_options.dart';
import 'package:pivot/providers/teams_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/screens/section2/team_formation_screen.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:provider/provider.dart';
import 'package:gradient_borders/gradient_borders.dart';

class TeamsScreen extends StatefulWidget {
  // = 'teams';

  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final List<String> years = FormOptions.academicYears;
  UserProfile? currentUserProfile;
  String? selectedYearFilter;
  late UserProfileProvider _userProfileProvider;

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
      final profile = _userProfileProvider.userProfile;
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

  List<Team> _filterTeams(List<Team> teams) {
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'تكوين فريق',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[50],
        elevation: 0,
        actions: [
          if (_isAdmin()) ...[
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedYearFilter,
                items: [
                  ...years.map(
                    (year) => DropdownMenuItem<String>(
                      value: year,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(year),
                      ),
                    ),
                  ),
                ],
                onChanged:
                    (value) => setState(() => selectedYearFilter = value),
                icon: Icon(
                  Icons.filter_list_outlined,
                  size: Responsive.space(context, size: Space.medium),
                ),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.black87),
              tooltip: 'تعديل التيمات',
              onPressed: _showEditTeamsDialog,
            ),
          ],
        ],
      ),
      body: Consumer<TeamsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || currentUserProfile == null) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
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

          final filteredTeams = _filterTeams(provider.teams);

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
                                  await context
                                      .read<TeamsProvider>()
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
                                team.year,
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
                                    value: selectedYear,
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
                                        await context
                                            .read<TeamsProvider>()
                                            .addTeam(name, selectedYear!);
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
                        Consumer<TeamsProvider>(
                          builder: (context, provider, child) {
                            return Column(
                              children:
                                  provider.teams
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
                                                await provider.deleteTeam(
                                                  team.id,
                                                );
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
                          value: selectedYear,
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
                              await context.read<TeamsProvider>().addTeam(
                                v,
                                selectedYear!,
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
