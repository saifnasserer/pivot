// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_link.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaterialLinkAdapter extends TypeAdapter<MaterialLink> {
  @override
  final int typeId = 8;

  @override
  MaterialLink read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialLink(
      title: fields[0] as String,
      url: fields[1] as String,
      thumbnail: fields[2] as String?,
      description: fields[3] as String?,
      type: fields[4] as MaterialType,
      metadata: (fields[5] as Map).cast<String, dynamic>(),
      createdAt: fields[6] as DateTime?,
      lastAccessed: fields[7] as DateTime?,
      userRatings: (fields[8] as Map).cast<String, double>(),
      totalRatings: fields[9] as int,
      averageRating: fields[10] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialLink obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.thumbnail)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.metadata)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastAccessed)
      ..writeByte(8)
      ..write(obj.userRatings)
      ..writeByte(9)
      ..write(obj.totalRatings)
      ..writeByte(10)
      ..write(obj.averageRating);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialLinkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
