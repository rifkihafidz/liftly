import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class SuggestionTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final List<String> suggestions;
  final Function(String) onSubmitted;
  final ValueChanged<String>? onChanged;

  const SuggestionTextField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.focusNode,
    this.hintText = 'Enter text...',
    this.suggestions = const [],
    this.onChanged,
  });

  @override
  State<SuggestionTextField> createState() => _SuggestionTextFieldState();
}

class _SuggestionTextFieldState extends State<SuggestionTextField> {
  List<String> _filteredSuggestions = [];
  bool _isSelecting = false;
  final FocusNode _internalFocusNode = FocusNode();

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _effectiveFocusNode.addListener(_onFocusChanged);
    // No auto-focus: let user tap to focus naturally.
    // Auto-focusing causes keyboard + viewport resize to race on mobile browsers.
  }

  @override
  void dispose() {
    // Safety: try to remove listener but catch if controller is already disposed
    try {
      widget.controller.removeListener(_onTextChanged);
    } catch (_) {}
    try {
      _effectiveFocusNode.removeListener(_onFocusChanged);
    } catch (_) {}

    _internalFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_effectiveFocusNode.hasFocus) {
      // Delay hiding to allow tap to register
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_effectiveFocusNode.hasFocus) {
          setState(() {
            _filteredSuggestions = [];
          });
        }
      });
    }
  }

  void _onTextChanged() {
    if (_isSelecting) return;

    final query = widget.controller.text.trim().toLowerCase();
    widget.onChanged?.call(widget.controller.text);

    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _filteredSuggestions = [];
        });
      }
      return;
    }

    setState(() {
      _filteredSuggestions = widget.suggestions.where((s) {
        final sLower = s.toLowerCase();
        return sLower.contains(query) && sLower != query;
      }).toList();
    });
  }

  void _selectSuggestion(String suggestion) {
    _isSelecting = true;
    widget.controller.text = suggestion;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _isSelecting = false;

    setState(() {
      _filteredSuggestions = [];
    });

    widget.onChanged?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _effectiveFocusNode,
          autofocus: false,
          textInputAction: TextInputAction.done,
          scrollPadding: EdgeInsets.zero,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            setState(() {
              _filteredSuggestions = [];
            });
            widget.onSubmitted(value);
          },
        ),
        if (_filteredSuggestions.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _filteredSuggestions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppColors.borderLight.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final suggestion = _filteredSuggestions[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) {
                    _selectSuggestion(suggestion);
                    widget.onSubmitted(suggestion);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      suggestion,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
