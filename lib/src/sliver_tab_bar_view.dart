import 'dart:math' as math;

import 'package:flutter/rendering.dart' as rendering;
import 'package:material_ui/material_ui.dart';

import 'multi_sliver.dart';
import 'sliver_overlap_reporter.dart';
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
/// Set [fillsRemaining] to true to make short tabs behave like tall ones: each
/// tab is then extended so it always covers the whole screen and keeps some
/// scroll extent even when its slivers are shorter (useful when one tab has
/// little content but the others fill the screen, and when a pinned [TabBar]
/// above must reach the top on every tab).
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
class SliverTabBarView extends StatefulWidget {
  const SliverTabBarView({
    super.key,
    required this.children,
    this.controller,
    this.enableSwipe = true,
    this.fillsRemaining = false,
    this.fillChild,
    this.extraScroll,
    this.overlapHandle,
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

  /// Whether every tab is extended to cover the whole viewport height, even
  /// when its slivers are shorter than the screen.
  ///
  /// When true, each tab is wrapped so that, right after the tab's own
  /// slivers, a filling sliver covers the leftover space with [fillChild]
  /// (keeping that area hit-testable for swipes) and contributes scroll
  /// extent. Two things happen for a short tab:
  ///
  ///  * A pinned header placed before this widget in the [CustomScrollView]
  ///    (like a [SliverAppBar] holding a [TabBar]) can reach the top, because
  ///    the tab is now tall enough to scroll past the header.
  ///  * The scroll stops with the tab's first items resting right below that
  ///    pinned header: the header is measured (or reported through an
  ///    [overlapHandle]) and the tab contributes exactly the scroll extent
  ///    needed, so the content is never scrolled entirely out of view nor
  ///    hidden behind the header. The resting position is fine tuned with
  ///    [extraScroll].
  ///
  /// The neighbor pages revealed during a swipe are filled the same way, so
  /// no gap shows between pages. Tabs that are taller than the viewport are
  /// unaffected. Defaults to false.
  final bool fillsRemaining;

  /// The widget painted in the leftover viewport space of tabs shorter than
  /// the screen, used when [fillsRemaining] is true.
  ///
  /// The child is stretched to cover the empty area below the tab content.
  /// When null the area is left transparent: the tab still covers the whole
  /// viewport (for hit testing and swipes), but nothing is painted. Provide
  /// something visible, like a [ColoredBox] with the background color, to
  /// actually paint the empty space.
  final Widget? fillChild;

  /// How far a short tab's content rests from the top edge when it has
  /// scrolled all the way, when [fillsRemaining] is true.
  ///
  /// When null (the default), the resting position is measured: the tab stops
  /// with its first items exactly below the pinned headers (like a pinned
  /// [SliverAppBar] holding a [TabBar]) laid out before this widget in the
  /// [CustomScrollView], so the content is never hidden behind them and the
  /// whole list stays on screen. When [overlapHandle] is provided, its
  /// reported resting height is used instead.
  ///
  /// Set it to a fixed value to override the measured one. A smaller value
  /// scrolls the top items further under the pinned header (tucking them in),
  /// a larger one keeps the content lower but can leave the pinned header
  /// unable to fully reach the top of the screen.
  final double? extraScroll;

  /// A [SliverOverlapReporterHandle] fed by a [SliverOverlapReporter] wrapping
  /// the pinned header laid out before this widget.
  ///
  /// Just like a [SliverOverlapAbsorber] in a [NestedScrollView], the
  /// [SliverOverlapReporter] records the header's true resting height in the
  /// handle during layout, and the tab reads it to compute where its content
  /// rests. This is the authoritative source when the header cannot be
  /// measured automatically (for example when it is grouped inside other
  /// slivers); when null, the header is measured from the running layout.
  ///
  /// ```dart
  /// final _overlap = SliverOverlapReporterHandle();
  ///
  /// CustomScrollView(
  ///   slivers: [
  ///     SliverOverlapReporter(
  ///       handle: _overlap,
  ///       sliver: SliverAppBar(pinned: true, bottom: TabBar(...)),
  ///     ),
  ///     SliverTabBarView(
  ///       overlapHandle: _overlap,
  ///       fillsRemaining: true,
  ///       children: [...],
  ///     ),
  ///   ],
  /// )
  /// ```
  final SliverOverlapReporterHandle? overlapHandle;

  @override
  State<SliverTabBarView> createState() => _SliverTabBarViewState();

  List<Widget> _tabsFillingRemaining() {
    // `reveal` is how far the content rests from the top edge when the tab has
    // scrolled all the way: the tab's total scroll extent is trimmed to
    // `viewport - reveal`, so the first items come to rest that many pixels
    // below the top. When [extraScroll] is null the reveal is measured from
    // the pinned headers laid out before this widget (or reported through
    // [overlapHandle]), so the items stop right below them, fully visible.
    // The filling extents are computed from the sliver constraints:
    // `leading` is everything before this tab (the outer builder), `content`
    // is the tab's own extent (`inner.precedingScrollExtent - leading`), and
    // the filler covers the leftover of `viewportMainAxisExtent` minus the
    // reveal. Both values are stable across scrolls, so the tab's total scroll
    // extent never changes while dragging.
    return [
      for (final tab in children)
        MultiSliver(
          children: [
            SliverLayoutBuilder(
              builder: (context, outer) {
                final double leading = outer.precedingScrollExtent;
                final double reveal =
                    extraScroll ??
                    overlapHandle?.extent ??
                    _measurePinnedHeaderExtent(context);
                return MultiSliver(
                  children: [
                    tab,
                    SliverLayoutBuilder(
                      builder: (context, inner) {
                        final double content =
                            inner.precedingScrollExtent - leading;
                        final double extra = math.max(
                          0.0,
                          inner.viewportMainAxisExtent - content - reveal,
                        );
                        return SliverToBoxAdapter(
                          child: SizedBox(
                            width: double.infinity,
                            height: extra,
                            child: fillChild ?? const SizedBox.shrink(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
    ];
  }

  // Measured pinned headers' resting height, used as the reveal when the
  // render tree is unavailable.
  static const double _fallbackReveal = kToolbarHeight + kTextTabBarHeight;

  /// The combined resting height of the pinned headers laid out before this
  /// widget in the same viewport, or 0 when there are none. Each pinned
  /// [RenderSliverPersistentHeader] carries its resting height in
  /// [SliverGeometry.maxScrollObstructionExtent] (its `minExtent`, the height
  /// it keeps on screen once scrolled to the top, toolbar and TabBar alike).
  static double _measurePinnedHeaderExtent(BuildContext context) {
    // This builder runs at layout time, so any header laid out before this tab
    // already holds a fresh geometry for the current frame. The headers can be
    // direct viewport slivers or grouped deeper (inside a MultiSliver or a
    // SliverStack), so walk up from this layout builder's render object and
    // scan the previous siblings at every container level.
    RenderObject? node = context.findRenderObject();
    var extent = 0.0;
    var foundContainer = false;
    while (node != null) {
      final parent = node.parent;
      if (parent is rendering.ContainerRenderObjectMixin) {
        foundContainer = true;
        var previous = parent.childBefore(node);
        while (previous != null) {
          if (previous is rendering.RenderSliverPinnedPersistentHeader) {
            extent += previous.geometry?.maxScrollObstructionExtent ?? 0.0;
          } else if (previous
              is rendering.RenderSliverFloatingPinnedPersistentHeader) {
            extent += previous.geometry?.maxScrollObstructionExtent ?? 0.0;
          }
          previous = parent.childBefore(previous);
        }
      }
      node = parent;
    }
    // Sane default only when no container was found at all; a real viewport
    // with no pinned headers measures 0.
    return foundContainer ? extent : _fallbackReveal;
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

class _SliverTabBarViewState extends State<SliverTabBarView> {
  // The wrapped tabs are stable and expensive to build (one SliverLayoutBuilder
  // per tab whose reveal does a small render-tree walk at layout time), so they
  // are built once and reused across rebuilds: the parent scrolls without
  // rebuilding the tab structure, and the AnimatedBuilder's per-tick rebuilds
  // only select the active sliver.
  List<Widget>? _tabs;

  @override
  void didUpdateWidget(SliverTabBarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fillsRemaining != oldWidget.fillsRemaining ||
        !identical(widget.children, oldWidget.children) ||
        widget.extraScroll != oldWidget.extraScroll ||
        widget.overlapHandle != oldWidget.overlapHandle) {
      _tabs = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller ?? DefaultTabController.of(context);
    final tabs = _tabs ??= widget.fillsRemaining
        ? widget._tabsFillingRemaining()
        : widget.children;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final index = controller.index;
        final sliver = tabs[index];
        if (!widget.enableSwipe || !widget._scrollsVertically(context)) {
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
          onSwipeProgress: (fraction) => SliverTabBarView._syncTabControllerOffset(
            controller,
            fraction,
          ),
          previousChild: hasPrevious ? tabs[index - 1] : null,
          nextChild: hasNext ? tabs[index + 1] : null,
          child: sliver,
        );
      },
    );
  }
}