// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String?,
      department: fields[3] as String,
      level: fields[4] as String,
      section: fields[5] as String,
      profileImageUrl: fields[6] as String?,
      role: fields[7] as String,
      aboutMe: fields[8] as String,
      teachingSubjects: (fields[9] as List).cast<String>(),
      enrolledSubjects: (fields[10] as List).cast<String>(),
      gender: fields[11] as String,
      fcmToken: fields[12] as String?,
      lastTokenUpdate: fields[13] as DateTime?,
      notificationPreferences: fields[14] as NotificationPreferences?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.department)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.section)
      ..writeByte(6)
      ..write(obj.profileImageUrl)
      ..writeByte(7)
      ..write(obj.role)
      ..writeByte(8)
      ..write(obj.aboutMe)
      ..writeByte(9)
      ..write(obj.teachingSubjects)
      ..writeByte(10)
      ..write(obj.enrolledSubjects)
      ..writeByte(11)
      ..write(obj.gender)
      ..writeByte(12)
      ..write(obj.fcmToken)
      ..writeByte(13)
      ..write(obj.lastTokenUpdate)
      ..writeByte(14)
      ..write(obj.notificationPreferences);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationPreferencesAdapter
    extends TypeAdapter<NotificationPreferences> {
  @override
  final int typeId = 6;

  @override
  NotificationPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationPreferences(
      taskReminders: fields[0] as bool,
      classReminders: fields[1] as bool,
      announcements: fields[2] as bool,
      departmentNotifications: fields[3] as bool,
      levelNotifications: fields[4] as bool,
      maxNotificationsPerHour: fields[5] as int,
      welcomeNotification: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationPreferences obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.taskReminders)
      ..writeByte(1)
      ..write(obj.classReminders)
      ..writeByte(2)
      ..write(obj.announcements)
      ..writeByte(3)
      ..write(obj.departmentNotifications)
      ..writeByte(4)
      ..write(obj.levelNotifications)
      ..writeByte(5)
      ..write(obj.maxNotificationsPerHour)
      ..writeByte(6)
      ..write(obj.welcomeNotification);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
