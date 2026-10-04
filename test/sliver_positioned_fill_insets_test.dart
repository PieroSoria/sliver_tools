import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_tools/sliver_tools.dart';

void main() {
  testWidgets('zero or omitted insets center at natural size and update',
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
              const item = SizedBox(key: itemKey, width: 40, height: 40);
              if (value == 1) return const SliverPositioned.fill(child: item);
              if (value == 3)
                return const SliverPositioned.fill(
                    top: 0, right: 0, child: item);
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
        Rect.fromLTWH((width - 40) / 2, 180, 40, 40));
    for (final value in [1, 2, 3, 0]) {
      mode.value = value;
      await tester.pump();
      final expected = value == 2
          ? Rect.fromLTWH(width - 60, 20, 40, 40)
          : Rect.fromLTWH((width - 40) / 2, 180, 40, 40);
      expect(tester.getRect(find.byKey(itemKey)), expected);
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });

  testWidgets('settings circle keeps 40px size with gesture and margin',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CustomScrollView(slivers: [
      SliverStack(children: [
        const SliverToBoxAdapter(child: SizedBox(height: 500)),
        SliverPositioned.fill(
            child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(top: 30, right: 10),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1)),
            child: const Icon(Icons.settings_outlined,
                color: Colors.white, size: 25),
          ),
        )),
      ]),
    ]))));
    final circle = find.ancestor(
        of: find.byIcon(Icons.settings_outlined),
        matching: find.byType(DecoratedBox));
    expect(tester.getSize(circle), const Size(40, 40));
    final width = tester.getSize(find.byType(CustomScrollView)).width;
    expect(tester.getTopLeft(circle),
        Offset((width - 50) / 2, (500 - 70) / 2 + 30));
    expect(tester.takeException(), isNull);
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
