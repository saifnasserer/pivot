import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/teams/providers/teams_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/screens/models/team_find_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/features/teams/screens/add_team_member_dialog.dart';
import 'package:pivot/responsive.dart';

class TeamMembersScreen extends ConsumerWidget {
  final String teamName;
  const TeamMembersScreen({super.key, required this.teamName});

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final teamsState = ref.read(teamsProvider);
    final purposes =
        teamsState.teamMembers
            .map((m) => {'name': m.teamName, 'year': ''})
            .toSet()
            .toList();
    // If you have a global purposes list, use that instead
    final userProfile = ref.read(userProfileProvider).userProfile;
    await showAddTeamMemberDialog(
      context,
      preselectedTeamName: teamName,
      purposes: purposes,
      onAdd: (member) async {
        await ref.read(teamsProvider.notifier).addTeamMember(member);
      },
      currentUserProfile: userProfile,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('أعضاء فريق $teamName'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final teamsState = ref.watch(teamsProvider);
          final user = FirebaseAuth.instance.currentUser;
          final isMember = teamsState.teamMembers.any(
            (m) => m.teamName == teamName && m.userId == user?.uid,
          );
          if (isMember) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            heroTag: 'team_members_fab',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
            elevation: 0,
            onPressed: () => _showAddDialog(context, ref),
            backgroundColor: Colors.black,
            icon: null,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ضيف نفسك'),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                const Icon(Icons.person_add),
              ],
            ),
          );
        },
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final teamsState = ref.watch(teamsProvider);

          if (teamsState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (teamsState.error != null) {
            return Center(
              child: Text(
                teamsState.error!,
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          final user = FirebaseAuth.instance.currentUser;
          final members =
              teamsState.teamMembers
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
                          await ref
                              .read(teamsProvider.notifier)
                              .deleteTeamMember(m.id);
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
