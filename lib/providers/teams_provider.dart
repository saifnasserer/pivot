import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String name;
  final String year;
  final DateTime createdAt;
  final bool isPinned;

  Team({
    required this.id,
    required this.name,
    required this.year,
    required this.createdAt,
    this.isPinned = false,
  });

  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name'] ?? '',
      year: data['year'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'year': year,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPinned': isPinned,
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? year,
    DateTime? createdAt,
    bool? isPinned,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

class TeamsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _teamsCollection;

  List<Team> _teams = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TeamsProvider() {
    _teamsCollection = _firestore.collection('teams');
    fetchTeams();
  }

  // Fetch all teams
  Future<void> fetchTeams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      QuerySnapshot snapshot;
      try {
        // Try with composite index
        snapshot =
            await _teamsCollection
                .orderBy('isPinned', descending: true)
                .orderBy('createdAt', descending: true)
                .get();
      } catch (e) {
        if (e.toString().contains('failed-precondition') ||
            e.toString().contains('requires an index')) {
          // Fallback to simple ordering if index doesn't exist
          snapshot =
              await _teamsCollection
                  .orderBy('createdAt', descending: true)
                  .get();
          //debugprint('Warning: Using fallback ordering until index is created');
        } else {
          rethrow;
        }
      }
      _teams = snapshot.docs.map((doc) => Team.fromFirestore(doc)).toList();
    } catch (e) {
      _error = 'Failed to fetch teams: $e';
      //debugprint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new team
  Future<void> addTeam(String name, String year) async {
    try {
      // Check if team name already exists
      if (_teams.any((t) => t.name == name)) {
        throw Exception('Team name already exists');
      }

      final team = {
        'name': name,
        'year': year,
        'createdAt': FieldValue.serverTimestamp(),
        'isPinned': false,
      };

      await _teamsCollection.add(team);
      await fetchTeams(); // Refresh the list
    } catch (e) {
      _error = 'Failed to add team: $e';
      //debugprint(_error);
      throw Exception(_error);
    }
  }

  // Toggle team pin status
  Future<void> toggleTeamPin(String teamId, bool isPinned) async {
    try {
      await _teamsCollection.doc(teamId).update({'isPinned': isPinned});

      // Update local state
      final index = _teams.indexWhere((team) => team.id == teamId);
      if (index != -1) {
        _teams[index] = _teams[index].copyWith(isPinned: isPinned);
        notifyListeners();
      }

      await fetchTeams(); // Refresh the list to ensure consistency
    } catch (e) {
      _error = 'Failed to update team pin status: $e';
      //debugprint(_error);
      throw Exception(_error);
    }
  }

  // Delete a team
  Future<void> deleteTeam(String teamId) async {
    try {
      await _teamsCollection.doc(teamId).delete();

      // Update local state
      _teams.removeWhere((team) => team.id == teamId);
      notifyListeners();

      await fetchTeams(); // Refresh the list to ensure consistency
    } catch (e) {
      _error = 'Failed to delete team: $e';
      //debugprint(_error);
      throw Exception(_error);
    }
  }
}
