import 'package:pivot/features/teams/services/teams_service.dart';
import 'package:pivot/models/team_member.dart';

class TeamsRepository {
  final TeamsService _teamsService;

  TeamsRepository(this._teamsService);

  // Get all team members
  Future<List<TeamMember>> getAllTeamMembers() async {
    return await _teamsService.getAllTeamMembers();
  }

  // Get team members by team name
  Future<List<TeamMember>> getTeamMembersByTeamName(String teamName) async {
    return await _teamsService.getTeamMembersByTeamName(teamName);
  }

  // Get team member by ID
  Future<TeamMember?> getTeamMemberById(String id) async {
    return await _teamsService.getTeamMemberById(id);
  }

  // Get team member by user ID
  Future<TeamMember?> getTeamMemberByUserId(String userId) async {
    return await _teamsService.getTeamMemberByUserId(userId);
  }

  // Add team member
  Future<bool> addTeamMember(TeamMember member) async {
    return await _teamsService.addTeamMember(member);
  }

  // Update team member
  Future<bool> updateTeamMember(TeamMember member) async {
    return await _teamsService.updateTeamMember(member);
  }

  // Delete team member
  Future<bool> deleteTeamMember(String id) async {
    return await _teamsService.deleteTeamMember(id);
  }

  // Search team members
  Future<List<TeamMember>> searchTeamMembers(String query) async {
    return await _teamsService.searchTeamMembers(query);
  }

  // Get team members by skills
  Future<List<TeamMember>> getTeamMembersBySkills(List<String> skills) async {
    return await _teamsService.getTeamMembersBySkills(skills);
  }

  // Get team statistics
  Future<Map<String, dynamic>> getTeamStatistics() async {
    return await _teamsService.getTeamStatistics();
  }

  // Get available team names
  Future<List<String>> getAvailableTeamNames() async {
    return await _teamsService.getAvailableTeamNames();
  }

  // Get available skills
  Future<List<String>> getAvailableSkills() async {
    return await _teamsService.getAvailableSkills();
  }

  // Check if user is already a team member
  Future<bool> isUserTeamMember(String userId) async {
    return await _teamsService.isUserTeamMember(userId);
  }

  // Get team members count by team
  Future<Map<String, int>> getTeamMemberCounts() async {
    return await _teamsService.getTeamMemberCounts();
  }
}
