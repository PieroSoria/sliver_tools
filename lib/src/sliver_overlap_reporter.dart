import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports the resting height of a pinned header sliver to a
/// [SliverOverlapReporterHandle], the same way [SliverOverlapAbsorber] feeds a
/// [NestedScrollView]'s handle.
///
/// Wrap the pinned header (a [SliverAppBar] with `pinned: true`, a
/// [SliverPinnedHeader], or any other persistently stuck sliver) in a
/// [SliverOverlapReporter] and pass the same handle to a
/// [SliverTabBarView]'s `overlapHandle`. The [SliverTabBarView] then reads
/// the header's true resting height from the handle when computing how far a
/// short tab's content rests: the first items come to rest right below the
/// header, so they are never hidden behind it, even when the header is nested
/// inside other slivers where an automatic measurement could not reach it.
///
/// Unlike [SliverOverlapAbsorber], this widget does **not** change the
/// header's geometry: it forwards the laid out sliver as-is and only copies
/// [SliverGeometry.maxScrollObstructionExtent] into [handle]. It is meant to
/// be used in a single [CustomScrollView] (not a [NestedScrollView]), where
/// the scroll extent must be kept intact.
class SliverOverlapReporter extends SingleChildRenderObjectWidget {
  /// Creates a sliver that reports its child's resting extent to [handle].
  const SliverOverlapReporter({
    super.key,
    required this.handle,
    required Widget sliver,
  }) : super(child: sliver);

  /// The handle in which the wrapped sliver's resting height is recorded.
  final SliverOverlapReporterHandle handle;

  @override
  RenderSliverOverlapReporter createRenderObject(BuildContext context) {
    return RenderSliverOverlapReporter(handle: handle);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverOverlapReporter renderObject) {
    renderObject.handle = handle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SliverOverlapReporterHandle>('handle', handle));
  }
}

/// Receives the resting height (the [SliverGeometry.maxScrollObstructionExtent],
/// i.e. the `minExtent` for a pinned header) of the sliver wrapped in a
/// [SliverOverlapReporter].
///
/// The value is written during the layout of the [SliverOverlapReporter] and
/// read by a [SliverTabBarView] during its own layout, so the reporter must
/// be laid out before the [SliverTabBarView] (as any header is, when it comes
/// before it in the [CustomScrollView]).
class SliverOverlapReporterHandle extends ChangeNotifier {
  /// Creates a [SliverOverlapReporterHandle].
  SliverOverlapReporterHandle() {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  double? _extent;

  /// The resting height of the reported sliver, or null before any layout has
  /// taken place.
  double? get extent => _extent;

  void _update(double value) {
    if (_extent == value) {
      return;
    }
    _extent = value;
    notifyListeners();
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'SliverOverlapReporterHandle')}(extent: $extent)';
  }
}

/// The render object for [SliverOverlapReporter]: measures its child exactly
/// like any other sliver and forwards its geometry unchanged, recording only
/// the child's [SliverGeometry.maxScrollObstructionExtent] in the handle.
class RenderSliverOverlapReporter extends RenderSliver
    with RenderObjectWithChildMixin<RenderSliver> {
  /// Creates a [RenderSliverOverlapReporter] that reports to [handle].
  RenderSliverOverlapReporter({required this.handle});

  /// The handle in which the wrapped sliver's resting height is recorded.
  SliverOverlapReporterHandle handle;

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    child!.layout(constraints);
    final SliverGeometry childGeometry = child!.geometry!;
    geometry = childGeometry;
    handle._update(childGeometry.maxScrollObstructionExtent);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    // child is laid out at our origin.
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child!, offset);
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (child != null) {
      return child!.hitTest(
        result,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
      );
    }
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SliverOverlapReporterHandle>('handle', handle));
  }
}