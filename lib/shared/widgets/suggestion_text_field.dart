import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class SuggestionTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final List<String> suggestions;
  final Function(String) onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const SuggestionTextField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.focusNode,
    this.hintText = 'Enter text...',
    this.suggestions = const [],
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<SuggestionTextField> createState() => _SuggestionTextFieldState();
}

class _SuggestionTextFieldState extends State<SuggestionTextField> {
  List<String> _filteredSuggestions = [];
  bool _isSelecting = false;
  final FocusNode _internalFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _effectiveFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
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
    if (_effectiveFocusNode.hasFocus) {
      _updateSuggestions();
    } else {
      // Small delay to allow tap on suggestion to register
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_effectiveFocusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    if (_isSelecting) return;
    widget.onChanged?.call(widget.controller.text);
    _updateSuggestions();
  }

  void _updateSuggestions() {
    if (!mounted || !_effectiveFocusNode.hasFocus || !widget.enabled) {
      _removeOverlay();
      return;
    }

    final query = widget.controller.text.trim().toLowerCase();

    // If query is empty, show all suggestions on focus
    if (query.isEmpty) {
      if (widget.suggestions.isNotEmpty) {
        setState(() {
          _filteredSuggestions = widget.suggestions;
        });
        _showOverlay();
      } else {
        _removeOverlay();
      }
      return;
    }

    final matches = widget.suggestions.where((s) {
      final sLower = s.toLowerCase();
      return sLower.contains(query) && sLower != query;
    }).toList();

    if (mounted) {
      setState(() {
        _filteredSuggestions = matches;
      });

      if (_filteredSuggestions.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    if (!mounted) return;
    if (_overlayEntry == null) {
      final overlayState = Overlay.maybeOf(context);
      if (overlayState != null) {
        _overlayEntry = _createOverlayEntry();
        overlayState.insert(_overlayEntry!);
      }
    } else {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation:
                12, // Increased elevation for better depth without borders
            borderRadius: BorderRadius.circular(16),
            color: AppColors.cardBg,
            clipBehavior: Clip.antiAlias,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: const BoxDecoration(
                border: null, // Removed border as requested
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredSuggestions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: AppColors.borderLight.withValues(alpha: 0.05),
                ),
                itemBuilder: (context, index) {
                  final suggestion = _filteredSuggestions[index];
                  return InkWell(
                    onTap: () {
                      _selectSuggestion(suggestion);
                      // Only update the field, don't submit yet
                      // User will click confirm button in dialog or press enter
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
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectSuggestion(String suggestion) {
    _isSelecting = true;
    widget.controller.text = suggestion;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _isSelecting = false;
    _removeOverlay();
    widget.onChanged?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _effectiveFocusNode,
        enabled: widget.enabled,
        textInputAction: TextInputAction.done,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onSubmitted: (value) {
          _removeOverlay();
          widget.onSubmitted(value);
        },
      ),
    );
  }
}
