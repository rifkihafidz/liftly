// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutMetadataAdapter extends TypeAdapter<WorkoutMetadata> {
  @override
  final int typeId = 6;

  @override
  WorkoutMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutMetadata(
      id: fields[0] as String,
      userId: fields[1] as String,
      date: fields[2] as DateTime,
      isDraft: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutMetadata obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.isDraft);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
