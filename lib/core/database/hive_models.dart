import 'package:hive/hive.dart';

part 'hive_models.g.dart';

// TypeIds:
// 0: HiveWorkoutSession
// 1: HiveSessionExercise
// 2: HiveExerciseSet
// 3: HiveSetSegment
// 4: HiveWorkoutPlan
// 5: HivePlanExercise
// 6: HivePreference

@HiveType(typeId: 0)
class HiveWorkoutSession extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String userId;

  @HiveField(2)
  String? planId;

  @HiveField(3)
  String? planName;

  @HiveField(4)
  late DateTime workoutDate;

  @HiveField(5)
  DateTime? startedAt;

  @HiveField(6)
  DateTime? endedAt;

  @HiveField(7)
  late List<HiveSessionExercise> exercises;

  @HiveField(8)
  late DateTime createdAt;

  @HiveField(9)
  late DateTime updatedAt;

  @HiveField(10)
  bool isDraft = false;
}

@HiveType(typeId: 1)
class HiveSessionExercise extends HiveObject {
  @HiveField(0)
  late String id; // Exercise ID

  @HiveField(1)
  late String name;

  @HiveField(2)
  int order = 0;

  @HiveField(3)
  bool skipped = false;

  @HiveField(4)
  bool isTemplate = false;

  @HiveField(5)
  late List<HiveExerciseSet> sets;
}

@HiveType(typeId: 2)
class HiveExerciseSet extends HiveObject {
  @HiveField(0)
  late String id; // Set ID

  @HiveField(1)
  int setNumber = 0;

  @HiveField(2)
  late List<HiveSetSegment> segments;
}

@HiveType(typeId: 3)
class HiveSetSegment extends HiveObject {
  @HiveField(0)
  late String id; // Segment ID

  @HiveField(1)
  double weight = 0;

  @HiveField(2)
  int repsFrom = 0;

  @HiveField(3)
  int repsTo = 0;

  @HiveField(4)
  int segmentOrder = 0;

  @HiveField(5)
  String? notes;
}

@HiveType(typeId: 4)
class HiveWorkoutPlan extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String userId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  String? description;

  @HiveField(4)
  late List<HivePlanExercise> exercises;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;
}

@HiveType(typeId: 5)
class HivePlanExercise extends HiveObject {
  @HiveField(0)
  late String id; // Exercise ID (reference to generic exercise or unique?)

  @HiveField(1)
  late String name;

  @HiveField(2)
  int order = 0;
}

@HiveType(typeId: 6)
class HivePreference extends HiveObject {
  @HiveField(0)
  late String prefKey;

  @HiveField(1)
  late String value;

  @HiveField(2)
  late DateTime updatedAt;
}
