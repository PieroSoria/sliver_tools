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
    expect(find.text('Page 2'), findsNothing);
  });

  testWidgets('switches between tabs when a tab is tapped', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();

    expect(find.text('Page 1'), findsNothing);
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
}