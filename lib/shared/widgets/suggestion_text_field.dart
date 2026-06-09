import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class SuggestionTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final List<String> suggestions;
  final Function(String) onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCleared;
  final bool enabled;

  const SuggestionTextField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.focusNode,
    this.hintText = 'Enter text...',
    this.suggestions = const [],
    this.onChanged,
    this.onCleared,
    this.enabled = true,
  });

  @override
  State<SuggestionTextField> createState() => _SuggestionTextFieldState();
}

class _SuggestionTextFieldState extends State<SuggestionTextField> {
  List<String> _filteredSuggestions = [];
  bool _isSelecting = false;
  bool _isInteractingWithSuggestions = false;
  bool _suppressRefocusAfterSelection = false;
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
      if (_suppressRefocusAfterSelection) {
        // A selection just occurred; ensure overlay removed and
        // don't refocus. Reset the suppress flag after handling.
        _removeOverlay();
        _suppressRefocusAfterSelection = false;
        return;
      }

      if (!_isInteractingWithSuggestions) {
        _removeOverlay();
      } else {
        // If lost focus while interacting with overlay, refocused
        _effectiveFocusNode.requestFocus();
      }
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
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    // Get screen and keyboard info
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final usableHeight = screenHeight - keyboardHeight;

    // Space calculations
    const double minOverlayHeight = 100;
    const double preferredMaxHeight = 200;
    final double spaceBelow = usableHeight - (offset.dy + size.height) - 8;
    final double spaceAbove = offset.dy - mediaQuery.padding.top - 8;

    // Determine position
    final bool showAbove =
        spaceBelow < minOverlayHeight && spaceAbove > spaceBelow;
    final double actualMaxHeight = showAbove
        ? spaceAbove.clamp(minOverlayHeight, preferredMaxHeight)
        : spaceBelow.clamp(minOverlayHeight, preferredMaxHeight);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset:
              Offset(0, showAbove ? -(actualMaxHeight + 4) : size.height + 4),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              setState(() => _isInteractingWithSuggestions = true);
              _effectiveFocusNode.requestFocus();
            },
            onPointerUp: (_) {
              // Delay setting to false to allow focus listener to catch it
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(() => _isInteractingWithSuggestions = false);
                }
              });
            },
            onPointerCancel: (_) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(() => _isInteractingWithSuggestions = false);
                }
              });
            },
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              color: AppColors.cardBg,
              clipBehavior: Clip.antiAlias,
              child: Container(
                constraints: BoxConstraints(maxHeight: actualMaxHeight),
                decoration: const BoxDecoration(),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  primary: false,
                  itemCount: _filteredSuggestions.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppColors.borderLight.withValues(alpha: 0.05),
                  ),
                  itemBuilder: (context, index) {
                    final suggestion = _filteredSuggestions[index];
                    return InkWell(
                      canRequestFocus: false,
                      onTap: () {
                        _selectSuggestion(suggestion);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          suggestion,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }

  void _selectSuggestion(String suggestion) {
    _isSelecting = true;
    widget.controller.text = suggestion;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    // Remove overlay and immediately unfocus so the keyboard/overlay
    // does not continue to block interaction after selection.
    // Set a suppress flag so the focus-change handler doesn't refocus
    // while we're intentionally closing the suggestions.
    _suppressRefocusAfterSelection = true;
    _removeOverlay();
    _isSelecting = false;
    widget.onChanged?.call(suggestion);
    if (mounted) {
      _effectiveFocusNode.unfocus();
    }
    // Clear the suppress flag after a short delay to allow normal behavior
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _suppressRefocusAfterSelection = false;
    });
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
        textAlignVertical: TextAlignVertical.center,
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
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, child) {
              if (value.text.isEmpty || !widget.enabled) {
                return const SizedBox(width: 36, height: 36);
              }
              return GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  widget.onChanged?.call('');
                  widget.onCleared?.call();
                  _updateSuggestions();
                  // Ensure field is focused after clearing
                  _effectiveFocusNode.requestFocus();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: const Icon(Icons.clear, size: 20, color: AppColors.textSecondary),
                ),
              );
            },
          ),
        ),
        onSubmitted: (value) {
          _removeOverlay();
          widget.onSubmitted(value);
        },
      ),
    );
  }
}
