import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/workout_plan.dart';
import '../bloc/plan_bloc.dart';
import '../bloc/plan_event.dart';
import '../bloc/plan_state.dart';

class CreatePlanPage extends StatefulWidget {
  final WorkoutPlan? plan;

  const CreatePlanPage({super.key, this.plan});

  @override
  State<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<TextEditingController> _exerciseControllers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name ?? '');
    _descriptionController = TextEditingController(text: widget.plan?.description ?? '');
    _exerciseControllers = (widget.plan?.exercises ?? [])
        .map((e) => TextEditingController(text: e.name))
        .toList();

    if (_exerciseControllers.isEmpty) {
      _exerciseControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (var controller in _exerciseControllers) {
      controller.dispose();
    }
    super.dispose();
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
            Navigator.pop(context);
          }
          if (state is PlanError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
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
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _exerciseControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _exerciseControllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.borderDark,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _exerciseControllers[index],
                                    decoration: InputDecoration(
                                      hintText: 'Exercise ${index + 1}',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_exerciseControllers.length > 1)
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _exerciseControllers[index].dispose();
                                        _exerciseControllers.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(Icons.delete),
                                    color: AppColors.error,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minHeight: 40),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
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
                            : Text(widget.plan == null ? 'Create Plan' : 'Update Plan'),
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
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan name is required')),
      );
      return;
    }

    if (_exerciseControllers.every((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    final exercises = <String>[];
    for (var i = 0; i < _exerciseControllers.length; i++) {
      if (_exerciseControllers[i].text.isNotEmpty) {
        exercises.add(_exerciseControllers[i].text);
      }
    }

    if (widget.plan == null) {
      context.read<PlanBloc>().add(
        PlanCreated(
          name: _nameController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          exercises: exercises,
        ),
      );
    } else {
      context.read<PlanBloc>().add(
        PlanUpdated(
          planId: widget.plan!.id,
          name: _nameController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          exercises: exercises,
        ),
      );
    }
  }
}
