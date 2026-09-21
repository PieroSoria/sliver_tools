import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' show SlottedContainerRenderObjectMixin;

/// The three page slots painted by [RenderSliverSwipe].
///
///  * [previous] is the page to the left, revealed when swiping right.
///  * [current] is the page that is normally shown.
///  * [next] is the page to the right, revealed when swiping left.
enum SliverSwipeSlot {
  previous,
  current,
  next;

  /// The horizontal paint offset for a page at [slideFactor] (a value in the
  /// range `-1.0..1.0`, where `0` means the page is centered, `-1` means the
  /// content was dragged one full page to the left and `1` means it was dragged
  /// a full page to the right).
  Offset offsetFor(double slideFactor, double crossAxisExtent) {
    switch (this) {
      case SliverSwipeSlot.previous:
        return Offset(crossAxisExtent * (slideFactor - 1), 0);
      case SliverSwipeSlot.current:
        return Offset(crossAxisExtent * slideFactor, 0);
      case SliverSwipeSlot.next:
        return Offset(crossAxisExtent * (1 + slideFactor), 0);
    }
  }
}

/// A [RenderSliver] that lays out up to three pages side by side (previous,
/// current and next tab) and slides them horizontally following an horizontal
/// drag, mimicking the look of a [PageView] without a nested viewport.
///
/// The pages are laid out with the same [SliverConstraints] as the containing
/// [Viewport], so they all scroll vertically with the parent. In the cross axis
/// they are painted at the offsets returned by
/// [SliverSwipeSlot.offsetFor], so dragging the [current] page aside reveals
/// the neighboring page underneath.
///
/// The reported geometry is taken from the [SliverSwipeSlot.current] page, so
/// the parent's scroll behaves exactly as if only the active tab was laid out.
///
/// Pointer events over the whole cross axis extent are forwarded to an
/// horizontal [GestureRecognizer] (see [handleEvent]), which competes with the
/// parent's vertical [Scrollable] in the gesture arena.
class RenderSliverSwipe extends RenderSliver
    with SlottedContainerRenderObjectMixin<SliverSwipeSlot, RenderSliver> {
  /// Creates a sliver that slides its pages by [xOffset] pixels and routes
  /// horizontal gestures to [recognizer].
  RenderSliverSwipe({
    required GestureRecognizer recognizer,
    double xOffset = 0,
  })  : _recognizer = recognizer,
        _xOffset = xOffset;

  GestureRecognizer _recognizer;

  /// The recognizer that receives every pointer that goes down over this
  /// sliver. It is the caller's responsibility to dispose it.
  GestureRecognizer get recognizer => _recognizer;
  set recognizer(GestureRecognizer value) {
    if (_recognizer == value) {
      return;
    }
    _recognizer = value;
  }

  double _xOffset;

  /// The current horizontal slide offset in pixels. Only affects painting, so
  /// changing it never triggers a relayout.
  double get xOffset => _xOffset;
  set xOffset(double value) {
    if (_xOffset == value) {
      return;
    }
    _xOffset = value;
    markNeedsPaint();
  }

  /// The width of the viewport in the cross axis.
  double get viewportWidth => constraints.crossAxisExtent;

  /// The slide amount as a fraction of the viewport width, clamped to
  /// `-1.0..1.0`.
  double get slideFactor {
    final width = viewportWidth;
    return width == 0 ? 0.0 : (_xOffset / width).clamp(-1.0, 1.0);
  }

  RenderSliver? _currentChild() {
    final child = childForSlot(SliverSwipeSlot.current);
    return child;
  }

  SliverSwipeSlot? _slotFor(RenderObject child) {
    for (final slot in SliverSwipeSlot.values) {
      if (identical(childForSlot(slot), child)) {
        return slot;
      }
    }
    return null;
  }

  @override
  void performLayout() {
    RenderSliver? current;
    for (final child in children) {
      child.layout(constraints, parentUsesSize: true);
      if (identical(child, _currentChild())) {
        current = child;
      }
    }
    geometry = current?.geometry ?? SliverGeometry.zero;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!geometry!.visible) {
      return;
    }
    final slide = slideFactor;
    for (final child in children) {
      final slot = _slotFor(child);
      if (slot == null || !child.geometry!.visible) {
        continue;
      }
      // Only paint pages that are (partially) visible: the previous page when
      // sliding right, the next page when sliding left and always the current
      // page.
      if (slot == SliverSwipeSlot.previous && slide <= 0) {
        continue;
      }
      if (slot == SliverSwipeSlot.next && slide >= 0) {
        continue;
      }
      final paintOffset = slot.offsetFor(slide, viewportWidth);
      context.paintChild(child, offset + paintOffset);
    }
  }

  @override
  void applyPaintTransform(covariant RenderObject child, Matrix4 transform) {
    final slot = _slotFor(child);
    if (slot == null) {
      return;
    }
    final paintOffset = slot.offsetFor(slideFactor, viewportWidth);
    transform.translateByDouble(paintOffset.dx, paintOffset.dy, 0.0, 1.0);
  }

  @override
  double childMainAxisPosition(covariant RenderObject child) => 0;

  @override
  double childCrossAxisPosition(covariant RenderObject child) {
    final slot = _slotFor(child);
    if (slot == null) {
      return 0;
    }
    return slot.offsetFor(slideFactor, viewportWidth).dx;
  }

  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (mainAxisPosition < 0.0 ||
        mainAxisPosition >= geometry!.hitTestExtent ||
        crossAxisPosition < 0.0 ||
        crossAxisPosition >= constraints.crossAxisExtent) {
      return false;
    }
    // Only the current page is interactive. Its paint offset depends on the
    // slide amount, so translate the hit to the child's local coordinates.
    final current = _currentChild();
    if (current != null) {
      final paintOffset =
          SliverSwipeSlot.current.offsetFor(slideFactor, viewportWidth);
      result.addWithAxisOffset(
        paintOffset: paintOffset,
        mainAxisOffset: 0,
        crossAxisOffset: paintOffset.dx,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
        hitTest: current.hitTest,
      );
    }
    // Behave like a translucent hit target: the whole area (including the gap
    // revealed next to the sliding page) can start a swipe.
    result.add(
      SliverHitTestEntry(
        this,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
      ),
    );
    return true;
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerDownEvent) {
      _recognizer.addPointer(event);
    }
  }
}