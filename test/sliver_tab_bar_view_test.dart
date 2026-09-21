import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sliver_tools/sliver_tools.dart';

void main() {
  Widget buildWidget({TabController? controller}) {
    return DefaultTabController(
      length: 2,
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              controller: controller,
              tabs: const [
                Tab(text: 'One'),
                Tab(text: 'Two'),
              ],
            ),
          ),
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: Text('Leading content')),
              SliverTabBarView(
                controller: controller,
                children: [
                  MultiSliver(
                    children: const [
                      SliverToBoxAdapter(child: Text('Page 1')),
                    ],
                  ),
                  MultiSliver(
                    children: const [
                      SliverToBoxAdapter(child: Text('Page 2')),
                    ],
                  ),
                ],
              ),
              const SliverToBoxAdapter(child: Text('Trailing content')),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('renders the slivers of the first tab', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2').hitTestable(), findsNothing);
  });

  testWidgets('switches between tabs when a tab is tapped', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();

    expect(find.text('Page 1').hitTestable(), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
  });

  testWidgets('uses a provided TabController', (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildWidget(controller: controller));

    controller.index = 1;
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);
  });

  testWidgets('tab content shares the parent scroll', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.byType(CustomScrollView), findsOneWidget);
  });

testWidgets('swipes left to switch to the next tab', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.text('Page 1'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Page 1').hitTestable(), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
  });

  testWidgets('swipes right to switch to the previous tab', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Page 2'), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2').hitTestable(), findsNothing);
  });

  testWidgets('vertical drag scrolls without switching tabs', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2').hitTestable(), findsNothing);
  });

  testWidgets('swiping on the last tab does not crash', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Page 2'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Page 1').hitTestable(), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
  });

  testWidgets('disableSwipe keeps the slivers from being wrapped', (tester) async {
    await tester.pumpWidget(
      DefaultTabController(
        length: 2,
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverTabBarView(
                  enableSwipe: false,
                  children: [
                    MultiSliver(
                      children: const [
                        SliverToBoxAdapter(child: Text('Page A')),
                      ],
                    ),
                    MultiSliver(
                      children: const [
                        SliverToBoxAdapter(child: Text('Page B')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Page A'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Page A'), findsOneWidget);
    expect(find.text('Page B'), findsNothing);
  });

  testWidgets('reveals the neighboring page while dragging (pageview effect)', (tester) async {
    await tester.pumpWidget(buildWidget());

    final gesture = await tester.startGesture(tester.getCenter(find.text('Page 1')));
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();
    // The first movement only accepted the gesture; slide once the drag is
    // being tracked.
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();

    // The next page is painted inside the viewport, next to the current one.
    expect(tester.getTopLeft(find.text('Page 2')).dx, lessThan(800));
    expect(find.text('Page 1').hitTestable(), findsOneWidget);

    // Release with a small net movement: below the swipe thresholds, so it
    // snaps back to the current page.
    await gesture.moveBy(const Offset(180, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Page 1').hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(find.text('Page 2')).dx, greaterThanOrEqualTo(800));
  });

  testWidgets('slides the pages in sync with the finger', (tester) async {
    await tester.pumpWidget(buildWidget());

    final gesture = await tester.startGesture(tester.getCenter(find.text('Page 1')));
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-250, 0));
    await tester.pump();

    // Dragging further slides the next page further into the viewport.
    expect(tester.getTopLeft(find.text('Page 2')).dx, lessThan(650));
  });

  testWidgets('moves the TabBar indicator with the drag', (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildWidget(controller: controller));

    final gesture = await tester.startGesture(tester.getCenter(find.text('Page 1')));
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();

    // Swiping left reveals the next tab, which moves the controller animation
    // towards it, exactly like a TabBarView.
    expect(controller.offset, closeTo(150 / 800, 0.05));

    await gesture.moveBy(const Offset(-250, 0));
    await tester.pump();
    expect(controller.offset, closeTo(400 / 800, 0.05));

    await gesture.moveBy(const Offset(400, 0));
    await tester.pump();
    expect(controller.offset, closeTo(0, 0.05));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.index, 0);
    expect(controller.animation!.value, 0);
  });

  testWidgets('switching by swipe keeps the TabBar indicator in sync', (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildWidget(controller: controller));

    await tester.drag(find.text('Page 1'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(controller.index, 1);
    // The offset was reset as part of the tab switch, so the indicator is
    // sitting exactly on the new tab without animating on its own.
    expect(controller.animation!.value, 1);
    expect(controller.offset, 0);
    expect(find.text('Page 2'), findsOneWidget);
  });

  testWidgets('dragging while a tab tap animation runs does not crash', (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildWidget(controller: controller));

    await tester.tap(find.text('Two'));
    await tester.pump(const Duration(milliseconds: 50));

    // indexIsChanging is true while the tap animation runs; the swipe keeps
    // sliding the content without writing to the controller's offset.
    await tester.drag(find.text('Page 2'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(controller.index, 1);
    expect(find.text('Page 2'), findsOneWidget);
  });
}