import '../models/workout_session.dart';
import '../models/personal_record.dart';

class StatisticsService {
  /// Helper to identify unilateral exercises
  static bool isUnilateral(String name) {
    final lower = name.toLowerCase();
    return lower.contains('single') || lower.contains('unilateral');
  }

  /// Calculate exercise metrics (volume, max weight, etc.) for a single session
  static Map<String, dynamic> calculateSessionMetrics(
    SessionExercise ex,
    DateTime workoutDate,
    List<ExerciseSet> sets,
  ) {
    double sessionMaxWeight = 0;
    int sessionMaxWeightReps = 0;
    double sessionTotalVolume = 0;
    double bestSetVolume = 0;
    String bestSetVolumeBreakdown = '';
    double bestSetVolumeWeight = 0;
    int bestSetVolumeReps = 0;
    int sessionTotalReps = 0;

    final isUnilateralEx = isUnilateral(ex.name);
    final volumeMultiplier = isUnilateralEx ? 2 : 1;

    for (final set in sets) {
      final segments = set.segments;
      double currentSetVolume = 0;
      List<String> breakdownParts = [];
      double firstSegmentWeight = 0;
      int totalSetReps = 0;

      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i];
        final effectiveReps = seg.repsTo - seg.repsFrom + 1;

        if (i == 0) firstSegmentWeight = seg.weight;

        totalSetReps += effectiveReps;
        sessionTotalReps += effectiveReps;

        // Max Weight (raw weight, not multiplied)
        if (seg.weight > sessionMaxWeight) {
          sessionMaxWeight = seg.weight;
          sessionMaxWeightReps = effectiveReps;
        } else if (seg.weight == sessionMaxWeight) {
          if (effectiveReps > sessionMaxWeightReps) {
            sessionMaxWeightReps = effectiveReps;
          }
        }

        final vol = seg.weight * effectiveReps * volumeMultiplier;
        currentSetVolume += vol;
        sessionTotalVolume += vol;

        breakdownParts.add(
            '${seg.weight % 1 == 0 ? seg.weight.toInt() : seg.weight} kg x $effectiveReps');
      }

      if (currentSetVolume > bestSetVolume) {
        bestSetVolume = currentSetVolume;
        bestSetVolumeBreakdown = breakdownParts.join(' + ');
        bestSetVolumeWeight = firstSegmentWeight;
        bestSetVolumeReps = totalSetReps;
      }
    }

    return {
      'workoutDate': workoutDate.toIso8601String(),
      'totalVolume': sessionTotalVolume,
      'totalReps': sessionTotalReps,
      'maxWeight': sessionMaxWeight,
      'maxWeightReps': sessionMaxWeightReps,
      'bestSetVolume': bestSetVolume,
      'bestSetVolumeBreakdown': bestSetVolumeBreakdown,
      'bestSetVolumeWeight': bestSetVolumeWeight,
      'bestSetVolumeReps': bestSetVolumeReps,
      'sets': sets,
    };
  }

  /// Calculate Personal Record from history
  static PersonalRecord? calculatePRFromHistory(
    String exerciseName,
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) return null;

    double globalMaxWeight = 0;
    int globalMaxWeightReps = 0;

    double globalMaxSetVolume = 0;
    double globalMaxSetVolumeWeight = 0;
    int globalMaxSetVolumeReps = 0;
    String globalMaxSetVolumeBreakdown = '';

    double globalBestSessionVolume = 0;
    int globalBestSessionReps = 0;
    String? globalBestSessionDate;
    List<ExerciseSet>? globalBestSessionSets;

    for (final record in history) {
      // 1. Max Weight
      final rMaxWeight = record['maxWeight'] as double;
      if (rMaxWeight > globalMaxWeight) {
        globalMaxWeight = rMaxWeight;
        globalMaxWeightReps = record['maxWeightReps'] as int;
      }

      // 2. Max Set Volume
      final rBestSetVol = record['bestSetVolume'] as double;
      if (rBestSetVol > globalMaxSetVolume) {
        globalMaxSetVolume = rBestSetVol;
        globalMaxSetVolumeWeight = record['bestSetVolumeWeight'] as double;
        globalMaxSetVolumeReps = record['bestSetVolumeReps'] as int;
        globalMaxSetVolumeBreakdown =
            record['bestSetVolumeBreakdown'] as String;
      }

      // 3. Best Session Volume
      final rSessionVol = record['totalVolume'] as double;
      final rSessionReps = record['totalReps'] as int? ?? 0;

      bool isNewBest = false;
      if (rSessionVol > globalBestSessionVolume) {
        isNewBest = true;
      } else if (globalBestSessionVolume == 0 && rSessionVol == 0) {
        if (rSessionReps > globalBestSessionReps) {
          isNewBest = true;
        }
      }

      if (isNewBest) {
        globalBestSessionVolume = rSessionVol;
        globalBestSessionReps = rSessionReps;
        globalBestSessionDate = record['workoutDate'] as String;
        globalBestSessionSets = record['sets'] as List<ExerciseSet>;
      }
    }

    if (globalMaxWeight == 0 &&
        globalMaxSetVolume == 0 &&
        globalBestSessionVolume == 0 &&
        globalBestSessionReps == 0) {
      return null;
    }

    return PersonalRecord(
      maxWeight: globalMaxWeight,
      maxWeightReps: globalMaxWeightReps,
      maxVolume: globalMaxSetVolume,
      maxVolumeWeight: globalMaxSetVolumeWeight,
      maxVolumeReps: globalMaxSetVolumeReps,
      maxVolumeBreakdown: globalMaxSetVolumeBreakdown,
      bestSessionVolume: globalBestSessionVolume,
      bestSessionReps: globalBestSessionReps,
      bestSessionDate: globalBestSessionDate,
      bestSessionSets: globalBestSessionSets,
      exerciseName: exerciseName,
    );
  }
}
