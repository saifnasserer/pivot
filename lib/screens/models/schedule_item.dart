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
  @HiveField(6)
  final bool notificationEnabled;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.time,
    required this.location,
    required this.day,
    required this.type,
    this.notificationEnabled = true, // Default to enabled
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
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
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
      'notificationEnabled': notificationEnabled,
    };
  }

  ScheduleItem copyWith({
    String? id,
    String? title,
    String? time,
    String? location,
    String? day,
    ScheduleItemType? type,
    bool? notificationEnabled,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      location: location ?? this.location,
      day: day ?? this.day,
      type: type ?? this.type,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}

// Custom adapter to handle null safety properly
class ScheduleItemCustomAdapter extends TypeAdapter<ScheduleItem> {
  @override
  final int typeId = 4;

  @override
  ScheduleItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleItem(
      id: fields[0] as String,
      title: fields[1] as String,
      time: fields[2] as String,
      location: fields[3] as String,
      day: fields[4] as String,
      type: fields[5] as ScheduleItemType,
      notificationEnabled: fields[6] as bool? ?? true, // Handle null values
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.day)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.notificationEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleItemCustomAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// Custom adapter for ScheduleItemType
class ScheduleItemTypeCustomAdapter extends TypeAdapter<ScheduleItemType> {
  @override
  final int typeId = 3;

  @override
  ScheduleItemType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScheduleItemType.lecture;
      case 1:
        return ScheduleItemType.section;
      default:
        return ScheduleItemType.lecture;
    }
  }

  @override
  void write(BinaryWriter writer, ScheduleItemType obj) {
    switch (obj) {
      case ScheduleItemType.lecture:
        writer.writeByte(0);
        break;
      case ScheduleItemType.section:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleItemTypeCustomAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
