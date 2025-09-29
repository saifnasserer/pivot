import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/teams/services/teams_service.dart';
import 'package:pivot/features/teams/repositories/teams_repository.dart';
import 'package:pivot/models/team_member.dart';

// Services
final teamsServiceProvider = Provider<TeamsService>((ref) {
  return TeamsService();
});

// Repositories
final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  final service = ref.watch(teamsServiceProvider);
  return TeamsRepository(service);
});

// State classes
class TeamsState {
  final bool isLoading;
  final String? error;
  final List<TeamMember> teamMembers;
  final List<TeamMember> filteredTeamMembers;
  final Map<String, dynamic>? statistics;
  final String searchQuery;
  final String? selectedTeamName;
  final List<String> selectedSkills;
  final List<String> availableTeamNames;
  final List<String> availableSkills;

  const TeamsState({
    this.isLoading = false,
    this.error,
    this.teamMembers = const [],
    this.filteredTeamMembers = const [],
    this.statistics,
    this.searchQuery = '',
    this.selectedTeamName,
    this.selectedSkills = const [],
    this.availableTeamNames = const [],
    this.availableSkills = const [],
  });

  TeamsState copyWith({
    bool? isLoading,
    String? error,
    List<TeamMember>? teamMembers,
    List<TeamMember>? filteredTeamMembers,
    Map<String, dynamic>? statistics,
    String? searchQuery,
    String? selectedTeamName,
    List<String>? selectedSkills,
    List<String>? availableTeamNames,
    List<String>? availableSkills,
  }) {
    return TeamsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      teamMembers: teamMembers ?? this.teamMembers,
      filteredTeamMembers: filteredTeamMembers ?? this.filteredTeamMembers,
      statistics: statistics ?? this.statistics,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTeamName: selectedTeamName ?? this.selectedTeamName,
      selectedSkills: selectedSkills ?? this.selectedSkills,
      availableTeamNames: availableTeamNames ?? this.availableTeamNames,
      availableSkills: availableSkills ?? this.availableSkills,
    );
  }
}

// Notifier
class TeamsNotifier extends StateNotifier<TeamsState> {
  final TeamsRepository _repository;

  TeamsNotifier(this._repository) : super(const TeamsState());

  // Get all team members
  Future<void> getAllTeamMembers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final teamMembers = await _repository.getAllTeamMembers();
      state = state.copyWith(
        isLoading: false,
        teamMembers: teamMembers,
        filteredTeamMembers: teamMembers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get team members by team name
  Future<void> getTeamMembersByTeamName(String teamName) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedTeamName: teamName,
    );
    try {
      final teamMembers = await _repository.getTeamMembersByTeamName(teamName);
      state = state.copyWith(
        isLoading: false,
        teamMembers: teamMembers,
        filteredTeamMembers: teamMembers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get team member by ID
  Future<TeamMember?> getTeamMemberById(String id) async {
    try {
      return await _repository.getTeamMemberById(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Get team member by user ID
  Future<TeamMember?> getTeamMemberByUserId(String userId) async {
    try {
      return await _repository.getTeamMemberByUserId(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Add team member
  Future<bool> addTeamMember(TeamMember member) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.addTeamMember(member);
      if (success) {
        await getAllTeamMembers(); // Refresh the list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update team member
  Future<bool> updateTeamMember(TeamMember member) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.updateTeamMember(member);
      if (success) {
        await getAllTeamMembers(); // Refresh the list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Delete team member
  Future<bool> deleteTeamMember(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.deleteTeamMember(id);
      if (success) {
        await getAllTeamMembers(); // Refresh the list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Search team members
  Future<void> searchTeamMembers(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final teamMembers = await _repository.searchTeamMembers(query);
      state = state.copyWith(
        isLoading: false,
        teamMembers: teamMembers,
        filteredTeamMembers: teamMembers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get team members by skills
  Future<void> getTeamMembersBySkills(List<String> skills) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedSkills: skills,
    );
    try {
      final teamMembers = await _repository.getTeamMembersBySkills(skills);
      state = state.copyWith(
        isLoading: false,
        teamMembers: teamMembers,
        filteredTeamMembers: teamMembers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get team statistics
  Future<void> getTeamStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statistics = await _repository.getTeamStatistics();
      state = state.copyWith(isLoading: false, statistics: statistics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get available team names
  Future<void> getAvailableTeamNames() async {
    try {
      final teamNames = await _repository.getAvailableTeamNames();
      state = state.copyWith(availableTeamNames: teamNames);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Get available skills
  Future<void> getAvailableSkills() async {
    try {
      final skills = await _repository.getAvailableSkills();
      state = state.copyWith(availableSkills: skills);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Check if user is already a team member
  Future<bool> isUserTeamMember(String userId) async {
    try {
      return await _repository.isUserTeamMember(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Get team members count by team
  Future<Map<String, int>> getTeamMemberCounts() async {
    try {
      return await _repository.getTeamMemberCounts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return {};
    }
  }

  // Filter team members locally
  void filterTeamMembers({
    String? query,
    String? teamName,
    List<String>? skills,
  }) {
    List<TeamMember> filtered = state.teamMembers;

    // Filter by search query
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      filtered =
          filtered.where((member) {
            return member.name.toLowerCase().contains(lowercaseQuery) ||
                member.skills.any(
                  (skill) => skill.toLowerCase().contains(lowercaseQuery),
                ) ||
                member.purpose.toLowerCase().contains(lowercaseQuery) ||
                member.teamName.toLowerCase().contains(lowercaseQuery);
          }).toList();
    }

    // Filter by team name
    if (teamName != null && teamName.isNotEmpty) {
      filtered =
          filtered.where((member) => member.teamName == teamName).toList();
    }

    // Filter by skills
    if (skills != null && skills.isNotEmpty) {
      filtered =
          filtered.where((member) {
            return skills.any(
              (skill) => member.skills.any(
                (memberSkill) =>
                    memberSkill.toLowerCase().contains(skill.toLowerCase()),
              ),
            );
          }).toList();
    }

    state = state.copyWith(
      filteredTeamMembers: filtered,
      searchQuery: query ?? state.searchQuery,
      selectedTeamName: teamName ?? state.selectedTeamName,
      selectedSkills: skills ?? state.selectedSkills,
    );
  }

  // Clear filters
  void clearFilters() {
    state = state.copyWith(
      filteredTeamMembers: state.teamMembers,
      searchQuery: '',
      selectedTeamName: null,
      selectedSkills: [],
    );
  }
}

// Providers
final teamsProvider =
    AutoDisposeStateNotifierProvider<TeamsNotifier, TeamsState>((ref) {
      final repository = ref.watch(teamsRepositoryProvider);
      return TeamsNotifier(repository);
    });

// Convenience providers for specific data
final teamMembersProvider = AutoDisposeProvider<List<TeamMember>>((ref) {
  final state = ref.watch(teamsProvider);
  return state.teamMembers;
});

final filteredTeamMembersProvider = AutoDisposeProvider<List<TeamMember>>((
  ref,
) {
  final state = ref.watch(teamsProvider);
  return state.filteredTeamMembers;
});

final teamStatisticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(teamsProvider);
  return state.statistics;
});

final availableTeamNamesProvider = AutoDisposeProvider<List<String>>((ref) {
  final state = ref.watch(teamsProvider);
  return state.availableTeamNames;
});

final availableSkillsProvider = AutoDisposeProvider<List<String>>((ref) {
  final state = ref.watch(teamsProvider);
  return state.availableSkills;
});
