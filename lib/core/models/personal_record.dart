import 'package:equatable/equatable.dart';
import 'workout_session.dart';

class PersonalRecord extends Equatable {
  // Metric 1: Max Weight (Heaviest Set - individual segment)
  final double maxWeight;
  final int maxWeightReps;

  // Metric 2: Max Volume Set (Best volume in a single set - aggregated segments)
  final double maxVolume;
  final double maxVolumeWeight;
  final int maxVolumeReps;
  final String maxVolumeBreakdown; // ex: "(10 kg x 10 + 5 kg x 2)"

  // Metric 3: Best Session (Highest total volume in one workout)
  final double bestSessionVolume;
  final int bestSessionReps; // Added for bodyweight/zero-weight fallback
  final String? bestSessionDate;
  final List<ExerciseSet>? bestSessionSets;

  // We avoid storing complex objects like ExerciseSet here to keep it lighter for now
  // or we can keep it if needed for UI details.
  // Given the previous code had it:
  // final List<ExerciseSet>? bestSessionSets;
  // I will omit it for the isolate optimization as transferring full objects back and forth is heavy.
  // But if UI needs it, we must keep it.
  // Let's keep it but make sure it's transferable (it is, distinct from HiveObject issues).

  final String exerciseName;
  final String variation; // Original case variation (e.g., "Flat Barbell")

  const PersonalRecord({
    this.exerciseName = '',
    this.variation = '',
    this.maxWeight = 0,
    this.maxWeightReps = 0,
    this.maxVolume = 0,
    this.maxVolumeWeight = 0,
    this.maxVolumeReps = 0,
    this.maxVolumeBreakdown = '',
    this.bestSessionVolume = 0,
    this.bestSessionReps = 0,
    this.bestSessionDate,
    this.bestSessionSets,
  });

  @override
  List<Object?> get props => [
        exerciseName,
        variation,
        maxWeight,
        maxWeightReps,
        maxVolume,
        maxVolumeWeight,
        maxVolumeReps,
        maxVolumeBreakdown,
        bestSessionVolume,
        bestSessionReps,
        bestSessionDate,
        bestSessionSets,
      ];
}
