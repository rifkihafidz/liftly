import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_plan.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../bloc/plan_bloc.dart';
import '../bloc/plan_event.dart';
import '../bloc/plan_state.dart';

import '../../workout_log/repositories/workout_repository.dart';

class _QueueItem {
  final String id;
  final String name;
  _QueueItem(this.name) : id = UniqueKey().toString();
}

class CreatePlanPage extends StatefulWidget {
  final WorkoutPlan? plan;

  const CreatePlanPage({super.key, this.plan});

  @override
  State<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final _focusNode = FocusNode();
  final List<_QueueItem> _exercises = [];
  final List<String> _availableExercises = [];
  final _workoutRepository = WorkoutRepository();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.plan?.description ?? '',
    );

    if (widget.plan != null) {
      _exercises.addAll(widget.plan!.exercises.map((e) => _QueueItem(e.name)));
    }

    context.read<PlanBloc>().add(const PlansFetchRequested(userId: '1'));
    _loadAvailableExercises();
  }

  Future<void> _loadAvailableExercises() async {
    final names = <String>{};
    final planState = context.read<PlanBloc>().state;
    if (planState is PlansLoaded) {
      for (var plan in planState.plans) {
        for (var ex in plan.exercises) {
          names.add(ex.name);
        }
      }
    }
    try {
      final workouts = await _workoutRepository.getWorkouts(userId: '1');
      for (var w in workouts) {
        for (var e in w.exercises) {
          names.add(e.name);
        }
      }
    } catch (e, stackTrace) {
      log(
        'Error loading suggestions',
        name: 'CreatePlanPage',
        error: e,
        stackTrace: stackTrace,
      );
    }

    if (mounted) {
      setState(() {
        _availableExercises.clear();
        _availableExercises.addAll(names.toList()..sort());
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addExercise(String name) {
    if (name.isNotEmpty) {
      setState(() {
        _exercises.add(_QueueItem(name));
      });
    }
  }

  void _editExercise(int index, String newName) {
    if (newName.isNotEmpty) {
      setState(() {
        // Replace item but keep ID if possible, or new ID is fine
        // Using distinct ID for new content is generally safer for keys
        _exercises[index] = _QueueItem(newName);
      });
    }
  }

  Future<void> _showExerciseDialog({int? index, String? initialValue}) async {
    // Ensure suggestions are loaded
    if (_availableExercises.isEmpty) {
      await _loadAvailableExercises();
    }

    if (!mounted) return;

    AppDialogs.showExerciseEntryDialog(
      context: context,
      title: index != null ? 'Edit Exercise' : 'Add Exercise',
      initialValue: initialValue,
      hintText: 'Exercise Name (e.g. Bench Press)',
      suggestions: _availableExercises,
      onConfirm: (name) {
        if (index != null) {
          _editExercise(index, name);
        } else {
          _addExercise(name);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.darkBg,
      body: BlocListener<PlanBloc, PlanState>(
        listener: (context, state) {
          if (state is PlanSuccess) {
            AppDialogs.showSuccessDialog(
              context: context,
              title: 'Success',
              message: state.message,
              onConfirm: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            );
          }
          if (state is PlanError) {
            AppDialogs.showErrorDialog(
              context: context,
              title: 'Error Occurred',
              message: state.message,
            );
          }
          if (state is PlansLoaded) {
            _loadAvailableExercises();
          }
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Text(
                    widget.plan == null ? 'Create Plan' : 'Edit Plan',
                  ),
                  // centerTitle override removed
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Plan Name'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: 'e.g., Push/Pull/Legs',
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Description (optional)'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _descriptionController,
                          hint: 'e.g., 3-day strength program',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLabel('Exercises'),
                            if (_exercises.isNotEmpty)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _exercises.clear()),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                ),
                                child: const Text('Clear All'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_exercises.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.cardBg.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    AppColors.borderDark.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fitness_center_outlined,
                                  size: 40,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No exercises added yet',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _exercises.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (oldIndex < newIndex) newIndex -= 1;
                                final item = _exercises.removeAt(oldIndex);
                                _exercises.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final exercise = _exercises[index];
                              return Container(
                                key: ValueKey(exercise.id),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.drag_handle_rounded,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              exercise.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => _showExerciseDialog(
                                            index: index,
                                            initialValue: exercise.name,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Icon(
                                              Icons.edit_rounded,
                                              size: 18,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => setState(
                                            () => _exercises.removeAt(index),
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 20,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showExerciseDialog(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Exercise'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: BlocBuilder<PlanBloc, PlanState>(
                            builder: (context, state) {
                              final isLoading = state is PlanLoading;
                              return FilledButton(
                                onPressed: isLoading ? null : _savePlan,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        widget.plan == null
                                            ? 'Create Plan'
                                            : 'Update Plan',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  void _savePlan() {
    if (_exercises.isNotEmpty && _nameController.text.isEmpty) {
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Plan Name Required',
        message: 'Please enter a plan name first.',
      );
      return;
    }

    if (_nameController.text.isEmpty) {
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Plan Name Required',
        message: 'Please enter a plan name.',
      );
      return;
    }

    if (_exercises.isEmpty) {
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Exercises Required',
        message: 'Please add at least one exercise.',
      );
      return;
    }

    final event = widget.plan == null
        ? PlanCreated(
            userId: '1',
            name: _nameController.text,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
            exercises: _exercises.map((e) => e.name).toList(),
          )
        : PlanUpdated(
            userId: '1',
            planId: widget.plan!.id,
            name: _nameController.text,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
            exercises: _exercises.map((e) => e.name).toList(),
          );

    context.read<PlanBloc>().add(event);
  }
}
