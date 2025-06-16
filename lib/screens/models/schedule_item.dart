enum ScheduleItemType { lecture, section }

class ScheduleItem {
  final String id;
  final String title;
  final String time;
  final String location;
  final String day;
  final ScheduleItemType type;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.time,
    required this.location,
    required this.day,
    required this.type,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as String,
      title: json['title'] as String,
      time: json['time'] as String,
      location: json['location'] as String,
      day: json['day'] as String,
      type: (json['type'] as String) == 'lecture'
          ? ScheduleItemType.lecture
          : ScheduleItemType.section,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'location': location,
      'day': day,
      'type': type.toString().split('.').last, // e.g., 'lecture' or 'section'
    };
  }

  ScheduleItem copyWith({
    String? id,
    String? title,
    String? time,
    String? location,
    String? day,
    ScheduleItemType? type,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      location: location ?? this.location,
      day: day ?? this.day,
      type: type ?? this.type,
    );
  }
}
