part of '../api_service.dart';

class StatsResponse {
  final List<dynamic> workouts;
  final int workoutCount;
  final double totalVolume;
  final int averageDurationMinutes;
  final Map<String, double> personalRecords;
  final Map<String, double> topExercisesByVolume;
  final String periodStart;
  final String periodEnd;

  StatsResponse({
    required this.workouts,
    required this.workoutCount,
    required this.totalVolume,
    required this.averageDurationMinutes,
    required this.personalRecords,
    required this.topExercisesByVolume,
    required this.periodStart,
    required this.periodEnd,
  });

  factory StatsResponse.fromJson(Map<String, dynamic> json) {
    return StatsResponse(
      workouts: json['workouts'] as List<dynamic>? ?? [],
      workoutCount: json['workoutCount'] as int? ?? 0,
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0.0,
      averageDurationMinutes: json['averageDurationMinutes'] as int? ?? 0,
      personalRecords: _parseDoubleMap(json['personalRecords']),
      topExercisesByVolume: _parseDoubleMap(json['topExercisesByVolume']),
      periodStart: json['periodStart'] as String? ?? '',
      periodEnd: json['periodEnd'] as String? ?? '',
    );
  }

  static Map<String, double> _parseDoubleMap(dynamic data) {
    if (data == null) return {};
    if (data is Map) {
      return Map<String, double>.from(
        data.cast<String, dynamic>().map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      );
    }
    return {};
  }
}
