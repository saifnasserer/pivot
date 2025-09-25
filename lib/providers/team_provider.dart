import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pivot/models/team_member.dart';

class TeamProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final CollectionReference _teamCollection;

  List<TeamMember> _teamMembers = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TeamMember> get teamMembers => _teamMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TeamProvider() {
    _teamCollection = _firestore.collection('team_members');
    fetchTeamMembers();
  }

  // Fetch all team members
  Future<void> fetchTeamMembers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot =
          await _teamCollection.orderBy('createdAt', descending: true).get();

      _teamMembers =
          snapshot.docs.map((doc) => TeamMember.fromFirestore(doc)).toList();
    } catch (e) {
      _error = 'Failed to fetch team members: $e';
      //debugprint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new team member
  Future<void> addTeamMember(TeamMember member) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _teamCollection.doc(member.id).set(member.toJson());
      await fetchTeamMembers(); // Refresh the list
    } catch (e) {
      _error = 'Failed to add team member: $e';
      //debugprint(_error);
      throw Exception(_error);
    }
  }

  // Update an existing team member
  Future<void> updateTeamMember(TeamMember member) async {
    try {
      await _teamCollection.doc(member.id).update(member.toJson());
      await fetchTeamMembers(); // Refresh the list
    } catch (e) {
      _error = 'Failed to update team member: $e';
      //debugprint(_error);
      throw Exception(_error);
    }
  }

  // Delete a team member
  Future<void> deleteTeamMember(String memberId) async {
    try {
      await _teamCollection.doc(memberId).delete();
      await fetchTeamMembers(); // Refresh the list
    } catch (e) {
      _error = 'Failed to delete team member: $e';
      //debugprint(_error);
      throw Exception(_error);
    }
  }

  // Filter team members by role, purpose, and skills
}
