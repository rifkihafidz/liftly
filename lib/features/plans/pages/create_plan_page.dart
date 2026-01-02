import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_plan.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../bloc/plan_bloc.dart';
import '../bloc/plan_event.dart';
import '../bloc/plan_state.dart';

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
        _exercises.add(_QueueItem(text));
        _newExerciseController.clear();
        _isAddingExercise = false;
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
  }

  void _cancelAddingExercise() {
    setState(() {
      _isAddingExercise = false;
      _newExerciseController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void _editExercise(int index) {
    setState(() {
      final exerciseToEdit = _exercises[index];
      _exercises.removeAt(index);
      _newExerciseController.text = exerciseToEdit.name;
      _isAddingExercise = true;
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan == null ? 'Create Plan' : 'Edit Plan'),
      ),
      body: BlocListener<PlanBloc, PlanState>(
        listener: (context, state) {
          if (state is PlanSuccess) {
            AppDialogs.showSuccessDialog(
              context: context,
              title: 'Success',
              message: state.message,
              onConfirm: () {
                // Close dialog
                Navigator.pop(context);
                // Pop create page to go back to plans list
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
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Name',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Push/Pull/Legs',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Description (optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., 3-day strength program',
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercises',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_exercises.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _exercises.clear();
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Added Exercises List
                if (_exercises.isNotEmpty)
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _exercises.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
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
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.drag_handle,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  exercise.name,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _editExercise(index),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _exercises.removeAt(index);
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.close,
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

                // Input Field (visible when adding)
                if (_isAddingExercise) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _newExerciseController,
                      builder: (context, value, child) {
                        final isEnabled = value.text.trim().isNotEmpty;
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newExerciseController,
                                focusNode: _focusNode,
                                autofocus: true,
                                textInputAction: TextInputAction.done,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Enter exercise name...',
                                  hintStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) {
                                  if (isEnabled) _submitExercise();
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: isEnabled ? _submitExercise : null,
                              icon: const Icon(Icons.check),
                              color: isEnabled
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              tooltip: 'Add',
                            ),
                            IconButton(
                              onPressed: _cancelAddingExercise,
                              icon: const Icon(Icons.close),
                              color: AppColors.error,
                              tooltip: 'Cancel',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                // Add Button (Always visible)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isAddingExercise
                        ? null // Disable if already adding
                        : () {
                            setState(() {
                              _isAddingExercise = true;
                            });
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercise'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(
                        color: _isAddingExercise
                            ? AppColors.borderLight.withValues(alpha: 0.3)
                            : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<PlanBloc, PlanState>(
                    builder: (context, state) {
                      final isLoading = state is PlanLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _savePlan,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                widget.plan == null
                                    ? 'Create Plan'
                                    : 'Update Plan',
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
      ),
    );
  }

  void _savePlan() {
    // Collect non-empty exercises
    // Exercises are already in _exercises list

    // Check if exercises exist but no plan name
    if (_exercises.isNotEmpty && _nameController.text.isEmpty) {
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Plan Name Required',
        message:
            'Please enter a plan name first. Exercises have been added but the plan name is still empty.',
      );
      return;
    }

    // Check if no name and no exercises
    if (_nameController.text.isEmpty) {
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Plan Name Required',
        message: 'Please enter a plan name.',
      );
      return;
    }

    // Check if exercises are empty
    if (_exercises.isEmpty) {
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Exercises Required',
        message: 'Please add at least one exercise.',
      );
      return;
    }

    if (widget.plan == null) {
      context.read<PlanBloc>().add(
        PlanCreated(
          userId: '1',
          name: _nameController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          exercises: _exercises.map((e) => e.name).toList(),
        ),
      );
    } else {
      context.read<PlanBloc>().add(
        PlanUpdated(
          userId: '1',
          planId: widget.plan!.id,
          name: _nameController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          exercises: _exercises.map((e) => e.name).toList(),
        ),
      );
    }
  }
}
