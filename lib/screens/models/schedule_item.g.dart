// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleItemAdapter extends TypeAdapter<ScheduleItem> {
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
      notificationEnabled: fields[6] as bool,
      order: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleItem obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.notificationEnabled)
      ..writeByte(7)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScheduleItemTypeAdapter extends TypeAdapter<ScheduleItemType> {
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
      other is ScheduleItemTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
