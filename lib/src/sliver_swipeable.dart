import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show RenderSliver;
import 'package:flutter/widgets.dart';

import 'rendering/sliver_swipeable.dart';

/// A sliver that gives its [child] a [PageView]-like swipe: dragging
/// horizontally slides the current page sideways following the finger, while
/// the page on the other side (painted from [previousChild]/[nextChild]) is
/// revealed underneath. Releasing the drag settles the pages either back to
/// the current one or onto the neighboring page, depending on distance and
/// velocity.
///
/// Because a sliver lives inside the parent [Viewport] (there is no nested
/// viewport to translate swipes into page changes), [SliverSwipeable] adds a
/// horizontal drag recognizer that competes with the parent scroll: horizontal
/// drags slide the pages, vertical drags (and taps) are left untouched.
///
/// When a swipe settles onto [nextChild] a new tab is selected. `onSwipeLeft`
/// is invoked when the user swiped left (towards the next/later tab),
/// `onSwipeRight` when the user swiped right (towards the previous tab). The
/// caller is responsible for rebuilding this widget with the newly active
/// [child]; the slide resets itself once [child] changes.
///
/// Use it by wrapping the slivers of a tab:
///
/// ```dart
/// SliverSwipeable(
///   onSwipeLeft: () => controller.nextPage(
///     duration: const Duration(milliseconds: 300),
///     curve: Curves.ease,
///   ),
///   onSwipeRight: () => controller.previousPage(
///     duration: const Duration(milliseconds: 300),
///     curve: Curves.ease,
///   ),
///   child: pages[controller.index],
///   nextChild: pages[controller.index + 1],
///   previousChild: pages[controller.index - 1],
/// )
/// ```
///
/// See also:
///
///  * [SliverTabBarView], which uses this widget to switch tabs on swipe.
class SliverSwipeable extends StatefulWidget {
  /// Creates a sliver with a pageview-like horizontal swipe.
  const SliverSwipeable({
    super.key,
    required this.child,
    this.previousChild,
    this.nextChild,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeProgress,
    this.swipeVelocityThreshold = 400,
    this.swipeDistanceThreshold = 48,
    this.settleDuration = const Duration(milliseconds: 220),
  });

  /// The currently active page's slivers.
  final Widget child;

  /// The slivers of the page to the left of [child] (the previous tab),
  /// revealed while swiping right.
  final Widget? previousChild;

  /// The slivers of the page to the right of [child] (the next tab), revealed
  /// while swiping left.
  final Widget? nextChild;

  /// Called when the user swipes towards the left and lets go (to go to the
  /// next tab). When null, a left swipe settles back to [child].
  final void Function()? onSwipeLeft;

  /// Called when the user swipes towards the right and lets go (to go to the
  /// previous tab). When null, a right swipe settles back to [child].
  final void Function()? onSwipeRight;

  /// Called with the slide of [child] as a fraction of the viewport width
  /// whenever it changes during a horizontal drag or the settling animation.
  ///
  /// The value is `0` when the page is centered, negative when the page was
  /// dragged to the left (towards [nextChild]) and positive when dragged to
  /// the right (towards [previousChild]). It is clamped to `-1.0..1.0`.
  ///
  /// This lets the parent reflect the swipe into other animations, like the
  /// [TabBar] indicator of a tab view.
  final void Function(double slideFraction)? onSwipeProgress;

  /// Horizontal pixels/second that count as a swipe even when the dragged
  /// distance stays below [swipeDistanceThreshold].
  final double swipeVelocityThreshold;

  /// Pixels dragged that count as a swipe even when the velocity stays below
  /// [swipeVelocityThreshold].
  final double swipeDistanceThreshold;

  /// The duration of the animation that settles the pages after a drag.
  final Duration settleDuration;

  @override
  State<SliverSwipeable> createState() => _SliverSwipeableState();
}

class _SliverSwipeableState extends State<SliverSwipeable>
    with SingleTickerProviderStateMixin {
  static const Widget _emptyPage = SliverToBoxAdapter(
    child: SizedBox.shrink(),
  );

  late final HorizontalDragGestureRecognizer _recognizer;
  late final AnimationController _settleController;

  double _dragStartX = 0;
  double _startGlobalX = 0;
  double _x = 0;
  double _animateFrom = 0;
  double _animateTarget = 0;
  void Function()? _settleCallback;

  RenderSliverSwipe? get _renderSwipe =>
      context.findRenderObject() as RenderSliverSwipe?;

  double get _viewportWidth => _renderSwipe?.viewportWidth ?? 0;

  @override
  void initState() {
    super.initState();
    _settleController =
        AnimationController(vsync: this)..addListener(_handleSettleTick);
    _recognizer = HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart;
    _recognizer.onUpdate = _handleDragUpdate;
    _recognizer.onEnd = _handleDragEnd;
  }

  @override
  void didUpdateWidget(SliverSwipeable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.child, widget.child)) {
      _settleController.stop();
      _settleCallback = null;
      _x = 0;
      _applyX();
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _settleController.stop();
    _settleCallback = null;
    _dragStartX = _x;
    _startGlobalX = details.globalPosition.dx;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final total = details.globalPosition.dx - _startGlobalX;
    final width = _viewportWidth;
    _x = (_dragStartX + total).clamp(-width, width);
    _applyX();
  }

  void _handleDragEnd(DragEndDetails details) {
    final total = (details.globalPosition.dx - _startGlobalX);
    final velocity = details.primaryVelocity ?? 0;
    final width = _viewportWidth;

    var swipeLeft = velocity < -widget.swipeVelocityThreshold ||
        total < -widget.swipeDistanceThreshold;
    var swipeRight = velocity > widget.swipeVelocityThreshold ||
        total > widget.swipeDistanceThreshold;
    if (widget.onSwipeLeft == null) {
      swipeLeft = false;
    }
    if (widget.onSwipeRight == null) {
      swipeRight = false;
    }

    double target = 0;
    void Function()? callback;
    if (swipeLeft) {
      target = -width;
      callback = widget.onSwipeLeft;
    } else if (swipeRight) {
      target = width;
      callback = widget.onSwipeRight;
    }
    _animateTo(target, onComplete: callback);
  }

  void _animateTo(double target, {void Function()? onComplete}) {
    _settleController.stop();
    if ((_x - target).abs() < 0.5) {
      _x = target;
      _applyX();
      onComplete?.call();
      return;
    }
    _animateFrom = _x;
    _animateTarget = target;
    _settleCallback = onComplete;
    _settleController.duration = widget.settleDuration;
    _settleController.forward(from: 0);
  }

  void _handleSettleTick() {
    final t = Curves.easeOutCubic.transform(_settleController.value);
    _x = _animateFrom + (_animateTarget - _animateFrom) * t;
    _applyX();
    if (_settleController.value >= 1.0) {
      final callback = _settleCallback;
      _settleCallback = null;
      callback?.call();
    }
  }

  void _applyX() {
    final render = _renderSwipe;
    if (render != null && render.xOffset != _x) {
      render.xOffset = _x;
    }
    _reportProgress();
  }

  void _reportProgress() {
    final onProgress = widget.onSwipeProgress;
    if (onProgress == null) {
      return;
    }
    final width = _viewportWidth;
    final fraction = width == 0 ? 0.0 : (_x / width).clamp(-1.0, 1.0);
    onProgress(fraction);
  }

  @override
  void dispose() {
    _settleController.dispose();
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SliverSwipeGesture(
      recognizer: _recognizer,
      previous: widget.previousChild ?? _emptyPage,
      current: widget.child,
      next: widget.nextChild ?? _emptyPage,
    );
  }
}

class _SliverSwipeGesture
    extends SlottedMultiChildRenderObjectWidget<SliverSwipeSlot, RenderSliver> {
  const _SliverSwipeGesture({
    required this.previous,
    required this.current,
    required this.next,
    required this.recognizer,
  });

  final Widget previous;
  final Widget current;
  final Widget next;
  final GestureRecognizer recognizer;

  @override
  Iterable<SliverSwipeSlot> get slots => SliverSwipeSlot.values;

  @override
  Widget? childForSlot(SliverSwipeSlot slot) {
    switch (slot) {
      case SliverSwipeSlot.previous:
        return previous;
      case SliverSwipeSlot.current:
        return current;
      case SliverSwipeSlot.next:
        return next;
    }
  }

  @override
  RenderSliverSwipe createRenderObject(BuildContext context) =>
      RenderSliverSwipe(recognizer: recognizer);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderSliverSwipe renderObject,
  ) {
    renderObject.recognizer = recognizer;
  }
}