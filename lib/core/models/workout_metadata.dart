import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'workout_metadata.g.dart';

@HiveType(typeId: 6)
class WorkoutMetadata extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final bool isDraft;

  const WorkoutMetadata({
    required this.id,
    required this.userId,
    required this.date,
    required this.isDraft,
  });

  @override
  List<Object?> get props => [id, userId, date, isDraft];
}
