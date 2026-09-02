import 'package:flutter_test/flutter_test.dart';

import 'package:sliver_tools_example/main.dart';

void main() {
  testWidgets('SliverTabBarView renders tab pages', (tester) async {
    await tester.pumpWidget(const SliverToolsExampleApp());

    expect(find.text('Feed'), findsNWidgets(2)); // tab label + page header
    expect(find.text('Grid'), findsOneWidget); // tab label only
    expect(find.text('Nested'), findsOneWidget); // tab label only

    expect(find.textContaining('Feed item'), findsWidgets);
  });

  testWidgets('switches between tab pages', (tester) async {
    await tester.pumpWidget(const SliverToolsExampleApp());

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();

    expect(find.text('Grid'), findsNWidgets(2)); // tab label + page header

    await tester.tap(find.text('Nested'));
    await tester.pumpAndSettle();

    expect(find.text('Nested'), findsNWidgets(2)); // tab label + page header
    expect(find.textContaining('Nested item'), findsWidgets);
  });
}
