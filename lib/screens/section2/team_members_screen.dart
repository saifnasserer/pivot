import 'package:flutter/material.dart';
import 'package:pivot/providers/team_provider.dart';
import 'package:pivot/screens/models/team_find_card.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/screens/section2/add_team_member_dialog.dart';
import 'package:pivot/providers/user_profile_provider.dart';

class TeamMembersScreen extends StatelessWidget {
  final String teamName;
  const TeamMembersScreen({super.key, required this.teamName});

  void _showAddDialog(BuildContext context) async {
    final purposes =
        Provider.of<TeamProvider>(context, listen: false).teamMembers
            .map((m) => {'name': m.teamName, 'year': ''})
            .toSet()
            .toList();
    // If you have a global purposes list, use that instead
    final userProfile =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;
    await showAddTeamMemberDialog(
      context,
      preselectedTeamName: teamName,
      purposes: purposes,
      onAdd: (member) async {
        await Provider.of<TeamProvider>(
          context,
          listen: false,
        ).addTeamMember(member);
      },
      currentUserProfile: userProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('أعضاء فريق $teamName'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: Consumer<TeamProvider>(
        builder: (context, provider, child) {
          final user = FirebaseAuth.instance.currentUser;
          final isMember = provider.teamMembers.any(
            (m) => m.teamName == teamName && m.userId == user?.uid,
          );
          if (isMember) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
            elevation: 0,
            onPressed: () => _showAddDialog(context),
            backgroundColor: Colors.black,
            icon: null,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ضيف نفسك'),
                SizedBox(width: 8),
                const Icon(Icons.person_add),
              ],
            ),
          );
        },
      ),
      body: Consumer<TeamProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Text(provider.error!, style: TextStyle(color: Colors.red)),
            );
          }
          final user = FirebaseAuth.instance.currentUser;
          final members =
              provider.teamMembers
                  .where((m) => m.teamName == teamName)
                  .toList();
          if (members.isEmpty) {
            return Center(child: Text('لا يوجد أعضاء في هذا الفريق'));
          }
          return ListView.builder(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final m = members[index];
              final isCurrentUser = user != null && m.userId == user.uid;
              return TeamFindCard(
                name: m.name,
                skills: m.skills,
                previousProjects:
                    m.previousProjects
                        .map((p) => {'title': p, 'url': p})
                        .toList(),
                whatsappNumber: m.whatsappNumber,
                linkedinProfile: m.linkedinProfile,
                profilePicUrl: null, // Optionally add logic for profilePicUrl
                showDelete: isCurrentUser,
                onDelete:
                    isCurrentUser
                        ? () async {
                          await Provider.of<TeamProvider>(
                            context,
                            listen: false,
                          ).deleteTeamMember(m.id);
                        }
                        : null,
              );
            },
          );
        },
      ),
    );
  }
}