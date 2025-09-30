import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/administration/repositories/administration_repository.dart';
import 'package:pivot/features/administration/services/administration_service.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/section_model.dart';

final administrationServiceProvider = Provider<AdministrationService>(
  (ref) => AdministrationService(),
);

final administrationRepositoryProvider = Provider<AdministrationRepository>((
  ref,
) {
  final service = ref.watch(administrationServiceProvider);
  return AdministrationRepository(service);
});

class AdministrationState {
  final List<UserProfile> users;
  final List<UserProfile> filteredUsers;
  final List<Subject> subjects;
  final List<Subject> filteredSubjects;
  final List<Section> sections;
  final List<Section> filteredSections;
  final Map<String, dynamic> storageStats;
  final String searchQuery;
  final String selectedRoleFilter;
  final Set<String> selectedUsers;
  final Set<String> selectedSubjects;
  final bool isLoading;
  final bool isSearching;
  final bool isDeleting;
  final bool isOptimizing;
  final String? error;
  final bool showSearchBar;

  const AdministrationState({
    this.users = const [],
    this.filteredUsers = const [],
    this.subjects = const [],
    this.filteredSubjects = const [],
    this.sections = const [],
    this.filteredSections = const [],
    this.storageStats = const {},
    this.searchQuery = '',
    this.selectedRoleFilter = 'الكل',
    this.selectedUsers = const {},
    this.selectedSubjects = const {},
    this.isLoading = false,
    this.isSearching = false,
    this.isDeleting = false,
    this.isOptimizing = false,
    this.error,
    this.showSearchBar = false,
  });

  AdministrationState copyWith({
    List<UserProfile>? users,
    List<UserProfile>? filteredUsers,
    List<Subject>? subjects,
    List<Subject>? filteredSubjects,
    List<Section>? sections,
    List<Section>? filteredSections,
    Map<String, dynamic>? storageStats,
    String? searchQuery,
    String? selectedRoleFilter,
    Set<String>? selectedUsers,
    Set<String>? selectedSubjects,
    bool? isLoading,
    bool? isSearching,
    bool? isDeleting,
    bool? isOptimizing,
    String? error,
    bool? showSearchBar,
  }) => AdministrationState(
    users: users ?? this.users,
    filteredUsers: filteredUsers ?? this.filteredUsers,
    subjects: subjects ?? this.subjects,
    filteredSubjects: filteredSubjects ?? this.filteredSubjects,
    sections: sections ?? this.sections,
    filteredSections: filteredSections ?? this.filteredSections,
    storageStats: storageStats ?? this.storageStats,
    searchQuery: searchQuery ?? this.searchQuery,
    selectedRoleFilter: selectedRoleFilter ?? this.selectedRoleFilter,
    selectedUsers: selectedUsers ?? this.selectedUsers,
    selectedSubjects: selectedSubjects ?? this.selectedSubjects,
    isLoading: isLoading ?? this.isLoading,
    isSearching: isSearching ?? this.isSearching,
    isDeleting: isDeleting ?? this.isDeleting,
    isOptimizing: isOptimizing ?? this.isOptimizing,
    error: error ?? this.error,
    showSearchBar: showSearchBar ?? this.showSearchBar,
  );
}

final administrationProvider = StateNotifierProvider.autoDispose<
  AdministrationNotifier,
  AdministrationState
>((ref) => AdministrationNotifier(ref));

class AdministrationNotifier extends StateNotifier<AdministrationState> {
  AdministrationNotifier(this._ref) : super(const AdministrationState());

  final Ref _ref;
  late final AdministrationRepository _repo = _ref.read(
    administrationRepositoryProvider,
  );

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repo.getAllUsers();
      final subjects = await _repo.getAllSubjects();
      final storageStats = await _repo.getStorageStats();

      state = state.copyWith(
        isLoading: false,
        users: users,
        filteredUsers: users,
        subjects: subjects,
        filteredSubjects: subjects,
        storageStats: storageStats,
      );

      // Also fetch sections
      await loadSections();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadSections() async {
    try {
      final sections = await _repo.getAllSections();
      state = state.copyWith(sections: sections, filteredSections: sections);
    } catch (e) {
      // Don't override main error, sections are optional
      print('Error loading sections: $e');
    }
  }

  Future<void> fetchSectionsForAssistant(String assistantId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sections = await _repo.getSectionsForAssistant(assistantId);
      state = state.copyWith(
        isLoading: false,
        sections: sections,
        filteredSections: sections,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchSectionsForSubjects(List<String> subjectIds) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sections = await _repo.getSectionsForSubjects(subjectIds);
      state = state.copyWith(
        isLoading: false,
        sections: sections,
        filteredSections: sections,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repo.getAllUsers();
      state = state.copyWith(
        isLoading: false,
        users: users,
        filteredUsers: users,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadSubjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final subjects = await _repo.getAllSubjects();
      state = state.copyWith(
        isLoading: false,
        subjects: subjects,
        filteredSubjects: subjects,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        filteredUsers: state.users,
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true, searchQuery: query);
    try {
      final results = await _repo.searchUsers(query);
      state = state.copyWith(isSearching: false, filteredUsers: results);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  Future<void> searchSubjects(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        filteredSubjects: state.subjects,
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true, searchQuery: query);
    try {
      final results = await _repo.searchSubjects(query);
      state = state.copyWith(isSearching: false, filteredSubjects: results);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  Future<void> filterUsersByRole(String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final filteredUsers =
          role == 'الكل' ? state.users : await _repo.getUsersByRole(role);
      state = state.copyWith(
        isLoading: false,
        filteredUsers: filteredUsers,
        selectedRoleFilter: role,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> filterSubjectsByYear(int year) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final filteredSubjects = await _repo.getSubjectsByYear(year);
      state = state.copyWith(
        isLoading: false,
        filteredSubjects: filteredSubjects,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createUser(UserProfile userProfile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repo.createUser(userProfile);
      if (success) {
        await loadUsers(); // Reload users list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repo.updateUserRole(userId, role);
      if (success) {
        await loadUsers(); // Reload users list
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    state = state.copyWith(isDeleting: true, error: null);
    try {
      final success = await _repo.deleteUser(userId);
      if (success) {
        await loadUsers(); // Reload users list
      }
      state = state.copyWith(isDeleting: false);
      return success;
    } catch (e) {
      state = state.copyWith(isDeleting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> bulkDeleteUsers(List<String> userIds) async {
    state = state.copyWith(isDeleting: true, error: null);
    try {
      final success = await _repo.bulkDeleteUsers(userIds);
      if (success) {
        await loadUsers(); // Reload users list
        state = state.copyWith(selectedUsers: {});
      }
      state = state.copyWith(isDeleting: false);
      return success;
    } catch (e) {
      state = state.copyWith(isDeleting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> addSubject(Subject subject) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.addSubject(subject);
      await loadSubjects(); // Reload subjects list
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateSubject(Subject subject) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.updateSubject(subject);
      await loadSubjects(); // Reload subjects list
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteSubject(String subjectId) async {
    state = state.copyWith(isDeleting: true, error: null);
    try {
      await _repo.deleteSubject(subjectId);
      await loadSubjects(); // Reload subjects list
      state = state.copyWith(isDeleting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isDeleting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> optimizeStorage() async {
    state = state.copyWith(isOptimizing: true, error: null);
    try {
      final success = await _repo.optimizeStorage();
      if (success) {
        final storageStats = await _repo.getStorageStats();
        state = state.copyWith(isOptimizing: false, storageStats: storageStats);
      }
      return success;
    } catch (e) {
      state = state.copyWith(isOptimizing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> sendNotificationToUser(
    String userId,
    String title,
    String body,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repo.sendNotificationToUser(userId, title, body);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> sendBulkNotification(
    List<String> userIds,
    String title,
    String body,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repo.sendBulkNotification(userIds, title, body);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void toggleUserSelection(String userId) {
    final newSelection = Set<String>.from(state.selectedUsers);
    if (newSelection.contains(userId)) {
      newSelection.remove(userId);
    } else {
      newSelection.add(userId);
    }
    state = state.copyWith(selectedUsers: newSelection);
  }

  void toggleSubjectSelection(String subjectId) {
    final newSelection = Set<String>.from(state.selectedSubjects);
    if (newSelection.contains(subjectId)) {
      newSelection.remove(subjectId);
    } else {
      newSelection.add(subjectId);
    }
    state = state.copyWith(selectedSubjects: newSelection);
  }

  void selectAllUsers() {
    final allUserIds = state.filteredUsers.map((u) => u.id).toSet();
    state = state.copyWith(selectedUsers: allUserIds);
  }

  void selectAllSubjects() {
    final allSubjectIds = state.filteredSubjects.map((s) => s.id).toSet();
    state = state.copyWith(selectedSubjects: allSubjectIds);
  }

  void clearUserSelection() {
    state = state.copyWith(selectedUsers: {});
  }

  void clearSubjectSelection() {
    state = state.copyWith(selectedSubjects: {});
  }

  void toggleSearchBar() {
    state = state.copyWith(showSearchBar: !state.showSearchBar);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
