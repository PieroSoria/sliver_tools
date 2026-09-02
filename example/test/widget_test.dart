import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:sliver_tools_example/main.dart';

void main() {
  testWidgets('SliverTabBarView renders the posts tab', (tester) async {
    await tester.pumpWidget(const SliverToolsExampleApp());

    expect(find.text('Posts'), findsOneWidget); // tab label
    expect(find.text('Obras'), findsOneWidget); // tab label
    expect(find.text('Música'), findsOneWidget); // tab label

    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // first grid cell

    // Solo hay un CustomScrollView: el contenido de la pestaña comparte su scroll.
    expect(find.byType(CustomScrollView), findsOneWidget);
  });

  testWidgets('tab content scrolls together with the parent', (tester) async {
    await tester.pumpWidget(const SliverToolsExampleApp());

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(position.pixels, 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(position.pixels, greaterThan(0));
  });
}