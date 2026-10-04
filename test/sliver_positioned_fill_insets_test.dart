import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_tools/sliver_tools.dart';

void main() {
  for (final alignment in [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ]) {
    testWidgets('fill respects 20px insets at $alignment', (tester) async {
      const itemKey = ValueKey('item');
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverStack(children: [
              const SliverToBoxAdapter(child: SizedBox(height: 1000)),
              SliverPositioned.fill(
                top: alignment.y < 0 ? 20 : null,
                right: alignment.x > 0 ? 20 : null,
                bottom: alignment.y > 0 ? 20 : null,
                left: alignment.x < 0 ? 20 : null,
                child: const SizedBox(key: itemKey, width: 34, height: 34),
              ),
            ]),
          ],
        ),
      ));
      final viewportWidth = tester.getSize(find.byType(CustomScrollView)).width;
      final expected = Offset(
        alignment.x < 0 ? 20 : viewportWidth - 20 - 34,
        alignment.y < 0 ? 20 : 1000 - 20 - 34,
      );
      expect(tester.getTopLeft(find.byKey(itemKey)), expected);
      expect(tester.getSize(find.byKey(itemKey)), const Size(34, 34));
      controller.jumpTo(100);
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(itemKey)),
          expected - const Offset(0, 100));
      expect(tester.takeException(), isNull);
    });
  }
}
