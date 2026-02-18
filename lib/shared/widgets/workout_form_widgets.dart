import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import 'package:intl/intl.dart';

// Reusable datetime dialog untuk session/workout form
class WorkoutDateTimeDialog extends StatefulWidget {
  final DateTime initialWorkoutDate;
  final DateTime? initialStartedAt;
  final DateTime? initialEndedAt;

  const WorkoutDateTimeDialog({
    super.key,
    required this.initialWorkoutDate,
    required this.initialStartedAt,
    required this.initialEndedAt,
  });

  @override
  State<WorkoutDateTimeDialog> createState() => _WorkoutDateTimeDialogState();
}

class _WorkoutDateTimeDialogState extends State<WorkoutDateTimeDialog> {
  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy').format(date);
  }

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialWorkoutDate;
    startTime = widget.initialStartedAt != null
        ? TimeOfDay.fromDateTime(widget.initialStartedAt!)
        : TimeOfDay.now();
    final endDateTime = DateTime.now().add(const Duration(hours: 1));
    endTime = widget.initialEndedAt != null
        ? TimeOfDay.fromDateTime(widget.initialEndedAt!)
        : TimeOfDay.fromDateTime(endDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.cardBg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.borderLight.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardBg,
                AppColors.cardBg.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.event_repeat_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Workout Timing',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date Picker Section
              _buildPickerSection(
                context,
                label: 'Workout Date',
                value: _formatDate(selectedDate),
                icon: Icons.calendar_month_rounded,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Time Row
              Row(
                children: [
                  Expanded(
                    child: _buildPickerSection(
                      context,
                      label: 'Started At',
                      value: DateFormat('HH:mm').format(DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        startTime.hour,
                        startTime.minute,
                      )),
                      icon: Icons.play_circle_outline_rounded,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                alwaysUse24HourFormat: true,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => startTime = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerSection(
                      context,
                      label: 'Ended At',
                      value: DateFormat('HH:mm').format(DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        endTime.hour,
                        endTime.minute,
                      )),
                      icon: Icons.stop_circle_outlined,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                alwaysUse24HourFormat: true,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => endTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final start = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          startTime.hour,
                          startTime.minute,
                        );
                        var end = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          endTime.hour,
                          endTime.minute,
                        );

                        // Handle cross-midnight workouts: if end is before start, add 1 day
                        if (end.isBefore(start)) {
                          end = end.add(const Duration(days: 1));
                        }

                        Navigator.pop(context, {
                          'workoutDate': selectedDate,
                          'startedAt': start,
                          'endedAt': end,
                        });
                      },
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerSection(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 20, color: AppColors.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable weight field
class WeightField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final EdgeInsets scrollPadding;

  const WeightField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.scrollPadding = const EdgeInsets.only(bottom: 48),
  });

  @override
  State<WeightField> createState() => WeightFieldState();
}

class WeightFieldState extends State<WeightField> {
  late TextEditingController controller;
  late FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    } else {
      // Flush changes immediately on focus loss
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _flushValue();
    }
  }

  void _flushValue() {
    final text = controller.text;
    if (text.isEmpty || text == '.') {
      widget.onChanged('0');
      controller.text = '0'; // Instant feedback
    } else {
      // Optimistic formatting
      // Replace comma with dot for iOS keyboard compatibility
      final normalizedText = text.replaceAll(',', '.');
      final val = double.tryParse(normalizedText);
      if (val != null) {
        // Standardize to double string (e.g. "50.0") if integer, to match BLoC
        final formatted = val.toString();

        // Update local controller immediately to avoid jump later
        if (text != formatted) {
          controller.text = formatted;
        }
        widget.onChanged(formatted);
      } else {
        widget.onChanged(text);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WeightField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != controller.text) {
      if (!_focusNode.hasFocus) {
        // Only update if value is mathematically different to avoid jumping
        // e.g. "50" vs "50.0"
        final d1 =
            double.tryParse(widget.initialValue.replaceAll(',', '.')) ?? 0;
        final d2 = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
        if ((d1 - d2).abs() > 0.001) {
          controller.text = widget.initialValue;
        }
      }
    }
  }

  static final _decoration = InputDecoration(
    hintText: '50',
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight (kg)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          focusNode: _focusNode,
          scrollPadding: widget.scrollPadding,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            DecimalInputFormatter(),
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (v) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              widget.onChanged(v.isEmpty || v == '.' || v == ','
                  ? '0'
                  : v.replaceAll(',', '.'));
            });
          },
          onSubmitted: (_) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _flushValue();
          },
          decoration: _decoration,
        ),
      ],
    );
  }
}

// Reusable number field
class NumberField extends StatefulWidget {
  final String label;
  final String initialValue;
  final Function(String) onChanged;
  final bool hasError;
  final EdgeInsets scrollPadding;

  const NumberField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hasError = false,
    this.scrollPadding = const EdgeInsets.only(bottom: 48),
  });

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late TextEditingController controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    } else {
      _flushValue();
    }
  }

  void _flushValue() {
    final text = controller.text;
    widget.onChanged(text.isEmpty ? '0' : text);
  }

  @override
  void dispose() {
    controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != controller.text) {
      if (!_focusNode.hasFocus) {
        controller.text = widget.initialValue;
      }
    }
  }

  InputDecoration get _decoration {
    final baseColor = widget.hasError
        ? AppColors.error
        : AppColors.borderLight.withValues(alpha: 0.5);

    return InputDecoration(
      hintText: widget.label == 'From' ? '6' : '8',
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: baseColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: widget.hasError ? AppColors.error : AppColors.accent,
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          focusNode: _focusNode,
          scrollPadding: widget.scrollPadding,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          onChanged: (v) {
            widget.onChanged(v.isEmpty ? '0' : v);
          },
          onSubmitted: (_) {
            _flushValue();
          },
          decoration: _decoration,
        ),
      ],
    );
  }
}

// Reusable to field with delete button
class ToField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final VoidCallback? onDeleteTap;
  final bool hasError;
  final EdgeInsets scrollPadding;

  const ToField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.onDeleteTap,
    this.hasError = false,
    this.scrollPadding = const EdgeInsets.only(bottom: 48),
  });

  @override
  State<ToField> createState() => _ToFieldState();
}

class _ToFieldState extends State<ToField> {
  late TextEditingController controller;
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
    focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (focusNode.hasFocus) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    } else {
      _flushValue();
    }
  }

  void _flushValue() {
    final text = controller.text;
    widget.onChanged(text.isEmpty ? '0' : text);
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.removeListener(_handleFocusChange);
    focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ToField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != controller.text) {
      if (!focusNode.hasFocus) {
        controller.text = widget.initialValue;
      }
    }
  }

  InputDecoration get _decoration {
    final baseColor = widget.hasError
        ? AppColors.error
        : AppColors.borderLight.withValues(alpha: 0.5);

    return InputDecoration(
      hintText: '8',
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: baseColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: widget.hasError ? AppColors.error : AppColors.accent,
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'To',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (widget.onDeleteTap != null)
              GestureDetector(
                onTap: widget.onDeleteTap,
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          focusNode: focusNode,
          scrollPadding: widget.scrollPadding,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          onChanged: (v) {
            widget.onChanged(v.isEmpty ? '0' : v);
          },
          onSubmitted: (_) {
            _flushValue();
          },
          decoration: _decoration,
        ),
      ],
    );
  }
}

// Reusable notes field
class NotesField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final EdgeInsets scrollPadding;

  const NotesField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.scrollPadding = const EdgeInsets.only(bottom: 60),
  });

  @override
  State<NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<NotesField> {
  late TextEditingController controller;
  late FocusNode focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
    focusNode = FocusNode();
    focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!focusNode.hasFocus) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      widget.onChanged(controller.text);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    controller.dispose();
    focusNode.removeListener(_handleFocusChange);
    focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != controller.text) {
      if (!focusNode.hasFocus) {
        controller.text = widget.initialValue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          focusNode: focusNode,
          scrollPadding: widget.scrollPadding,
          maxLines: 2,
          onChanged: (v) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              widget.onChanged(v);
            });
          },
          decoration: InputDecoration(
            hintText: 'Wide grip, feels good, etc.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}

// Reusable datetime input field
class DateTimeInput extends StatelessWidget {
  final String label;
  final DateTime? dateTime;
  final VoidCallback onTap;

  const DateTimeInput({
    super.key,
    required this.label,
    required this.dateTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        dateTime != null ? DateFormat('HH:mm').format(dateTime!) : '--:--';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              formattedTime,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Workout Date/Time Card
class WorkoutDateTimeCard extends StatelessWidget {
  final DateTime workoutDate;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final VoidCallback onTap;

  const WorkoutDateTimeCard({
    super.key,
    required this.workoutDate,
    required this.startedAt,
    required this.endedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Format Date
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(workoutDate);

    // Format Time Range
    String timeRange = 'Set Time';
    if (startedAt != null && endedAt != null) {
      final startStr = DateFormat('HH:mm').format(startedAt!);
      final endStr = DateFormat('HH:mm').format(endedAt!);
      timeRange = '$startStr - $endStr';
    } else if (startedAt != null) {
      final startStr = DateFormat('HH:mm').format(startedAt!);
      timeRange = '$startStr - ?';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeRange,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A formatter that allows only one decimal separator (dot or comma)
class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // 1. Block consecutive separators (e.g., .., ,, ,. .,)
    if (newValue.text.contains('..') ||
        newValue.text.contains(',,') ||
        newValue.text.contains('.,') ||
        newValue.text.contains(',.')) {
      return oldValue;
    }

    // 2. Count total separators
    final dotCount = newValue.text.split('.').length - 1;
    final commaCount = newValue.text.split(',').length - 1;

    // 3. Block if more than one total separator exists in the string
    if (dotCount + commaCount > 1) {
      return oldValue;
    }

    return newValue;
  }
}
