import 'package:flutter/material.dart';

/// Data class for announcements
class AnnouncementData {
  final String title;
  final String date;
  final Color color;
  final String description;
  final List<String>? tags;
  final DateTime timestamp;

  AnnouncementData({
    required this.title,
    required this.date,
    required this.color,
    required this.description,
    this.tags,
    DateTime? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now();
}
