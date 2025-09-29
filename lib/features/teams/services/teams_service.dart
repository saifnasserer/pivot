import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/models/team_member.dart';

class TeamsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all team members
  Future<List<TeamMember>> getAllTeamMembers() async {
    try {
      final snapshot =
          await _firestore
              .collection('team_members')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) => TeamMember.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch team members: $e');
    }
  }

  // Get team members by team name
  Future<List<TeamMember>> getTeamMembersByTeamName(String teamName) async {
    try {
      final snapshot =
          await _firestore
              .collection('team_members')
              .where('teamName', isEqualTo: teamName)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) => TeamMember.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch team members by team name: $e');
    }
  }

  // Get team member by ID
  Future<TeamMember?> getTeamMemberById(String id) async {
    try {
      final doc = await _firestore.collection('team_members').doc(id).get();
      if (doc.exists) {
        return TeamMember.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch team member by ID: $e');
    }
  }

  // Get team member by user ID
  Future<TeamMember?> getTeamMemberByUserId(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('team_members')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return TeamMember.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch team member by user ID: $e');
    }
  }

  // Add team member
  Future<bool> addTeamMember(TeamMember member) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('team_members')
          .doc(member.id)
          .set(member.toJson());
      return true;
    } catch (e) {
      throw Exception('Failed to add team member: $e');
    }
  }

  // Update team member
  Future<bool> updateTeamMember(TeamMember member) async {
    try {
      await _firestore
          .collection('team_members')
          .doc(member.id)
          .update(member.toJson());
      return true;
    } catch (e) {
      throw Exception('Failed to update team member: $e');
    }
  }

  // Delete team member
  Future<bool> deleteTeamMember(String id) async {
    try {
      await _firestore.collection('team_members').doc(id).delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete team member: $e');
    }
  }

  // Search team members
  Future<List<TeamMember>> searchTeamMembers(String query) async {
    try {
      final allMembers = await getAllTeamMembers();
      final lowercaseQuery = query.toLowerCase();

      return allMembers.where((member) {
        return member.name.toLowerCase().contains(lowercaseQuery) ||
            member.skills.any(
              (skill) => skill.toLowerCase().contains(lowercaseQuery),
            ) ||
            member.purpose.toLowerCase().contains(lowercaseQuery) ||
            member.teamName.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search team members: $e');
    }
  }

  // Get team members by skills
  Future<List<TeamMember>> getTeamMembersBySkills(List<String> skills) async {
    try {
      final allMembers = await getAllTeamMembers();

      return allMembers.where((member) {
        return skills.any(
          (skill) => member.skills.any(
            (memberSkill) =>
                memberSkill.toLowerCase().contains(skill.toLowerCase()),
          ),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch team members by skills: $e');
    }
  }

  // Get team statistics
  Future<Map<String, dynamic>> getTeamStatistics() async {
    try {
      final allMembers = await getAllTeamMembers();

      int totalMembers = allMembers.length;
      Map<String, int> teamCounts = {};
      Map<String, int> skillCounts = {};
      List<String> allSkills = [];

      for (var member in allMembers) {
        // Count by team
        teamCounts[member.teamName] = (teamCounts[member.teamName] ?? 0) + 1;

        // Count skills
        for (var skill in member.skills) {
          skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
          allSkills.add(skill);
        }
      }

      // Get unique skills
      final uniqueSkills = allSkills.toSet().toList();

      // Get top skills
      final topSkills =
          skillCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'totalMembers': totalMembers,
        'teamCounts': teamCounts,
        'skillCounts': skillCounts,
        'uniqueSkills': uniqueSkills,
        'topSkills':
            topSkills
                .take(10)
                .map((e) => {'skill': e.key, 'count': e.value})
                .toList(),
        'averageSkillsPerMember':
            totalMembers > 0 ? (allSkills.length / totalMembers).round() : 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch team statistics: $e');
    }
  }

  // Get available team names
  Future<List<String>> getAvailableTeamNames() async {
    try {
      final allMembers = await getAllTeamMembers();
      final teamNames =
          allMembers.map((member) => member.teamName).toSet().toList();
      teamNames.sort();
      return teamNames;
    } catch (e) {
      throw Exception('Failed to fetch available team names: $e');
    }
  }

  // Get available skills
  Future<List<String>> getAvailableSkills() async {
    try {
      final allMembers = await getAllTeamMembers();
      final skills = <String>{};

      for (var member in allMembers) {
        skills.addAll(member.skills);
      }

      final skillsList = skills.toList();
      skillsList.sort();
      return skillsList;
    } catch (e) {
      throw Exception('Failed to fetch available skills: $e');
    }
  }

  // Check if user is already a team member
  Future<bool> isUserTeamMember(String userId) async {
    try {
      final member = await getTeamMemberByUserId(userId);
      return member != null;
    } catch (e) {
      return false;
    }
  }

  // Get team members count by team
  Future<Map<String, int>> getTeamMemberCounts() async {
    try {
      final allMembers = await getAllTeamMembers();
      Map<String, int> counts = {};

      for (var member in allMembers) {
        counts[member.teamName] = (counts[member.teamName] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to fetch team member counts: $e');
    }
  }
}
