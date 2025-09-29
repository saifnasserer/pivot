// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnouncementDataAdapter extends TypeAdapter<AnnouncementData> {
  @override
  final int typeId = 5;

  @override
  AnnouncementData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnouncementData(
      id: fields[0] as String?,
      title: fields[1] as String,
      date: fields[2] as String,
      description: fields[4] as String,
      tags: (fields[5] as List).cast<String>(),
      imageUrls: (fields[7] as List).cast<String>(),
      links: (fields[8] as List)
          .map((dynamic e) => (e as Map).cast<String, String>())
          .toList(),
      pinned: fields[9] as bool,
      draft: fields[10] as bool,
      level: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AnnouncementData obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.timestampMillis)
      ..writeByte(7)
      ..write(obj.imageUrls)
      ..writeByte(8)
      ..write(obj.links)
      ..writeByte(9)
      ..write(obj.pinned)
      ..writeByte(10)
      ..write(obj.draft)
      ..writeByte(11)
      ..write(obj.publishAtMillis)
      ..writeByte(12)
      ..write(obj.expireAtMillis)
      ..writeByte(13)
      ..write(obj.level);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
