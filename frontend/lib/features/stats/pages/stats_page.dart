import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  // Mock data - nanti dari API
  late List<WorkoutSession> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = _generateMockSessions();
  }

  List<WorkoutSession> _generateMockSessions() {
    return [
      WorkoutSession(
        id: 'session_1',
        userId: 'user_1',
        workoutDate: DateTime.now().subtract(const Duration(days: 1)),
        startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        endedAt: DateTime.now().subtract(const Duration(days: 1, minutes: 45)),
        exercises: [
          SessionExercise(
            id: 'ex_1',
            name: 'Bench Press',
            order: 0,
            sets: [
              ExerciseSet(
                id: 'set_1',
                setNumber: 1,
                segments: [
                  SetSegment(
                    id: 'seg_1',
                    weight: 80,
                    repsFrom: 6,
                    repsTo: 8,
                    segmentOrder: 0,
                  ),
                ],
              ),
              ExerciseSet(
                id: 'set_2',
                setNumber: 2,
                segments: [
                  SetSegment(
                    id: 'seg_2',
                    weight: 85,
                    repsFrom: 5,
                    repsTo: 7,
                    segmentOrder: 0,
                  ),
                ],
              ),
            ],
          ),
          SessionExercise(
            id: 'ex_2',
            name: 'Barbell Rows',
            order: 1,
            sets: [
              ExerciseSet(
                id: 'set_3',
                setNumber: 1,
                segments: [
                  SetSegment(
                    id: 'seg_3',
                    weight: 100,
                    repsFrom: 6,
                    repsTo: 8,
                    segmentOrder: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      WorkoutSession(
        id: 'session_2',
        userId: 'user_1',
        workoutDate: DateTime.now().subtract(const Duration(days: 3)),
        startedAt: DateTime.now().subtract(const Duration(days: 3, hours: 1, minutes: 15)),
        endedAt: DateTime.now().subtract(const Duration(days: 3, minutes: 50)),
        exercises: [
          SessionExercise(
            id: 'ex_3',
            name: 'Squats',
            order: 0,
            sets: [
              ExerciseSet(
                id: 'set_4',
                setNumber: 1,
                segments: [
                  SetSegment(
                    id: 'seg_4',
                    weight: 120,
                    repsFrom: 8,
                    repsTo: 10,
                    segmentOrder: 0,
                  ),
                ],
              ),
              ExerciseSet(
                id: 'set_5',
                setNumber: 2,
                segments: [
                  SetSegment(
                    id: 'seg_5',
                    weight: 120,
                    repsFrom: 8,
                    repsTo: 10,
                    segmentOrder: 0,
                  ),
                ],
              ),
              ExerciseSet(
                id: 'set_6',
                setNumber: 3,
                segments: [
                  SetSegment(
                    id: 'seg_6',
                    weight: 110,
                    repsFrom: 10,
                    repsTo: 12,
                    segmentOrder: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      WorkoutSession(
        id: 'session_3',
        userId: 'user_1',
        workoutDate: DateTime.now().subtract(const Duration(days: 5)),
        startedAt: DateTime.now().subtract(const Duration(days: 5, hours: 1, minutes: 30)),
        endedAt: DateTime.now().subtract(const Duration(days: 5, minutes: 55)),
        exercises: [
          SessionExercise(
            id: 'ex_4',
            name: 'Deadlift',
            order: 0,
            sets: [
              ExerciseSet(
                id: 'set_7',
                setNumber: 1,
                segments: [
                  SetSegment(
                    id: 'seg_7',
                    weight: 150,
                    repsFrom: 3,
                    repsTo: 5,
                    segmentOrder: 0,
                  ),
                ],
              ),
              ExerciseSet(
                id: 'set_8',
                setNumber: 2,
                segments: [
                  SetSegment(
                    id: 'seg_8',
                    weight: 150,
                    repsFrom: 3,
                    repsTo: 5,
                    segmentOrder: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              _SummaryCard(
                title: 'Total Workouts',
                value: _sessions.length.toString(),
                icon: Icons.fitness_center,
                color: AppColors.accent,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Total Volume',
                value: '${_calculateTotalVolume().toStringAsFixed(0)} kg',
                icon: Icons.scale,
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: 'Average Duration',
                value: _calculateAverageDuration(),
                icon: Icons.schedule,
                color: AppColors.warning,
              ),
              const SizedBox(height: 32),

              // Personal Records Section
              Text(
                'Personal Records',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ..._getPersonalRecords().entries.map((entry) {
                final exercise = entry.key;
                final maxWeight = entry.value;
                return _PRCard(
                  exercise: exercise,
                  maxWeight: maxWeight,
                );
              }),

              const SizedBox(height: 32),

              // Top Exercises by Volume
              Text(
                'Top Exercises by Volume',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ..._getTopExercisesByVolume().entries.map((entry) {
                final exercise = entry.key;
                final volume = entry.value;
                final maxVolume = _getTopExercisesByVolume().values.reduce((a, b) => a > b ? a : b);
                final percentage = (volume / maxVolume * 100).toInt();
                return _ExerciseVolumeCard(
                  exercise: exercise,
                  volume: volume,
                  percentage: percentage,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotalVolume() {
    double total = 0;
    for (var session in _sessions) {
      for (var exercise in session.exercises) {
        for (var set in exercise.sets) {
          for (var segment in set.segments) {
            total += segment.volume;
          }
        }
      }
    }
    return total;
  }

  String _calculateAverageDuration() {
    final durations = _sessions
        .where((s) => s.duration != null)
        .map((s) => s.duration!)
        .toList();

    if (durations.isEmpty) return '-';

    final totalMinutes = durations.fold<int>(0, (sum, d) => sum + d.inMinutes);
    final avgMinutes = totalMinutes ~/ durations.length;

    return '${avgMinutes}m';
  }

  Map<String, double> _getPersonalRecords() {
    final records = <String, double>{};

    for (var session in _sessions) {
      for (var exercise in session.exercises) {
        for (var set in exercise.sets) {
          for (var segment in set.segments) {
            final current = records[exercise.name] ?? 0;
            records[exercise.name] = segment.weight > current ? segment.weight : current;
          }
        }
      }
    }

    return Map.fromEntries(
      records.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  Map<String, double> _getTopExercisesByVolume() {
    final volumes = <String, double>{};

    for (var session in _sessions) {
      for (var exercise in session.exercises) {
        double exerciseVolume = 0;
        for (var set in exercise.sets) {
          for (var segment in set.segments) {
            exerciseVolume += segment.volume;
          }
        }
        volumes[exercise.name] = (volumes[exercise.name] ?? 0) + exerciseVolume;
      }
    }

    return Map.fromEntries(
      volumes.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PRCard extends StatelessWidget {
  final String exercise;
  final double maxWeight;

  const _PRCard({
    required this.exercise,
    required this.maxWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Personal Record',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              '${maxWeight.toStringAsFixed(0)} kg',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseVolumeCard extends StatelessWidget {
  final String exercise;
  final double volume;
  final int percentage;

  const _ExerciseVolumeCard({
    required this.exercise,
    required this.volume,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exercise,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${volume.toStringAsFixed(0)} kg',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: AppColors.inputBg,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.success.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$percentage%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
