import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class WorkoutEditPage extends StatefulWidget {
  final Map<String, dynamic> workout;

  const WorkoutEditPage({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutEditPage> createState() => _WorkoutEditPageState();
}

class _WorkoutEditPageState extends State<WorkoutEditPage> {
  late Map<String, dynamic> _editedWorkout;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _editedWorkout = _deepCopyWorkout(widget.workout);
    // Initialize start and end times if they exist
    if (_editedWorkout['startedAt'] != null) {
      final startDateTime = DateTime.parse(_editedWorkout['startedAt'] as String);
      _startTime = TimeOfDay(hour: startDateTime.hour, minute: startDateTime.minute);
    }
    if (_editedWorkout['endedAt'] != null) {
      final endDateTime = DateTime.parse(_editedWorkout['endedAt'] as String);
      _endTime = TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute);
    }
  }

  Map<String, dynamic> _deepCopyWorkout(Map<String, dynamic> original) {
    return {
      ...original,
      'exercises': (original['exercises'] as List<dynamic>?)?.map((ex) {
        return {
          ...ex,
          'sets': (ex['sets'] as List<dynamic>?)?.map((set) {
            return {
              ...set,
              'segments': (set['segments'] as List<dynamic>?)
                  ?.map((seg) {
                    final segMap = seg as Map<dynamic, dynamic>;
                    return <String, dynamic>{...segMap.cast<String, dynamic>()};
                  })
                  .toList() ?? []
            };
          }).toList() ?? []
        };
      }).toList() ?? []
    };
  }

  void _updateSegment(int exIndex, int setIndex, int segIndex,
      String field, dynamic value) {
    setState(() {
      final exercises = _editedWorkout['exercises'] as List<dynamic>;
      final sets = exercises[exIndex]['sets'] as List<dynamic>;
      final segments = sets[setIndex]['segments'] as List<dynamic>;
      segments[segIndex][field] = value;
    });
  }

  void _saveChanges() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final userId = authState.user.id;
    final workoutId = _editedWorkout['id'].toString();

    String? formatDateTime(dynamic dateValue) {
      if (dateValue == null) return null;
      final dt = dateValue is DateTime 
        ? dateValue 
        : DateTime.parse(dateValue.toString());
      return dt.toIso8601String().split('.')[0];
    }

    final workoutDataToSave = <String, dynamic>{
      'planId': _editedWorkout['planId'],
      'workoutDate': formatDateTime(_editedWorkout['workoutDate']),
      'startedAt': formatDateTime(_editedWorkout['startedAt']),
      'endedAt': formatDateTime(_editedWorkout['endedAt']),
    };
    
    final exercisesToSave = <Map<String, dynamic>>[];
    final originalExercises = (_editedWorkout['exercises'] as List<dynamic>?) ?? [];
    
    for (final exercise in originalExercises) {
      final exMap = exercise as Map<dynamic, dynamic>;
      
      final setsToSave = <Map<String, dynamic>>[];
      final originalSets = (exMap['sets'] as List<dynamic>?) ?? [];
      
      for (final set in originalSets) {
        final setMap = set as Map<dynamic, dynamic>;
        final setToSave = <String, dynamic>{
          if (setMap['id'] != null) 'id': setMap['id'],
          'setNumber': setMap['setNumber'] ?? 1,
        };
        
        final segmentsToSave = <Map<String, dynamic>>[];
        final originalSegments = (setMap['segments'] as List<dynamic>?) ?? [];
        
        for (final segment in originalSegments) {
          final segMap = segment as Map<dynamic, dynamic>;
          segmentsToSave.add({
            if (segMap['id'] != null) 'id': segMap['id'],
            'weight': segMap['weight'] ?? 0,
            'repsFrom': segMap['repsFrom'] ?? 0,
            'repsTo': segMap['repsTo'] ?? 0,
            'segmentOrder': segMap['segmentOrder'] ?? 0,
            'notes': segMap['notes'] ?? '',
          });
        }
        
        setToSave['segments'] = segmentsToSave;
        setsToSave.add(setToSave);
      }
      
      exercisesToSave.add({
        if (exMap['id'] != null) 'id': exMap['id'],
        'name': exMap['name'] ?? '',
        'order': exMap['order'] ?? 0,
        'skipped': exMap['skipped'] ?? false,
        'sets': setsToSave,
      });
    }
    
    workoutDataToSave['exercises'] = exercisesToSave;

    context.read<WorkoutBloc>().add(

      WorkoutUpdated(
        userId: userId,
        workoutId: workoutId,
        workoutData: workoutDataToSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutDate = DateTime.parse(_editedWorkout['workoutDate'] as String);
    final exercises = (_editedWorkout['exercises'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Workout'),
        actions: [
          TextButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: BlocListener<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutUpdatedSuccess) {
            AppDialogs.showSuccessDialog(
              context: context,
              title: 'Berhasil',
              message: 'Workout berhasil diupdate.',
              onConfirm: () {
                // Dialog sudah di-close oleh button di AppDialogs
                // Tinggal pop edit page kembali ke detail
                Navigator.pop(context, true);
              },
            );
          } else if (state is WorkoutError) {
            AppDialogs.showErrorDialog(
              context: context,
              title: 'Terjadi Kesalahan',
              message: state.message,
            );
          }
        },
        child: BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, state) {
            if (state is WorkoutLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Container(
                    color: AppColors.cardBg,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(workoutDate),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Workout Time Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
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
                                    'Workout Time',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    'Optional',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: _startTime ?? TimeOfDay.now(),
                                        );
                                        if (time != null) {
                                          setState(() {
                                            _startTime = time;
                                            final baseDate = DateTime.parse(_editedWorkout['workoutDate'] as String);
                                            final updatedTime = baseDate.copyWith(
                                              hour: time.hour,
                                              minute: time.minute,
                                              second: 0,
                                              millisecond: 0,
                                              microsecond: 0,
                                            );
                                            _editedWorkout['startedAt'] = updatedTime.toIso8601String();
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardBg,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.borderDark,
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Start Time',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _startTime?.format(context) ?? 'Not set',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: _startTime == null ? AppColors.textSecondary : AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: _endTime ?? TimeOfDay.now(),
                                        );
                                        if (time != null) {
                                          setState(() {
                                            _endTime = time;
                                            final baseDate = DateTime.parse(_editedWorkout['workoutDate'] as String);
                                            final updatedTime = baseDate.copyWith(
                                              hour: time.hour,
                                              minute: time.minute,
                                              second: 0,
                                              millisecond: 0,
                                              microsecond: 0,
                                            );
                                            _editedWorkout['endedAt'] = updatedTime.toIso8601String();
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardBg,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.borderDark,
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'End Time',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _endTime?.format(context) ?? 'Not set',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: _endTime == null ? AppColors.textSecondary : AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              // Exercises section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${exercises.length} Exercises',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(exercises.length, (exIndex) {
                      final exercise = (exercises[exIndex] as Map<dynamic, dynamic>).cast<String, dynamic>();
                      final sets = (exercise['sets'] as List<dynamic>?) ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight, width: 1),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  exercise['name'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      final currentSkipped = exercise['skipped'] == true;
                                      _editedWorkout['exercises'][exIndex]['skipped'] = !currentSkipped;
                                      
                                      // Jika uncheck skipped dan tidak ada sets, buat set default
                                      if (currentSkipped && sets.isEmpty) {
                                        sets.add({
                                          'setNumber': 1,
                                          'segments': [
                                            {
                                              'weight': 0,
                                              'repsFrom': 1,
                                              'repsTo': 1,
                                              'notes': '',
                                            }
                                          ],
                                        });
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: exercise['skipped'] == true ? AppColors.accent.withValues(alpha: 0.2) : AppColors.inputBg,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: exercise['skipped'] == true ? AppColors.accent : AppColors.borderLight,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          exercise['skipped'] == true ? Icons.check_box : Icons.check_box_outline_blank,
                                          size: 14,
                                          color: exercise['skipped'] == true ? AppColors.accent : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          exercise['skipped'] == true ? 'Skipped' : 'Skip',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: exercise['skipped'] == true ? AppColors.accent : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if ((_editedWorkout['exercises'][exIndex] as Map<dynamic, dynamic>)['skipped'] != true) ...[
                              ...List.generate(sets.length, (setIndex) {
                                final set = (sets[setIndex] as Map<dynamic, dynamic>).cast<String, dynamic>();
                                final segments = (set['segments'] as List<dynamic>?) ?? [];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (setIndex > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                  Row(
                                    children: [
                                      Text('Set ${set['setNumber']}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.accent)),
                                      const SizedBox(width: 8),
                                      if (segments.length > 1)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Drop Set',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...List.generate(segments.length, (segIndex) {
                                    final segment = (segments[segIndex] as Map<dynamic, dynamic>).cast<String, dynamic>();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Expanded(child: _EditField(label: 'Weight', value: segment['weight'], onChanged: (v) => _updateSegment(exIndex, setIndex, segIndex, 'weight', double.tryParse(v) ?? 0))),
                                          const SizedBox(width: 8),
                                          Expanded(child: _EditField(label: 'From', value: segment['repsFrom'], onChanged: (v) => _updateSegment(exIndex, setIndex, segIndex, 'repsFrom', int.tryParse(v) ?? 0))),
                                          const SizedBox(width: 8),
                                          Expanded(child: _EditField(label: 'To', value: segment['repsTo'], onChanged: (v) => _updateSegment(exIndex, setIndex, segIndex, 'repsTo', int.tryParse(v) ?? 0))),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                  _EditField(label: 'Notes (Optional)', value: (segments.isNotEmpty ? segments.first['notes'] ?? '' : ''), onChanged: (v) => _updateSegment(exIndex, setIndex, 0, 'notes', v)),
                                  const SizedBox(height: 12),
                                  if (setIndex == sets.length - 1) ...[
                                    // Last set: show both buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                final newSet = {
                                                  'setNumber': sets.length + 1,
                                                  'segments': [
                                                    {
                                                      'weight': 0,
                                                      'repsFrom': 1,
                                                      'repsTo': 1,
                                                      'notes': '',
                                                    }
                                                  ],
                                                };
                                                sets.add(newSet);
                                              });
                                            },
                                            icon: const Icon(Icons.add, size: 16),
                                            label: const Text('Add Set', style: TextStyle(fontSize: 12)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                final newSegment = {
                                                  'weight': 0,
                                                  'repsFrom': 1,
                                                  'repsTo': 1,
                                                  'notes': '',
                                                };
                                                segments.add(newSegment);
                                              });
                                            },
                                            icon: const Icon(Icons.add, size: 16),
                                            label: const Text('Add Drop Set', style: TextStyle(fontSize: 12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    // Not last set: show only Add Drop Set button
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                final newSegment = {
                                                  'weight': 0,
                                                  'repsFrom': 1,
                                                  'repsTo': 1,
                                                  'notes': '',
                                                };
                                                segments.add(newSegment);
                                              });
                                            },
                                            icon: const Icon(Icons.add, size: 16),
                                            label: const Text('Add Drop Set', style: TextStyle(fontSize: 12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              );
                              }),
                            ] else ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    'Exercise Skipped',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
            );
          },
        ),
      ),
    );
  }
}

class _EditField extends StatefulWidget {
  final String label;
  final dynamic value;
  final Function(String) onChanged;

  const _EditField({required this.label, required this.value, required this.onChanged});

  @override
  State<_EditField> createState() => _EditFieldState();
}

class _EditFieldState extends State<_EditField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(labelText: widget.label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      keyboardType: TextInputType.number,
      onChanged: widget.onChanged,
    );
  }
}
