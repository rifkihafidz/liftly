import 'package:flutter/material.dart';

class ScaleButtonWrapper extends StatefulWidget {
  final Widget child;
  final double scaleAmount;
  final Duration duration;

  const ScaleButtonWrapper({
    super.key,
    required this.child,
    this.scaleAmount = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<ScaleButtonWrapper> createState() => _ScaleButtonWrapperState();
}

class _ScaleButtonWrapperState extends State<ScaleButtonWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      upperBound: 1.0,
      lowerBound: widget.scaleAmount,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) =>
          _controller.animateTo(widget.scaleAmount, curve: Curves.easeInOut),
      onPointerUp: (_) => _controller.animateTo(1.0, curve: Curves.easeInOut),
      onPointerCancel: (_) =>
          _controller.animateTo(1.0, curve: Curves.easeInOut),
      child: ScaleTransition(scale: _controller, child: widget.child),
    );
  }
}
