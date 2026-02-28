import 'package:flutter/widgets.dart';

/// InheritedWidget that broadcasts the currently active bottom‑nav tab index
/// to all descendants.
///
/// Pages inside an `IndexedStack` can override `didChangeDependencies` and call
/// `ActiveTabScope.of(context)` to know when their tab becomes visible, e.g.
/// to scroll back to the top.
class ActiveTabScope extends InheritedWidget {
  final int activeIndex;

  const ActiveTabScope({
    super.key,
    required this.activeIndex,
    required super.child,
  });

  /// Returns the active tab index.  Throws if no [ActiveTabScope] ancestor
  /// exists.
  static int of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ActiveTabScope>();
    assert(scope != null, 'No ActiveTabScope found in context');
    return scope!.activeIndex;
  }

  /// Returns the active tab index, or `null` if no [ActiveTabScope] ancestor
  /// exists.
  static int? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ActiveTabScope>()
        ?.activeIndex;
  }

  @override
  bool updateShouldNotify(ActiveTabScope oldWidget) =>
      activeIndex != oldWidget.activeIndex;
}
