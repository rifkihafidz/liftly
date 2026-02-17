import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_plan.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../bloc/plan_bloc.dart';
import '../bloc/plan_event.dart';
import '../bloc/plan_state.dart';

import '../../../shared/widgets/suggestion_text_field.dart';
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
  late TextEditingController _newExerciseController;
  final _focusNode = FocusNode();
  final List<_QueueItem> _exercises = [];
  bool _isAddingExercise = false;
  final List<String> _availableExercises = [];
  final _workoutRepository = WorkoutRepository();
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.plan?.description ?? '',
    );
    _newExerciseController = TextEditingController();

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
    _newExerciseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitExercise() {
    final text = _newExerciseController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        if (_editingIndex != null) {
          // Update existing item in-place
          final newItem = _QueueItem(text);
          // We replace the item in the list at the same index
          // Note: using a new ID is generally safer for key uniqueness if content changes substantially,
          // but if we want to preserve identity we could pass the ID.
          // For now, let's treat it as a new item content-wise but kept in same slot.
          _exercises[_editingIndex!] = newItem;

          _editingIndex = null;
          _editingIndex = null;
        } else {
          // Add new item at end
          _exercises.add(_QueueItem(text));
        }
        _newExerciseController.clear();
        _isAddingExercise = false;
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
  }

  void _cancelAddingExercise() {
    setState(() {
      // Just clear edit state, no need to re-insert as we never removed it
      _editingIndex = null;
      _editingIndex = null;
      _isAddingExercise = false;
      _newExerciseController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void _editExercise(int index) {
    setState(() {
      _editingIndex = index;
      _editingIndex = index;
      // Do NOT remove the item. We render the edit form AT this index.
      // _exercises.removeAt(index);

      _newExerciseController.text = _exercises[index].name;
      // We are NOT "adding" a new exercise at the bottom, so set this false
      _isAddingExercise = false;

      // Use a post-frame callback or slight delay to ensure the UI has updated
      // before requesting focus.
      Future.delayed(const Duration(milliseconds: 50), () {
        _focusNode.requestFocus();
      });
    });
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
                  centerTitle: false,
                  backgroundColor: AppColors.darkBg,
                  surfaceTintColor: AppColors.darkBg,
                  title: Text(
                    widget.plan == null ? 'Create Plan' : 'Edit Plan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  leading: IconButton(
                    // Explicit leading to match StartWorkoutPage style if desired, or default back
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

                        if (_exercises.isNotEmpty)
                          ReorderableListView.builder(
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
                              // Check if this item is being edited
                              if (_editingIndex == index) {
                                return Container(
                                  key: ValueKey('editing_${exercise.id}'),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.accent),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SuggestionTextField(
                                          controller: _newExerciseController,
                                          focusNode: _focusNode,
                                          hintText: 'Exercise name...',
                                          suggestions: _availableExercises,
                                          onSubmitted: (_) => _submitExercise(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.filled(
                                        onPressed: _submitExercise,
                                        icon: const Icon(Icons.check_rounded),
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _cancelAddingExercise,
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

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
                                          onTap: () => _editExercise(index),
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

                        // Make sure we only show the "Add New" input if we are NOT editing an item
                        if (_editingIndex == null && _isAddingExercise) ...[
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.accent),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SuggestionTextField(
                                    controller: _newExerciseController,
                                    focusNode: _focusNode,
                                    hintText: 'Exercise name...',
                                    suggestions: _availableExercises,
                                    onSubmitted: (_) => _submitExercise(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: _submitExercise,
                                  icon: const Icon(Icons.check_rounded),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _cancelAddingExercise,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                (_isAddingExercise || _editingIndex != null)
                                    ? null
                                    : () {
                                        setState(() {
                                          _isAddingExercise = true;
                                          // Delay to ensure widget is built
                                          Future.delayed(
                                            const Duration(milliseconds: 100),
                                            () {
                                              _focusNode.requestFocus();
                                            },
                                          );
                                        });
                                      },
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
