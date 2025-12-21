import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_session.dart';
import 'workout_detail_page.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
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
                    weight: 80,
                    repsFrom: 6,
                    repsTo: 8,
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
                    weight: 100,
                    repsFrom: 10,
                    repsTo: 12,
                    segmentOrder: 0,
                  ),
                  SetSegment(
                    id: 'seg_7',
                    weight: 80,
                    repsFrom: 12,
                    repsTo: 15,
                    segmentOrder: 1,
                  ),
                ],
              ),
            ],
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
      ),
      body: _sessions.isEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No workouts yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start logging your workouts to build your history',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutDetailPage(
                            session: session,
                            onSessionUpdated: (updatedSession) {
                              setState(() {
                                _sessions[index] = updatedSession;
                              });
                            },
                            onSessionDeleted: () {
                              setState(() {
                                _sessions.removeAt(index);
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent.withValues(alpha: 0.08),
                            AppColors.accent.withValues(alpha: 0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMM d, yyyy').format(session.workoutDate),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (session.startedAt != null && session.endedAt != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${DateFormat('HH:mm').format(session.startedAt!)} - ${DateFormat('HH:mm').format(session.endedAt!)} • ${_formatDuration(session.duration!)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.accent.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.accent.withValues(alpha: 0.5),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.25),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  '${session.exercises.length} Exercises',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.success.withValues(alpha: 0.25),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  '${session.exercises.fold<int>(0, (sum, ex) => sum + ex.sets.length)} Sets',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
