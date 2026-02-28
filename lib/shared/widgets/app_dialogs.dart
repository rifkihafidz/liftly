import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../features/workout_log/repositories/workout_repository.dart';
import 'suggestion_text_field.dart';

class AppDialogs {
  /// Show success dialog
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      onConfirm?.call();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm?.call();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (isDangerous ? AppColors.error : AppColors.warning)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDangerous ? Icons.delete_outline : Icons.help_outline,
                    color: isDangerous ? AppColors.error : AppColors.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(cancelText),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            isDangerous ? AppColors.error : AppColors.accent,
                      ),
                      child: Text(confirmText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show unsaved changes confirmation dialog
  static Future<bool?> showUnsavedChangesDialog({
    required BuildContext context,
  }) async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unsaved Changes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'You have unsaved changes. Are you sure you want to discard them?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show text input dialog
  static Future<void> showTextInputDialog({
    required BuildContext context,
    required String title,
    String? initialValue,
    String? hint,
    List<String>? suggestions,
    required Function(String) onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: _TextInputDialog(
          title: title,
          initialValue: initialValue,
          hint: hint,
          suggestions: suggestions,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  /// Show exercise entry dialog
  static void showExerciseEntryDialog({
    required BuildContext context,
    required String title,
    required String userId,
    String? initialValue,
    String? initialVariation,
    String? hintText,
    required List<String> suggestions,
    required Function(String name, String variation) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => _ExerciseEntryDialog(
        title: title,
        userId: userId,
        initialValue: initialValue,
        initialVariation: initialVariation,
        hintText: hintText,
        suggestions: suggestions,
        onConfirm: onConfirm,
      ),
    );
  }

  /// Show a non-dismissible loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.accent),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show a non-dismissible progress dialog with a linear progress bar.
  /// Use [ValueNotifier] for [progress] (0.0–1.0) and [status] text.
  static void showProgressDialog(
    BuildContext context, {
    required String title,
    required ValueListenable<double> progress,
    required ValueListenable<String> status,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: status,
                builder: (_, s, __) => Text(
                  s,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.darkBg,
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Close any open dialog (like the loading one)
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class _ExerciseEntryDialog extends StatefulWidget {
  final String title;
  final String userId;
  final String? initialValue;
  final String? initialVariation;
  final String? hintText;
  final List<String> suggestions;
  final Function(String name, String variation) onConfirm;

  const _ExerciseEntryDialog({
    required this.title,
    required this.userId,
    this.initialValue,
    this.initialVariation,
    this.hintText,
    required this.suggestions,
    required this.onConfirm,
  });

  @override
  State<_ExerciseEntryDialog> createState() => _ExerciseEntryDialogState();
}

class _ExerciseEntryDialogState extends State<_ExerciseEntryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _variationController;
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  List<String> _variationSuggestions = [];
  String? _errorText;
  bool _isLoadingVariations = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialValue);
    _variationController = TextEditingController(text: widget.initialVariation);

    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _loadVariations(widget.initialValue!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _variationController.dispose();
    super.dispose();
  }

  Future<void> _loadVariations(String exerciseName) async {
    if (exerciseName.isEmpty) {
      setState(() {
        _variationSuggestions = [];
      });
      return;
    }

    setState(() => _isLoadingVariations = true);
    try {
      final vars = await _workoutRepository.getExerciseVariations(
        userId: widget.userId,
        exerciseName: exerciseName,
      );
      if (mounted) {
        setState(() {
          _variationSuggestions = vars;
          _isLoadingVariations = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVariations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(
        widget.title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Name Field
            _buildInputWrapper(
              child: SuggestionTextField(
                controller: _nameController,
                hintText: widget.hintText ?? 'Exercise Name',
                suggestions: widget.suggestions,
                onChanged: (val) {
                  if (_errorText != null) setState(() => _errorText = null);
                  _loadVariations(val.trim());
                },
                onSubmitted: (val) {
                  _loadVariations(val.trim());
                },
              ),
              errorText: _errorText,
            ),
            const SizedBox(height: 16),

            // Variation Field
            _buildInputWrapper(
              child: SuggestionTextField(
                controller: _variationController,
                hintText: 'Variation (Optional, ex: Close Grip)',
                suggestions: _variationSuggestions,
                enabled: _nameController.text.trim().isNotEmpty,
                onSubmitted: (_) {
                  _handleConfirm();
                },
              ),
            ),
            if (_isLoadingVariations)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _handleConfirm,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(widget.initialValue != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildInputWrapper({
    required Widget child,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(16),
            border: errorText != null
                ? Border.all(color: AppColors.error, width: 1)
                : null,
          ),
          child: child,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _handleConfirm() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      widget.onConfirm(name, _variationController.text.trim());
      Navigator.pop(context);
    } else {
      setState(() {
        _errorText = 'Exercise name cannot be empty';
      });
    }
  }
}

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String? hint;
  final List<String>? suggestions;
  final Function(String) onConfirm;

  const _TextInputDialog({
    required this.title,
    this.initialValue,
    this.hint,
    this.suggestions,
    required this.onConfirm,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    // Show all suggestions initially if textfield is empty or just has initial value
    _controller.addListener(_updateSuggestions);
  }

  void _updateSuggestions() {
    if (widget.suggestions == null) return;
    setState(() {
      // Logic for updating suggestions is handled by SuggestionTextField internally
      // or by parent if needed. In this dialog, SuggestionTextField takes
      // the full list and filters internally if configured, or here we just
      // trigger rebuild if needed.
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: SuggestionTextField(
          controller: _controller,
          hintText: widget.hint ?? '',
          suggestions: widget.suggestions ?? [],
          onChanged: (_) => _updateSuggestions(),
          onSubmitted: (_) {
            widget.onConfirm(_controller.text.trim());
            Navigator.pop(context);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onConfirm(_controller.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
