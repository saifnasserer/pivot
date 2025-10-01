import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  final String id;
  final String name;
  final List<String> skills;
  final List<String> previousProjects;
  final String purpose;
  final String whatsappNumber;
  final String? linkedinProfile;
  final String userId;
  final DateTime createdAt;
  final String teamName;
  final String? year;
  final bool isPinned;

  TeamMember({
    required this.id,
    required this.name,
    required this.skills,
    required this.previousProjects,
    required this.purpose,
    required this.whatsappNumber,
    this.linkedinProfile,
    required this.userId,
    required this.createdAt,
    required this.teamName,
    this.year,
    this.isPinned = false,
  });

  factory TeamMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Handle both String and List<String> for previousProjects
    final prevProjectsRaw = data['previousProjects'];
    List<String> prevProjects;
    if (prevProjectsRaw is String) {
      prevProjects = prevProjectsRaw.isNotEmpty ? [prevProjectsRaw] : [];
    } else if (prevProjectsRaw is List) {
      prevProjects = List<String>.from(prevProjectsRaw);
    } else {
      prevProjects = [];
    }
    return TeamMember(
      id: doc.id,
      name: data['name'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      previousProjects: prevProjects,
      purpose: data['purpose'] ?? '',
      whatsappNumber: data['whatsappNumber'] ?? '',
      linkedinProfile: data['linkedinProfile'],
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      teamName: data['teamName'] ?? '',
      year: data['year'] as String?,
      isPinned: data['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'skills': skills,
      'previousProjects': previousProjects,
      'purpose': purpose,
      'whatsappNumber': whatsappNumber,
      'linkedinProfile': linkedinProfile,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'teamName': teamName,
      'year': year,
      'isPinned': isPinned,
    };
  }

  TeamMember copyWith({
    String? id,
    String? name,
    List<String>? skills,
    List<String>? previousProjects,
    String? purpose,
    String? whatsappNumber,
    String? linkedinProfile,
    String? userId,
    DateTime? createdAt,
    String? teamName,
    String? year,
    bool? isPinned,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      skills: skills ?? this.skills,
      previousProjects: previousProjects ?? this.previousProjects,
      purpose: purpose ?? this.purpose,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      linkedinProfile: linkedinProfile ?? this.linkedinProfile,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      teamName: teamName ?? this.teamName,
      year: year ?? this.year,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
