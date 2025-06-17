class GuideContent {
  final String id;
  final String guidebookUrl;
  final List<String> planImageUrls;

  GuideContent({
    this.id = 'default_guide',
    required this.guidebookUrl,
    required this.planImageUrls,
  });

  factory GuideContent.fromMap(Map<String, dynamic> map) {
    return GuideContent(
      id: map['id'] ?? 'default_guide',
      guidebookUrl: map['guidebookUrl'] as String,
      planImageUrls: List<String>.from(map['planImageUrls'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guidebookUrl': guidebookUrl,
      'planImageUrls': planImageUrls,
    };
  }
}
