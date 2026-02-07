import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class IsarWorkoutSession {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String workoutId;

  late String userId;

  String? planId;
  String? planName;

  late DateTime workoutDate;

  DateTime? startedAt;
  DateTime? endedAt;

  final exercises = IsarLinks<IsarSessionExercise>();

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isDraft = false;
}

@collection
class IsarSessionExercise {
  Id id = Isar.autoIncrement;

  late String exerciseId;

  late String name;

  int order = 0;

  bool skipped = false;
  bool isTemplate = false;

  final sets = IsarLinks<IsarExerciseSet>();

  @Backlink(to: 'exercises')
  final workout = IsarLink<IsarWorkoutSession>();
}

@collection
class IsarExerciseSet {
  Id id = Isar.autoIncrement;

  late String setId;

  int setNumber = 0;

  final segments = IsarLinks<IsarSetSegment>();

  @Backlink(to: 'sets')
  final exercise = IsarLink<IsarSessionExercise>();
}

@collection
class IsarSetSegment {
  Id id = Isar.autoIncrement; // Isar internal ID

  late String segmentId; // Logic segment ID from app

  double weight = 0;
  int repsFrom = 0;
  int repsTo = 0;
  int segmentOrder = 0;
  String? notes;

  @Backlink(to: 'segments')
  final set = IsarLink<IsarExerciseSet>();
}

@collection
class IsarPreference {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  late String value;

  late DateTime updatedAt;
}

// ================= PLANS MODELS =================

@collection
class IsarWorkoutPlan {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String planId;

  late String userId;
  late String name;
  String? description;

  final exercises = IsarLinks<IsarPlanExercise>();

  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class IsarPlanExercise {
  Id id = Isar.autoIncrement;

  late String exerciseId;
  late String name;
  late int order;

  @Backlink(to: 'exercises')
  final plan = IsarLink<IsarWorkoutPlan>();
}
