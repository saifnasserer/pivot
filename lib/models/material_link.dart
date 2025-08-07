import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'material_link.g.dart';

enum MaterialType { video, pdf, document, image, link }

@HiveType(typeId: 8)
class MaterialLink extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String? thumbnail;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final MaterialType type;

  @HiveField(5)
  final Map<String, dynamic> metadata;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? lastAccessed;

  @HiveField(8)
  final Map<String, double> userRatings; // userId -> rating (1-5)

  @HiveField(9)
  final int totalRatings;

  @HiveField(10)
  final double averageRating;

  MaterialLink({
    required this.title,
    required this.url,
    this.thumbnail,
    this.description,
    required this.type,
    this.metadata = const {},
    DateTime? createdAt,
    this.lastAccessed,
    this.userRatings = const {},
    this.totalRatings = 0,
    this.averageRating = 0.0,
  }) : createdAt = createdAt ?? DateTime.now();

  MaterialLink copyWith({
    String? title,
    String? url,
    String? thumbnail,
    String? description,
    MaterialType? type,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastAccessed,
    Map<String, double>? userRatings,
    int? totalRatings,
    double? averageRating,
  }) {
    return MaterialLink(
      title: title ?? this.title,
      url: url ?? this.url,
      thumbnail: thumbnail ?? this.thumbnail,
      description: description ?? this.description,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      userRatings: userRatings ?? this.userRatings,
      totalRatings: totalRatings ?? this.totalRatings,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  static MaterialLink fromMap(Map<String, dynamic> map) {
    // Handle legacy format (just title and url)
    if (map.length == 2 && map.containsKey('title') && map.containsKey('url')) {
      return MaterialLink(
        title: map['title'] ?? '',
        url: map['url'] ?? '',
        type: _detectType(map['url'] ?? ''),
      );
    }

    // Handle new format with all fields
    return MaterialLink(
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      thumbnail: map['thumbnail'],
      description: map['description'],
      type:
          map['type'] != null
              ? MaterialType.values.firstWhere(
                (e) => e.name == map['type'],
                orElse: () => _detectType(map['url'] ?? ''),
              )
              : _detectType(map['url'] ?? ''),
      metadata:
          map['metadata'] is Map
              ? Map<String, dynamic>.from(map['metadata'])
              : {},
      createdAt:
          map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
              : null,
      lastAccessed:
          map['lastAccessed'] != null
              ? DateTime.tryParse(map['lastAccessed'])
              : null,
      userRatings: _parseUserRatings(map['userRatings']),
      totalRatings:
          map['totalRatings'] is int
              ? map['totalRatings']
              : int.tryParse(map['totalRatings']?.toString() ?? '0') ?? 0,
      averageRating:
          map['averageRating'] is double
              ? map['averageRating']
              : double.tryParse(map['averageRating']?.toString() ?? '0.0') ??
                  0.0,
    );
  }

  static Map<String, double> _parseUserRatings(dynamic ratingsData) {
    if (ratingsData == null) return {};

    if (ratingsData is Map) {
      return Map<String, double>.from(ratingsData);
    }

    if (ratingsData is String) {
      try {
        // Try to parse string representation of map
        // This is a simplified parser - in production you might want a more robust solution
        return {};
      } catch (e) {
        return {};
      }
    }

    return {};
  }

  Map<String, dynamic> toLegacyMap() {
    return {
      'title': title,
      'url': url,
      'thumbnail': thumbnail ?? '',
      'description': description ?? '',
      'type': type.name,
      'metadata': metadata.toString(),
      'createdAt': createdAt.toIso8601String(),
      'lastAccessed': lastAccessed?.toIso8601String() ?? '',
      'userRatings': userRatings,
      'totalRatings': totalRatings,
      'averageRating': averageRating,
    };
  }

  static MaterialType _detectType(String url) {
    final lowerUrl = url.toLowerCase();

    // Video platforms
    if (lowerUrl.contains('youtube.com') ||
        lowerUrl.contains('youtu.be') ||
        lowerUrl.contains('vimeo.com') ||
        lowerUrl.contains('dailymotion.com')) {
      return MaterialType.video;
    }

    // Document platforms
    if (lowerUrl.contains('drive.google.com') && lowerUrl.contains('/file/')) {
      return MaterialType.document;
    }
    if (lowerUrl.contains('docs.google.com')) {
      return MaterialType.document;
    }
    if (lowerUrl.contains('onedrive.live.com')) {
      return MaterialType.document;
    }

    // File extensions
    if (lowerUrl.endsWith('.pdf')) {
      return MaterialType.pdf;
    }
    if (lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp')) {
      return MaterialType.image;
    }
    if (lowerUrl.endsWith('.doc') ||
        lowerUrl.endsWith('.docx') ||
        lowerUrl.endsWith('.ppt') ||
        lowerUrl.endsWith('.pptx') ||
        lowerUrl.endsWith('.xls') ||
        lowerUrl.endsWith('.xlsx')) {
      return MaterialType.document;
    }

    return MaterialType.link;
  }

  String get displayTitle {
    if (title.isNotEmpty) return title;

    // Extract title from URL if no title provided
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.isNotEmpty) {
      return uri.host.replaceAll('www.', '');
    }

    return 'Untitled Material';
  }

  String get typeDisplayName {
    switch (type) {
      case MaterialType.video:
        return 'Video';
      case MaterialType.pdf:
        return 'PDF Document';
      case MaterialType.document:
        return 'Document';
      case MaterialType.image:
        return 'Image';
      case MaterialType.link:
        return 'Link';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case MaterialType.video:
        return Icons.play_circle_outline;
      case MaterialType.pdf:
        return Icons.picture_as_pdf;
      case MaterialType.document:
        return Icons.description;
      case MaterialType.image:
        return Icons.image;
      case MaterialType.link:
        return Icons.link;
    }
  }

  String? get videoId {
    if (type != MaterialType.video) return null;

    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.last;
    }

    return null;
  }

  String? get youtubeThumbnail {
    final videoId = this.videoId;
    if (videoId == null) return null;

    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  String? get pdfThumbnail {
    if (type != MaterialType.pdf) return null;

    // For PDFs, we'll use a placeholder thumbnail that represents PDF content
    // In a real implementation, you could generate actual PDF thumbnails
    return null; // Will fall back to placeholder
  }

  String? get bestThumbnail {
    // Priority: custom thumbnail > YouTube thumbnail > PDF thumbnail > null
    if (thumbnail?.isNotEmpty == true) {
      return thumbnail;
    }

    if (type == MaterialType.video) {
      return youtubeThumbnail;
    }

    if (type == MaterialType.pdf) {
      return pdfThumbnail;
    }

    return null;
  }

  double get averageRatingCalculated {
    if (userRatings.isEmpty) return 0.0;
    final sum = userRatings.values.reduce((a, b) => a + b);
    return sum / userRatings.length;
  }

  int get totalRatingsCalculated => userRatings.length;

  double? getUserRating(String userId) {
    return userRatings[userId];
  }

  bool hasUserRated(String userId) {
    return userRatings.containsKey(userId);
  }
}
