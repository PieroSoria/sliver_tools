import 'package:material_ui/material_ui.dart';

import 'sliver_swipeable.dart';

/// [SliverTabBarView] is a sliver that shows one of several sliver groups
/// depending on the active tab. Use it directly inside a
/// [CustomScrollView]'s `slivers` list.
///
/// Each entry in [children] is the content of one tab and must be a sliver
/// (for example a [MultiSliver] wrapping several slivers). Only the slivers of
/// the active tab are inserted into the [CustomScrollView], so the tab content
/// **shares the parent's scroll** — there is no nested viewport. This is the
/// classic profile-page layout where headers, posts and works all scroll
/// together.
///
/// Switching tabs is done through the [TabBar] (tab taps) and, when
/// [enableSwipe] is true, by swiping sideways over the tab content. Because
/// the content is laid out as regular slivers of the parent's viewport, the
/// swipe is recognized by a [SliverSwipeable] gesture that competes with the
/// parent's vertical scroll: horizontal drags switch tabs, vertical drags
/// scroll.
///
/// The [TabBar] itself is **not** part of this widget. Drive the tabs with
/// your own [TabController] (or a [DefaultTabController] ancestor) and place
/// the [TabBar] wherever you like.
///
/// Typical usage:
///
/// ```dart
/// DefaultTabController(
///   length: 2,
///   child: Scaffold(
///     body: CustomScrollView(
///       slivers: [
///         const SliverToBoxAdapter(child: Text('Leading content')),
///         const SliverTabBarView(
///           children: [
///             MultiSliver(
///               children: [
///                 SliverToBoxAdapter(child: Text('Page A')),
///               ],
///             ),
///             MultiSliver(
///               children: [
///                 SliverToBoxAdapter(child: Text('Page B')),
///               ],
///             ),
///           ],
///         ),
///         const SliverToBoxAdapter(child: Text('Trailing content')),
///       ],
///     ),
///   ),
/// )
/// ```
class SliverTabBarView extends StatelessWidget {
  const SliverTabBarView({
    super.key,
    required this.children,
    this.controller,
    this.enableSwipe = true,
  });

  /// The content of each tab. Every entry must be a sliver (use a
  /// [MultiSliver] to group several slivers into one tab).
  final List<Widget> children;

  /// The [TabController] that drives the tabs. When null a
  /// [DefaultTabController] ancestor is used.
  final TabController? controller;

  /// Whether swiping sideways over the tab content switches tabs with a
  /// [PageView]-like slide, exactly like a [TabBarView] does. Horizontal drags
  /// are handled by the tab content while vertical drags keep scrolling the
  /// parent viewport. Defaults to true.
  ///
  /// When enabled, the [TabBar] indicator is kept in sync with the swipe: the
  /// [TabController.offset] follows the slide as it is dragged, so the
  /// indicator moves with the finger and settles together with the content,
  /// just like a [TabBarView].
  ///
  /// Only applies when the parent [Scrollable] scrolls vertically. Inside a
  /// horizontally scrolling [CustomScrollView] horizontal drags are left to
  /// the scroll itself.
  final bool enableSwipe;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller ?? DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final index = controller.index;
        final sliver = children[index];
        if (!enableSwipe || !_scrollsVertically(context)) {
          return sliver;
        }
        final hasPrevious = index > 0;
        final hasNext = index < controller.length - 1;
        return SliverSwipeable(
          onSwipeLeft: hasNext
              ? () =>
                  controller.animateTo(controller.index + 1, duration: Duration.zero)
              : null,
          onSwipeRight: hasPrevious
              ? () =>
                  controller.animateTo(controller.index - 1, duration: Duration.zero)
              : null,
          // Mirror the slide into the TabController's offset so the TabBar
          // indicator follows the drag. Sign: a swipe to the left (fraction
          // negative) goes to the next tab, which is a positive offset for the
          // TabController's animation.
          onSwipeProgress: (fraction) => _syncTabControllerOffset(
            controller,
            fraction,
          ),
          previousChild: hasPrevious ? children[index - 1] : null,
          nextChild: hasNext ? children[index + 1] : null,
          child: sliver,
        );
      },
    );
  }

  static void _syncTabControllerOffset(TabController controller, double fraction) {
    // A tab tap animates the controller on its own; the offset cannot be
    // changed while that animation is running.
    if (controller.indexIsChanging) {
      return;
    }
    controller.offset = -fraction.clamp(-1.0, 1.0);
  }

  bool _scrollsVertically(BuildContext context) {
    switch (Scrollable.maybeOf(context)?.axisDirection) {
      case AxisDirection.up:
      case AxisDirection.down:
      case null:
        return true;
      case AxisDirection.left:
      case AxisDirection.right:
        return false;
    }
  }
}