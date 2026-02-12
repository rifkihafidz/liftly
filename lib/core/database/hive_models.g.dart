// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveWorkoutSessionAdapter extends TypeAdapter<HiveWorkoutSession> {
  @override
  final int typeId = 0;

  @override
  HiveWorkoutSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveWorkoutSession()
      ..id = fields[0] as String
      ..userId = fields[1] as String
      ..planId = fields[2] as String?
      ..planName = fields[3] as String?
      ..workoutDate = fields[4] as DateTime
      ..startedAt = fields[5] as DateTime?
      ..endedAt = fields[6] as DateTime?
      ..exercises = (fields[7] as List).cast<HiveSessionExercise>()
      ..createdAt = fields[8] as DateTime
      ..updatedAt = fields[9] as DateTime
      ..isDraft = fields[10] as bool;
  }

  @override
  void write(BinaryWriter writer, HiveWorkoutSession obj) {
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
      other is HiveWorkoutSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSessionExerciseAdapter extends TypeAdapter<HiveSessionExercise> {
  @override
  final int typeId = 1;

  @override
  HiveSessionExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSessionExercise()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..order = fields[2] as int
      ..skipped = fields[3] as bool
      ..isTemplate = fields[4] as bool
      ..sets = (fields[5] as List).cast<HiveExerciseSet>();
  }

  @override
  void write(BinaryWriter writer, HiveSessionExercise obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.sets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSessionExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveExerciseSetAdapter extends TypeAdapter<HiveExerciseSet> {
  @override
  final int typeId = 2;

  @override
  HiveExerciseSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveExerciseSet()
      ..id = fields[0] as String
      ..setNumber = fields[1] as int
      ..segments = (fields[2] as List).cast<HiveSetSegment>();
  }

  @override
  void write(BinaryWriter writer, HiveExerciseSet obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.setNumber)
      ..writeByte(2)
      ..write(obj.segments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveExerciseSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSetSegmentAdapter extends TypeAdapter<HiveSetSegment> {
  @override
  final int typeId = 3;

  @override
  HiveSetSegment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSetSegment()
      ..id = fields[0] as String
      ..weight = fields[1] as double
      ..repsFrom = fields[2] as int
      ..repsTo = fields[3] as int
      ..segmentOrder = fields[4] as int
      ..notes = fields[5] as String?;
  }

  @override
  void write(BinaryWriter writer, HiveSetSegment obj) {
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
      other is HiveSetSegmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveWorkoutPlanAdapter extends TypeAdapter<HiveWorkoutPlan> {
  @override
  final int typeId = 4;

  @override
  HiveWorkoutPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveWorkoutPlan()
      ..id = fields[0] as String
      ..userId = fields[1] as String
      ..name = fields[2] as String
      ..description = fields[3] as String?
      ..exercises = (fields[4] as List).cast<HivePlanExercise>()
      ..createdAt = fields[5] as DateTime
      ..updatedAt = fields[6] as DateTime;
  }

  @override
  void write(BinaryWriter writer, HiveWorkoutPlan obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.exercises)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveWorkoutPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HivePlanExerciseAdapter extends TypeAdapter<HivePlanExercise> {
  @override
  final int typeId = 5;

  @override
  HivePlanExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePlanExercise()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..order = fields[2] as int;
  }

  @override
  void write(BinaryWriter writer, HivePlanExercise obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePlanExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HivePreferenceAdapter extends TypeAdapter<HivePreference> {
  @override
  final int typeId = 6;

  @override
  HivePreference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePreference()
      ..prefKey = fields[0] as String
      ..value = fields[1] as String
      ..updatedAt = fields[2] as DateTime;
  }

  @override
  void write(BinaryWriter writer, HivePreference obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.prefKey)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
