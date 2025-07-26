import 'package:pivot/models/guidebook_model.dart';

class GuideContent {
  final String id;
  final List<Guidebook> guidebooks;

  GuideContent({
    this.id = 'default_guide',
    required this.guidebooks,
  });

  factory GuideContent.fromMap(Map<String, dynamic> map) {
    return GuideContent(
      id: map['id'] ?? 'default_guide',
      guidebooks: (map['guidebooks'] as List<dynamic>? ?? [])
          .map((item) => Guidebook.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guidebooks': guidebooks.map((gb) => gb.toMap()).toList(),
    };
  }
}

