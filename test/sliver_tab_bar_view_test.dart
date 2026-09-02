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
            bottom: const TabBar(
              tabs: [
                Tab(text: 'One'),
                Tab(text: 'Two'),
              ],
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverTabBarView(
                controller: controller,
                children: const [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: Text('Page 1')),
                    ],
                  ),
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: Text('Page 2')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('renders the first page inside a CustomScrollView', (
    tester,
  ) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);
  });

  testWidgets('switches between pages when a tab is tapped', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();

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

  testWidgets('uses a fixed height when height is provided', (tester) async {
    await tester.pumpWidget(
      const DefaultTabController(
        length: 2,
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverTabBarView(
                  height: 200,
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: Text('Page 1')),
                      ],
                    ),
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: Text('Page 2')),
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

    final size = tester.getSize(find.byType(TabBarView));
    expect(size.height, 200);
  });
}