import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:sliver_tools/sliver_tools.dart';

void main() => runApp(const SliverToolsExampleApp());

/// Example app demonstrating [SliverTabBarView] inside an [CustomScrollView]
/// with a [SliverStack]: a banner, a pinned [TabBar] and the active tab's
/// slivers all scroll together, while overlays stay fixed using
/// [SliverPositioned].
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
  late ScrollController _scrollController;
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);
  static const double _speedFactor = 10.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    _scrollOffset.value = _scrollController.offset;
  }

  double _positionInfo(double value) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final base = isIOS ? 230.0 : 210.0;
    return math.max(
      0.0,
      base - (value / (value.isNegative ? 1 : _speedFactor)),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: ValueListenableBuilder<double>(
          valueListenable: _scrollOffset,
          builder: (context, value, _) {
            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverStack(
                  children: [
                    // ── CONTENIDO PRINCIPAL ────────────────────────────────
                    MultiSliver(
                      children: [
                        // Banner con stretch (equivalente a tu BannerWidget)
                        SliverAppBar(
                          stretch: true,
                          expandedHeight: 200,
                          flexibleSpace: const FlexibleSpaceBar(
                            collapseMode: CollapseMode.pin,
                            stretchModes: [
                              StretchMode.zoomBackground,
                              StretchMode.blurBackground,
                            ],
                            background: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF3949AB),
                                    Color(0xFF8E24AA),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Espacio que ocupará la información superpuesta
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 210),
                        ),

                        // ── TABBAR PERSISTENTE ─────────────────────────────
                        SliverAppBar(
                          pinned: true,
                          primary: false,
                          bottom: TabBar(
                            controller: _tabController,
                            indicatorColor: Colors.pinkAccent,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: Colors.pinkAccent,
                            unselectedLabelColor: Colors.grey,
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.grid_view_rounded),
                                text: 'Posts',
                              ),
                              Tab(
                                icon: Icon(Icons.menu_book_rounded),
                                text: 'Obras',
                              ),
                              Tab(
                                icon: Icon(Icons.music_note_rounded),
                                text: 'Música',
                              ),
                            ],
                          ),
                        ),

                        // ── VISTAS DEL TABBAR ──────────────────────────────
                        // Reemplaza el clásico SliverFillRemaining + TabBarView:
                        // solo los slivers de la pestaña activa se insertan en
                        // este CustomScrollView, así que comparten SU scroll.
                        SliverTabBarView(
                          controller: _tabController,
                          children: const [
                            PostsPage(),
                            WorksPage(),
                            MusicPage(),
                          ],
                        ),
                      ],
                    ),

                    // ── INFO SUPUESTA (avatar, usuario, logros) ────────────
                    SliverPositioned.fill(
                      top: _positionInfo(value),
                      child: const _ProfileInfoOverlay(),
                    ),

                    // ── BOTÓN DE AJUSTES ───────────────────────────────────
                    SliverPositioned.fill(
                      left: size.width - 55,
                      bottom: (size.height / 1.25) -
                          (defaultTargetPlatform == TargetPlatform.iOS
                              ? 25
                              : 0),
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 34,
                          height: 34,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x1AFFFFFF),
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Slivers de la pestaña Posts (reemplaza tu GridPostsWidget, que además del
/// CustomScrollView debe devolver directamente estos [MultiSliver]).
class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      children: [
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
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$i',
                      style: TextStyle(color: Colors.indigo.shade900),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Slivers de la pestaña Obras (reemplaza tu ListWorkWidget).
class WorksPage extends StatelessWidget {
  const WorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      children: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: Text('Obra item $i'),
              trailing: const Icon(Icons.chevron_right),
            ),
            childCount: 40,
          ),
        ),
      ],
    );
  }
}

/// Slivers de la pestaña Música (reemplaza tu ListMusicWidget).
class MusicPage extends StatelessWidget {
  const MusicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      children: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => ListTile(
              leading: const Icon(Icons.music_note_rounded),
              title: Text('Canción $i'),
              subtitle: const Text('sliver_tools demo'),
              trailing: const Icon(Icons.play_circle_outline),
            ),
            childCount: 40,
          ),
        ),
      ],
    );
  }
}

/// Información del perfil superpuesta sobre el banner. Reemplaza tu
/// InfoProfileWidget.
class _ProfileInfoOverlay extends StatelessWidget {
  const _ProfileInfoOverlay();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final texts = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: colors.primaryContainer,
                child: const Icon(Icons.person, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sliver Tools', style: texts.titleMedium),
                    Text('sliver_tools example', style: texts.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.qr_code_2_rounded, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stats(label: 'Publicaciones', value: '234'),
              _Stats(label: 'Seguidores', value: '1.2k'),
              _Stats(label: 'Siguiendo', value: '890'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionAchievementsHeader(
            title: 'Logros',
            linkText: 'Ver todos',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: texts.titleSmall),
        Text(label, style: texts.bodySmall),
      ],
    );
  }
}

class _SectionAchievementsHeader extends StatelessWidget {
  const _SectionAchievementsHeader({
    required this.title,
    required this.linkText,
    required this.onTap,
  });

  final String title;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colors = themeData.colorScheme;
    final texts = themeData.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: texts.titleSmall),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  linkText,
                  style: texts.labelSmall?.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => CircleAvatar(
              radius: 28,
              backgroundColor: colors.secondaryContainer,
              child: Text(
                String.fromCharCode(65 + i),
                style: texts.titleMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}