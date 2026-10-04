import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_tools/sliver_tools.dart';

void main() {
  for (final axis in Axis.values) {
    for (final direction in TextDirection.values) {
      testWidgets('alignment updates on $axis in $direction', (tester) async {
        final semantics = tester.ensureSemantics();
        final alignment = ValueNotifier<AlignmentGeometry>(Alignment.center);
        final scroll = ScrollController();
        addTearDown(alignment.dispose);
        addTearDown(scroll.dispose);
        const key = ValueKey('aligned');
        await tester.pumpWidget(Directionality(
          textDirection: direction,
          child: CustomScrollView(
            controller: scroll,
            scrollDirection: axis,
            slivers: [
              SliverStack(positionedAlignment: Alignment.bottomLeft, children: [
                const SliverToBoxAdapter(
                    child: SizedBox(width: 1200, height: 1200)),
                ValueListenableBuilder<AlignmentGeometry>(
                  valueListenable: alignment,
                  builder: (_, value, __) => SliverAlign(
                    alignment: value,
                    child: const SizedBox(key: key, width: 40, height: 40),
                  ),
                ),
              ]),
            ],
          ),
        ));
        final viewport = tester.getSize(find.byType(CustomScrollView));
        final size = axis == Axis.vertical
            ? Size(viewport.width, 1200)
            : Size(1200, viewport.height);
        final reverseHorizontal =
            axis == Axis.horizontal && direction == TextDirection.rtl;
        final origin = reverseHorizontal
            ? Offset(viewport.width - size.width, 0)
            : Offset.zero;
        for (final value in [
          Alignment.center,
          Alignment.topRight,
          Alignment.bottomLeft,
          AlignmentDirectional.topEnd
        ]) {
          alignment.value = value;
          await tester.pump();
          final expected = value
              .resolve(direction)
              .alongOffset(Offset(size.width - 40, size.height - 40));
          expect(tester.getTopLeft(find.byKey(key)), expected + origin);
          expect(tester.getSize(find.byKey(key)), const Size(40, 40));
          expect(tester.takeException(), isNull);
        }
        scroll.jumpTo(100);
        await tester.pump();
        final shift = axis == Axis.vertical
            ? const Offset(0, -100)
            : Offset(reverseHorizontal ? 100 : -100, 0);
        final expected = alignment.value
            .resolve(direction)
            .alongOffset(Offset(size.width - 40, size.height - 40));
        expect(tester.getTopLeft(find.byKey(key)), expected + origin + shift);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }
}
