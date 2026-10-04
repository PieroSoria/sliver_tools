import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_tools/sliver_tools.dart';

void main() {
  testWidgets('explicit zero insets center at natural size and update',
      (tester) async {
    const itemKey = ValueKey('centered-item');
    final semantics = tester.ensureSemantics();
    final mode = ValueNotifier<int>(0);
    addTearDown(mode.dispose);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: CustomScrollView(slivers: [
        SliverStack(positionedAlignment: Alignment.topLeft, children: [
          const SliverToBoxAdapter(child: SizedBox(height: 400)),
          ValueListenableBuilder<int>(
            valueListenable: mode,
            builder: (_, value, __) {
              const item = SizedBox(key: itemKey, width: 34, height: 50);
              if (value == 1) return const SliverPositioned.fill(child: item);
              return SliverPositioned.fill(
                top: value == 0 ? 0 : 20,
                left: value == 0 ? 0 : null,
                right: value == 0 ? 0 : 20,
                bottom: value == 0 ? 0 : null,
                child: item,
              );
            },
          ),
        ]),
      ]),
    ));
    final width = tester.getSize(find.byType(CustomScrollView)).width;
    expect(tester.getRect(find.byKey(itemKey)),
        Rect.fromLTWH((width - 34) / 2, 175, 34, 50));
    for (final value in [1, 2, 0]) {
      mode.value = value;
      await tester.pump();
      final expected = value == 1
          ? Rect.fromLTWH(0, 0, width, 400)
          : value == 2
              ? Rect.fromLTWH(width - 54, 20, 34, 50)
              : Rect.fromLTWH((width - 34) / 2, 175, 34, 50);
      expect(tester.getRect(find.byKey(itemKey)), expected);
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });

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
