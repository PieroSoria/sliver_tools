import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_tools/sliver_tools.dart';

void main() {
  testWidgets('natural-height overlay updates with semantics enabled',
      (tester) async {
    final semantics = tester.ensureSemantics();

    final offset = ValueNotifier<double>(0);
    final scroll = ScrollController();
    scroll.addListener(() => offset.value = scroll.offset);
    addTearDown(scroll.dispose);
    addTearDown(offset.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CustomScrollView(
      controller: scroll,
      slivers: [
        SliverStack(children: [
          MultiSliver(children: [
            const SliverAppBar(
                expandedHeight: 200,
                flexibleSpace: FlexibleSpaceBar(title: Text('Banner'))),
            const SliverToBoxAdapter(child: SizedBox(height: 240)),
            const SliverAppBar(pinned: true, title: Text('Tabs')),
          ]),
          ValueListenableBuilder<double>(
              valueListenable: offset,
              builder: (_, value, __) => SliverPositioned.fill(
                    top: (210 - value / 3).clamp(0, 210),
                    child:
                        const Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Icon(Icons.person),
                        Expanded(child: Text('Profile'))
                      ]),
                      Text('Achievements'),
                      SizedBox(
                          height: 80,
                          child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                  children: [Text('First'), Text('Second')]))),
                    ]),
                  )),
        ]),
        const SliverToBoxAdapter(child: SizedBox(height: 1500))
      ],
    ))));
    expect(tester.takeException(), isNull);
    final profile =
        find.ancestor(of: find.text('Profile'), matching: find.byType(Column));
    final naturalSize = tester.getSize(profile);
    expect(
        naturalSize.width, tester.getSize(find.byType(CustomScrollView)).width);
    expect(naturalSize.height, greaterThan(80));
    expect(naturalSize.height, lessThan(210));
    for (final position in [20.0, 100.0, 300.0, 500.0, 800.0, 0.0]) {
      scroll.jumpTo(position);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(profile), naturalSize);
    }
    semantics.dispose();
  });
}
