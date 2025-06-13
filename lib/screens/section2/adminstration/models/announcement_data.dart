import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Data class for announcements, compatible with Firestore
class AnnouncementData {
  final String? id;
  final String title;
  final String date;
  final Color color;
  final String description;
  final List<String> tags;
  final DateTime timestamp;

  AnnouncementData({
    this.id,
    required this.title,
    required this.date,
    required this.color,
    required this.description,
    required this.tags,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert an AnnouncementData object into a map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'color': color.value,
      'description': description,
      'tags': tags,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Create an AnnouncementData object from a Firestore document
  factory AnnouncementData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AnnouncementData(
      id: doc.id,
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      color: Color(data['color'] ?? 0xFFFFFFFF),
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
