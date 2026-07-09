import 'package:liftly/domain/models/workout_session.dart';
import 'package:liftly/core/utils/muscle_detector.dart';

class RecoveryAnalyzer {
  static const int fullRecoveryHours = 48;
  static const int maxSetsForZeroRecovery = 12;

  /// Returns a map of MuscleGroup to Recovery Percentage (0.0 to 1.0)
  /// 1.0 = Fully Recovered (Green)
  /// 0.0 = Fully Fatigued (Red)
  static Map<MuscleGroup, double> calculateRecovery(List<WorkoutSession> recentWorkouts) {
    final now = DateTime.now();
    final fatigueMap = <MuscleGroup, double>{};

    for (final workout in recentWorkouts) {
      if (workout.endedAt == null) continue;
      
      final hoursSinceWorkout = now.difference(workout.endedAt!).inHours;
      if (hoursSinceWorkout >= fullRecoveryHours) continue;

      // Calculate decay factor (1.0 = just finished, 0.0 = fully recovered)
      final decayFactor = 1.0 - (hoursSinceWorkout / fullRecoveryHours);

      // Sum sets per muscle in this workout
      final workoutMuscles = <MuscleGroup, int>{};
      for (final ex in workout.exercises) {
        if (!ex.skipped) {
          final muscle = MuscleDetector.detectPrimaryMuscle(ex.name, ex.variation);
          if (muscle != MuscleGroup.unknown) {
            workoutMuscles[muscle] = (workoutMuscles[muscle] ?? 0) + ex.sets.length;
          }
        }
      }

      // Add remaining fatigue
      workoutMuscles.forEach((muscle, sets) {
        final fatigueContribution = sets * decayFactor;
        fatigueMap[muscle] = (fatigueMap[muscle] ?? 0) + fatigueContribution;
      });
    }

    // Convert fatigue to recovery percentage
    final recoveryMap = <MuscleGroup, double>{};
    for (final muscle in MuscleGroup.values) {
      if (muscle == MuscleGroup.unknown) continue;
      
      final fatigue = fatigueMap[muscle] ?? 0.0;
      double recovery = 1.0 - (fatigue / maxSetsForZeroRecovery);
      if (recovery < 0.0) recovery = 0.0;
      if (recovery > 1.0) recovery = 1.0;
      
      recoveryMap[muscle] = recovery;
    }

    return recoveryMap;
  }
}
