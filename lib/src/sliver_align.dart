import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'rendering/sliver_stack.dart';
import 'sliver_stack.dart';

/// Aligns a naturally sized box child within a [SliverStack].
///
/// Defaults to [Alignment.center]. Supports [AlignmentDirectional] using the
/// stack's text direction. The child does not contribute to the stack's extent
/// and scrolls with it. Use [Padding] inside [SliverAlign] for edge spacing.
///
/// Like [SliverPositioned], this must descend from a [SliverStack] through only
/// stateless or stateful widgets. The child must be a box widget, not a sliver.
class SliverAlign extends ParentDataWidget<SliverStackParentData> {
  const SliverAlign({
    Key? key,
    this.alignment = Alignment.center,
    required Widget child,
  }) : super(key: key, child: child);

  /// The child's position within the stack.
  final AlignmentGeometry alignment;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject is RenderBox, 'SliverAlign requires a box child.');
    assert(renderObject.parentData is SliverStackParentData);
    final data = renderObject.parentData as SliverStackParentData;
    if (data.alignment == alignment &&
        data.left == null &&
        data.top == null &&
        data.right == null &&
        data.bottom == null &&
        data.width == null &&
        data.height == null &&
        !data.centerWhenZero) {
      return;
    }
    data
      ..alignment = alignment
      ..left = null
      ..top = null
      ..right = null
      ..bottom = null
      ..width = null
      ..height = null
      ..centerWhenZero = false;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
  }

  @override
  Type get debugTypicalAncestorWidgetClass => SliverStack;
}
