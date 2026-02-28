// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SetSegmentAdapter extends TypeAdapter<SetSegment> {
  @override
  final int typeId = 3;

  @override
  SetSegment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SetSegment(
      id: fields[0] as String,
      weight: fields[1] as double,
      repsFrom: fields[2] as int,
      repsTo: fields[3] as int,
      segmentOrder: fields[4] as int,
      notes: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SetSegment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.repsFrom)
      ..writeByte(3)
      ..write(obj.repsTo)
      ..writeByte(4)
      ..write(obj.segmentOrder)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetSegmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseSetAdapter extends TypeAdapter<ExerciseSet> {
  @override
  final int typeId = 2;

  @override
  ExerciseSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseSet(
      id: fields[0] as String,
      segments: (fields[1] as List).cast<SetSegment>(),
      setNumber: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseSet obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.segments)
      ..writeByte(2)
      ..write(obj.setNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionExerciseAdapter extends TypeAdapter<SessionExercise> {
  @override
  final int typeId = 1;

  @override
  SessionExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionExercise(
      id: fields[0] as String,
      name: fields[1] as String,
      order: fields[2] as int,
      skipped: fields[3] == null ? false : fields[3] as bool,
      isTemplate: fields[4] == null ? false : fields[4] as bool,
      sets: (fields[5] as List).cast<ExerciseSet>(),
      notes: fields[6] == null ? '' : fields[6] as String,
      variation: fields[7] == null ? '' : fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SessionExercise obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.order)
      ..writeByte(3)
      ..write(obj.skipped)
      ..writeByte(4)
      ..write(obj.isTemplate)
      ..writeByte(5)
      ..write(obj.sets)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.variation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutSessionAdapter extends TypeAdapter<WorkoutSession> {
  @override
  final int typeId = 0;

  @override
  WorkoutSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSession(
      id: fields[0] as String,
      userId: fields[1] as String,
      planId: fields[2] as String?,
      planName: fields[3] as String?,
      workoutDate: fields[4] as DateTime,
      startedAt: fields[5] as DateTime?,
      endedAt: fields[6] as DateTime?,
      exercises: (fields[7] as List).cast<SessionExercise>(),
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      isDraft: fields[10] == null ? false : fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSession obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.planId)
      ..writeByte(3)
      ..write(obj.planName)
      ..writeByte(4)
      ..write(obj.workoutDate)
      ..writeByte(5)
      ..write(obj.startedAt)
      ..writeByte(6)
      ..write(obj.endedAt)
      ..writeByte(7)
      ..write(obj.exercises)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.isDraft);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
