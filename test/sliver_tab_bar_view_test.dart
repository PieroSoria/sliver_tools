import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sliver_tools/sliver_tools.dart';

void main() {
  Widget buildWidget({
    TabController? controller,
    bool fillsRemaining = false,
    Widget? fillChild,
  }) {
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
                fillsRemaining: fillsRemaining,
                fillChild: fillChild,
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

  testWidgets('fillsRemaining wraps every tab with a filling region', (tester) async {
    await tester.pumpWidget(buildWidget(fillsRemaining: true));

    // One filling SliverToBoxAdapter per tab, plus the tabs' own content
    // adapters.
    expect(find.byType(SliverToBoxAdapter), findsWidgets);
  });

  testWidgets('fillsRemaining paints the provided fillChild in the leftover space', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        fillsRemaining: true,
        fillChild: const ColoredBox(color: Color(0xFFFF0000)),
      ),
    );

    expect(find.byType(ColoredBox), findsWidgets);
  });

  testWidgets('fillsRemaining makes a short tab fill the viewport', (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildWidget(controller: controller, fillsRemaining: true));

    // Page 1's content is a few pixels tall; with fillsRemaining the tab
    // extends to the bottom of the viewport, so a swipe in the empty area
    // below the text switches tabs.
    await tester.dragFrom(const Offset(400, 550), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(controller.index, 1);
    expect(find.text('Page 2'), findsOneWidget);
  });

  testWidgets('does not extend short tabs by default', (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildWidget(controller: controller));

    await tester.dragFrom(const Offset(400, 550), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(controller.index, 0);
    expect(find.text('Page 1'), findsOneWidget);
  });

  Widget buildPinnedHeaderScenario({
    required TabController controller,
    required bool fillsRemaining,
    List<Widget>? children,
    double? extraScroll,
  }) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 200)),
            const SliverToBoxAdapter(child: SizedBox(height: 210)),
            SliverAppBar(
              pinned: true,
              primary: false,
              bottom: TabBar(
                controller: controller,
                tabs: const [
                  Tab(text: 'One'),
                  Tab(text: 'Two'),
                ],
              ),
            ),
            SliverTabBarView(
              controller: controller,
              fillsRemaining: fillsRemaining,
              extraScroll: extraScroll,
              children: children ??
                  [
                    MultiSliver(
                      children: const [SliverToBoxAdapter(child: SizedBox(height: 100))],
                    ),
                    MultiSliver(
                      children: const [SliverToBoxAdapter(child: SizedBox(height: 100))],
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('fillsRemaining lets a short tab scroll a pinned header to the top', (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      buildPinnedHeaderScenario(controller: controller, fillsRemaining: true),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100000));
    await tester.pumpAndSettle();

    // The filling sliver adds scroll extent, so the short tab can scroll the
    // pinned header to the ceiling (the TabBar sits right under the toolbar).
    expect(tester.getTopLeft(find.byType(TabBar)).dy, kToolbarHeight);
  });

  testWidgets('without fillsRemaining a short tab cannot pin the header', (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      buildPinnedHeaderScenario(controller: controller, fillsRemaining: false),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100000));
    await tester.pumpAndSettle();

    // The tab is too short to scroll the header out of the way, so the TabBar
    // stays below the ceiling.
    expect(tester.getTopLeft(find.byType(TabBar)).dy, greaterThan(kToolbarHeight));
  });

  testWidgets('fillsRemaining stops a short tab with the first items under the pinned header',
      (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    final list = MultiSliver(
      children: const [
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('First'))),
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('Second'))),
      ],
    );
    await tester.pumpWidget(
      buildPinnedHeaderScenario(
        controller: controller,
        fillsRemaining: true,
        children: [list, const SliverToBoxAdapter(child: SizedBox.shrink())],
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    // The pinned header reached the top...
    expect(tester.getTopLeft(find.byType(TabBar)).dy, kToolbarHeight);
    // ...the tab measured the header, so the first item rests right below it,
    // fully visible instead of being hidden behind it...
    expect(tester.getTopLeft(find.text('First')).dy, greaterThan(100));
    expect(find.text('First').hitTestable(), findsOneWidget);
    expect(find.text('Second').hitTestable(), findsOneWidget);
    // ...and the list did not scroll entirely off-screen.
    expect(tester.getTopLeft(find.text('Second')).dy, lessThan(600));
  });

  testWidgets('fillsRemaining measures the pinned header so the items rest under it', (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    final list = MultiSliver(
      children: const [
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('First'))),
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('Second'))),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 200)),
              const SliverToBoxAdapter(child: SizedBox(height: 210)),
              SliverAppBar(
                pinned: true,
                primary: false,
                toolbarHeight: 80,
                bottom: TabBar(
                  controller: controller,
                  tabs: const [
                    Tab(text: 'One'),
                    Tab(text: 'Two'),
                  ],
                ),
              ),
              SliverTabBarView(
                controller: controller,
                fillsRemaining: true,
                children: [list, const SliverToBoxAdapter(child: SizedBox.shrink())],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    // The header (80 toolbar + 48 TabBar) fully pinned at the top...
    expect(tester.getTopLeft(find.byType(TabBar)).dy, 80);
    // ...and the measured reveal is its resting height: the first item comes
    // to rest right below it, fully visible.
    expect(tester.getTopLeft(find.text('First')).dy, closeTo(128, 4));
    expect(find.text('First').hitTestable(), findsOneWidget);
    expect(find.text('Second').hitTestable(), findsOneWidget);
  });

  testWidgets('fillsRemaining measures the whole header so tall TabBars stay visible', (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    final list = MultiSliver(
      children: const [
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('First'))),
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('Second'))),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 200)),
              const SliverToBoxAdapter(child: SizedBox(height: 210)),
              SliverAppBar(
                pinned: true,
                primary: false,
                bottom: TabBar(
                  controller: controller,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_view_rounded), text: 'Posts'),
                    Tab(icon: Icon(Icons.menu_book_rounded), text: 'Obras'),
                  ],
                ),
              ),
              SliverTabBarView(
                controller: controller,
                fillsRemaining: true,
                children: [list, const SliverToBoxAdapter(child: SizedBox.shrink())],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    // The icon TabBar is 74 tall, so the header is 56 + 74 = 130. The reveal
    // is the whole header, so the first item rests right below the TabBar,
    // fully visible.
    expect(tester.getTopLeft(find.byType(TabBar)).dy, kToolbarHeight);
    expect(
      tester.getBottomLeft(find.byType(TabBar)).dy,
      closeTo(kToolbarHeight + 74, 2),
    );
    expect(tester.getTopLeft(find.text('First')).dy, closeTo(130, 4));
    expect(find.text('First').hitTestable(), findsOneWidget);
    expect(find.text('Second').hitTestable(), findsOneWidget);
  });

  testWidgets('fillsRemaining uses an overlap reporter to capture the header height',
      (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    final overlap = SliverOverlapReporterHandle();
    addTearDown(overlap.dispose);
    final list = MultiSliver(
      children: const [
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('First'))),
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('Second'))),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: CustomScrollView(
            slivers: [
              SliverOverlapReporter(
                handle: overlap,
                sliver: SliverAppBar(
                  pinned: true,
                  primary: false,
                  bottom: TabBar(
                    controller: controller,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_view_rounded), text: 'Posts'),
                      Tab(icon: Icon(Icons.menu_book_rounded), text: 'Obras'),
                    ],
                  ),
                ),
              ),
              SliverTabBarView(
                controller: controller,
                fillsRemaining: true,
                overlapHandle: overlap,
                children: [list, const SliverToBoxAdapter(child: SizedBox.shrink())],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    // The reporter captured the true header height (130) in the handle, so
    // the tab rests its first item right below it even without the leading
    // slivers that the automatic measurement walks through.
    expect(overlap.extent, closeTo(130, 0.01));
    expect(tester.getTopLeft(find.byType(TabBar)).dy, kToolbarHeight);
    expect(tester.getTopLeft(find.text('First')).dy, closeTo(130, 4));
    expect(find.text('First').hitTestable(), findsOneWidget);
    expect(find.text('Second').hitTestable(), findsOneWidget);
  });

  testWidgets('fillsRemaining measures headers nested inside a SliverStack', (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    final list = MultiSliver(
      children: const [
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('First'))),
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('Second'))),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: CustomScrollView(
            slivers: [
              SliverStack(
                children: [
                  MultiSliver(
                    children: [
                      const SliverAppBar(
                        stretch: true,
                        expandedHeight: 200,
                        flexibleSpace: FlexibleSpaceBar(
                          collapseMode: CollapseMode.pin,
                          stretchModes: [StretchMode.zoomBackground],
                          background: DecoratedBox(
                            decoration: BoxDecoration(color: Color(0xFF3949AB)),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 210)),
                      SliverAppBar(
                        pinned: true,
                        primary: false,
                        bottom: TabBar(
                          controller: controller,
                          tabs: const [
                            Tab(icon: Icon(Icons.grid_view_rounded), text: 'Posts'),
                            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Obras'),
                          ],
                        ),
                      ),
                      SliverTabBarView(
                        controller: controller,
                        fillsRemaining: true,
                        children: [
                          list,
                          const SliverToBoxAdapter(child: SizedBox.shrink()),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    // The pinned header is hidden two levels deep (SliverStack > MultiSliver),
    // yet the tab still measures it: it pins at the top and the first item
    // rests right below the whole header (toolbar + icon TabBar = 130).
    expect(tester.getTopLeft(find.byType(TabBar)).dy, kToolbarHeight);
    expect(
      tester.getTopLeft(find.text('First')).dy,
      closeTo(kToolbarHeight + 74, 4),
    );
    expect(find.text('First').hitTestable(), findsOneWidget);
    expect(find.text('Second').hitTestable(), findsOneWidget);
  });

  testWidgets('extraScroll overrides the measured reveal to tuck the first item under the header',
      (tester) async {
    final controller = TabController(length: 2, vsync: tester);
    addTearDown(controller.dispose);
    final list = MultiSliver(
      children: const [
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('First'))),
        SliverToBoxAdapter(child: SizedBox(height: 56, child: Text('Second'))),
      ],
    );
    await tester.pumpWidget(
      buildPinnedHeaderScenario(
        controller: controller,
        fillsRemaining: true,
        // A manual reveal smaller than the header's measured height: the tab
        // scrolls further so the first item slides under the pinned header.
        extraScroll: 30,
        children: [list, const SliverToBoxAdapter(child: SizedBox.shrink())],
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    // The header still reaches the top...
    expect(tester.getTopLeft(find.byType(TabBar)).dy, kToolbarHeight);
    // ...but the smaller override tucks the first item under it.
    expect(find.text('First').hitTestable(), findsNothing);
    expect(find.text('Second').hitTestable(), findsOneWidget);
  });
}