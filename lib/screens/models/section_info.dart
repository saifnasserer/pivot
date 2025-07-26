class SectionInfo {
  final String id; // Automatically set from title
  final String title;
  final String days;
  final String location;
  final String time;

  SectionInfo({
    required this.title,
    required this.days,
    required this.location,
    required this.time,
  }) : id = title; // Initialize id with the title value

  // Optional: Add copyWith method for easier updates
  SectionInfo copyWith({
    String? title,
    String? days,
    String? location,
    String? time,
  }) {
    return SectionInfo(
      title: title ?? this.title,
      days: days ?? this.days,
      location: location ?? this.location,
      time: time ?? this.time,
    );
  }
}
