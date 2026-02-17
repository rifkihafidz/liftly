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
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _filteredSuggestions = [];

  // Used to distinguish between typing and selecting
  // When selecting, we update the TextField without re-opening the overlay
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    if (widget.focusNode != null) {
      widget.focusNode!.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    // Safety: try to remove listener but catch if controller is already disposed
    try {
      widget.controller.removeListener(_onTextChanged);
    } catch (_) {
      // Controller might already be disposed by parent
    }
    if (widget.focusNode != null) {
      try {
        widget.focusNode!.removeListener(_onFocusChanged);
      } catch (_) {}
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode != null && !widget.focusNode!.hasFocus) {
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    if (_isSelecting) return;

    final query = widget.controller.text.trim().toLowerCase();

    // Notify parent of changes
    widget.onChanged?.call(widget.controller.text);

    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    setState(() {
      _filteredSuggestions = widget.suggestions.where((s) {
        final sLower = s.toLowerCase();
        // Show suggestion if it matches query BUT is not an exact match
        // This solves the issue of the suggestion box persisting after selection
        return sLower.contains(query) && sLower != query;
      }).toList();
    });

    if (_filteredSuggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(String suggestion) {
    _isSelecting = true;
    widget.controller.text = suggestion;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _isSelecting = false;

    // Explicitly hide overlay and clear suggestions after selection
    _removeOverlay();
    if (!mounted) return;
    setState(() {
      _filteredSuggestions = [];
    });

    // Notify parent
    widget.onChanged?.call(suggestion);
  }

  OverlayEntry _createOverlayEntry() {
    if (!mounted) return OverlayEntry(builder: (_) => const SizedBox.shrink());
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return OverlayEntry(builder: (_) => const SizedBox.shrink());
    }
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: TapRegion(
            onTapOutside: (event) {
              _removeOverlay();
            },
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(8),
              color: AppColors.cardBg,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _filteredSuggestions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = _filteredSuggestions[index];
                    return InkWell(
                      onTap: () {
                        _selectSuggestion(suggestion);
                        // Also trigger onSubmitted if needed, though _selectSuggestion
                        // already updates the text.
                        widget.onSubmitted(suggestion);
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: true,
        textInputAction: TextInputAction.done,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
        onSubmitted: (value) {
          _removeOverlay();
          widget.onSubmitted(value);
        },
      ),
    );
  }
}
