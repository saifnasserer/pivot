enum ScheduleItemType { lecture, section }

class ScheduleItem {
  final String id; // Use UUID or similar for unique IDs
  final String title;
  final String time;
  final String location;
  final String day; // e.g., 'السبت'
  final ScheduleItemType type;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.time,
    required this.location,
    required this.day,
    required this.type,
  });

  // copyWith method to create a new instance with updated values
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
