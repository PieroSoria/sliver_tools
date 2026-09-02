import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

void main() => runApp(const SliverToolsExampleApp());

/// Example app demonstrating [SliverTabBarView], which renders one sliver
/// (e.g. a [MultiSliver]) per tab inside a [TabBarView].
class SliverToolsExampleApp extends StatelessWidget {
  const SliverToolsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sliver_tools example',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SliverTabBarView'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Grid'),
            Tab(text: 'Nested'),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'SliverTabBarView lives inside this CustomScrollView.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
          ),
          SliverTabBarView(
            controller: _tabController,
            slivers: const [
              FeedPage(),
              GridPage(),
              NestedPage(),
            ],
          ),
        ],
      ),
    );
  }
}

/// A simple multi-sliver page: a pinned header followed by a lazy list.
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      pushPinnedChildren: true,
      children: [
        const SliverPersistentHeader(
          pinned: true,
          delegate: _SectionHeaderDelegate('Feed', Colors.indigo),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => ListTile(
              leading: const Icon(Icons.article),
              title: Text('Feed item $i'),
              trailing: const Icon(Icons.chevron_right),
            ),
            childCount: 50,
          ),
        ),
      ],
    );
  }
}

/// A multi-sliver page that combines a header with a grid.
class GridPage extends StatelessWidget {
  const GridPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MultiSliver(
      children: [
        const SliverPersistentHeader(
          pinned: true,
          delegate: _SectionHeaderDelegate('Grid', Colors.teal),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (var i = 0; i < 18; i++)
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('$i')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A multi-sliver page that stacks several sliver sections together.
class NestedPage extends StatelessWidget {
  const NestedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      pushPinnedChildren: true,
      children: [
        const SliverPersistentHeader(
          pinned: true,
          delegate: _SectionHeaderDelegate('Nested', Colors.deepOrange),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'MultiSliver lets you group several slivers into one page.',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => ListTile(
              leading: const Icon(Icons.collections_bookmark),
              title: Text('Nested item $i'),
            ),
            childCount: 30,
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SectionHeaderDelegate(this.title, this.color);

  final String title;
  final Color color;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: color,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return oldDelegate.title != title || oldDelegate.color != color;
  }
}
