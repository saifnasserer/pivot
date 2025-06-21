import 'package:hive/hive.dart';
part 'schedule_item.g.dart';

@HiveType(typeId: 3)
enum ScheduleItemType {
  @HiveField(0)
  lecture,
  @HiveField(1)
  section,
}

@HiveType(typeId: 4)
class ScheduleItem extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String time;
  @HiveField(3)
  final String location;
  @HiveField(4)
  final String day;
  @HiveField(5)
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
      type:
          (json['type'] as String) == 'lecture'
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
