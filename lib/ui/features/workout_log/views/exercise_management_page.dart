import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liftly/core/constants/app_constants.dart';
import 'package:liftly/core/constants/colors.dart';
import 'package:liftly/ui/core/shared/widgets/app_dialogs.dart';
import 'package:liftly/ui/features/workout_log/bloc/workout_bloc.dart';
import 'package:liftly/ui/features/workout_log/bloc/workout_event.dart';
import 'package:liftly/data/repositories/workout_repository.dart';
import 'package:liftly/ui/features/stats/bloc/stats_bloc.dart';
import 'package:liftly/ui/features/stats/bloc/stats_event.dart';

class ExerciseManagementPage extends StatefulWidget {
  const ExerciseManagementPage({super.key});

  @override
  State<ExerciseManagementPage> createState() => _ExerciseManagementPageState();
}

class _ExerciseManagementPageState extends State<ExerciseManagementPage> {
  final _workoutRepository = WorkoutRepository();
  bool _isLoading = true;
  List<Map<String, String>> _exercises = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    
    try {
      const userId = AppConstants.defaultUserId;
      final names = await _workoutRepository.getExerciseNames(userId: userId);
      
      final List<Map<String, String>> result = [];
      
      for (final name in names) {
        final variations = await _workoutRepository.getExerciseVariations(
          userId: userId,
          exerciseName: name,
        );
        
        if (variations.isEmpty) {
          result.add({'name': name, 'variation': ''});
        } else {
          for (final variation in variations) {
            result.add({'name': name, 'variation': variation});
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _exercises = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await AppDialogs.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Failed to load exercises: $e',
        );
      }
    }
  }

  String _searchQuery = '';

  List<Map<String, String>> get _filteredExercises {
    if (_searchQuery.isEmpty) return _exercises;
    final query = _searchQuery.toLowerCase();
    return _exercises.where((ex) {
      final name = (ex['name'] ?? '').toLowerCase();
      final variation = (ex['variation'] ?? '').toLowerCase();
      return name.contains(query) || variation.contains(query);
    }).toList();
  }

  void _showEditDialog(Map<String, String> exercise) {
    final oldName = exercise['name']!;
    final oldVariation = exercise['variation']!;

    // Get unique exercise names for suggestions
    final suggestions = _exercises.map((e) => e['name']!).toSet().toList();

    AppDialogs.showExerciseEntryDialog(
      context: context,
      title: 'Edit Exercise',
      caption: 'This will update the exercise name and variation across all your past workouts and plans.',
      initialValue: oldName,
      initialVariation: oldVariation,
      hintText: 'Exercise Name',
      suggestions: suggestions,
      onConfirm: (newName, newVariation) async {
        if (newName == oldName && newVariation == oldVariation) return;

        // Check if renaming onto an existing exercise (merge scenario)
        final isMerge = _exercises.any((e) =>
            e['name']!.toLowerCase() == newName.toLowerCase() &&
            e['variation']!.toLowerCase() == newVariation.toLowerCase() &&
            !(e['name'] == oldName && e['variation'] == oldVariation));

        final label = '$newName${newVariation.isNotEmpty ? ' ($newVariation)' : ''}';
        final confirmed = await AppDialogs.showConfirmationDialog(
          context: context,
          title: isMerge ? 'Merge Exercise?' : 'Rename Exercise?',
          message: isMerge
              ? '"$label" already exists. Renaming will merge all history of "$oldName${oldVariation.isNotEmpty ? ' ($oldVariation)' : ''}" into "$label". This cannot be undone.'
              : 'Rename "$oldName${oldVariation.isNotEmpty ? ' ($oldVariation)' : ''}" to "$label" across all workouts and plans?',
          confirmText: isMerge ? 'Merge' : 'Rename',
          isDangerous: isMerge,
        );

        if (confirmed != true || !mounted) return;

        AppDialogs.showLoadingDialog(context, 'Updating exercises...');
        try {
          // Await directly so _loadExercises sees fresh data
          await _workoutRepository.batchUpdateExerciseNameAndVariation(
            userId: AppConstants.defaultUserId,
            oldName: oldName,
            oldVariation: oldVariation,
            newName: newName,
            newVariation: newVariation,
          );

          if (!mounted) return;
          AppDialogs.hideLoadingDialog(context);

          // Also dispatch to Bloc to invalidate caches used by Stats/History
          context.read<WorkoutBloc>().add(
            WorkoutBatchEdited(
              userId: AppConstants.defaultUserId,
              oldName: oldName,
              oldVariation: oldVariation,
              newName: newName,
              newVariation: newVariation,
            ),
          );
          context.read<StatsBloc>().add(
            const StatsFetched(),
          );

          // Start reloading exercises in background
          unawaited(_loadExercises());

          await AppDialogs.showSuccessDialog(
            context: context,
            title: 'Update Successful',
            message: 'Exercise updated to "$label".',
          );
        } catch (e) {
          if (!mounted) return;
          AppDialogs.hideLoadingDialog(context);
          await AppDialogs.showErrorDialog(
            context: context,
            title: 'Update Failed',
            message: e.toString(),
          );
        }
      },
    );
  }

  /// Builds a flat list of alternating alphabet-header tiles and exercise tiles.
  Widget _buildExerciseList(List<Map<String, String>> exercises) {
    // Each element is either {'type': 'header', 'letter': 'A'}
    // or {'type': 'exercise', ...exercise data...}
    final List<Map<String, dynamic>> items = [];
    String? lastLetter;

    for (final ex in exercises) {
      final name = ex['name'] ?? '';
      final firstChar = name.isNotEmpty ? name[0].toUpperCase() : '#';
      final letter = RegExp(r'[A-Z]').hasMatch(firstChar) ? firstChar : '#';

      if (letter != lastLetter) {
        items.add({'type': 'header', 'letter': letter});
        lastLetter = letter;
      }
      items.add({'type': 'exercise', ...ex});
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item['type'] == 'header') {
          final letter = item['letter'] as String;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Divider(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    thickness: 1,
                    height: 1,
                  ),
                ),
              ],
            ),
          );
        }

        final name = item['name'] as String? ?? '';
        final variation = item['variation'] as String? ?? '';
        final hasVariation = variation.isNotEmpty;
        final ex = {'name': name, 'variation': variation};

        return ListTile(
          title: Text(
            name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: hasVariation
              ? Text(
                  variation,
                  style: const TextStyle(color: AppColors.accent),
                )
              : null,
          trailing: const Icon(
            Icons.edit_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onTap: () => _showEditDialog(ex),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExercises;
    
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Exercise Management'),
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                debugPrint('--- All Exercises & Variations ---');
                for (final ex in _exercises) {
                  debugPrint('${ex['name']} - ${ex['variation']}');
                }
                debugPrint('----------------------------------');
              },
              tooltip: 'Print all exercises to console',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search exercise...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'No exercises found.' : 'No exercises match your search.',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : _buildExerciseList(filtered),
          ),
        ],
      ),
    );
  }
}
