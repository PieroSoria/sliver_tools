import 'package:material_ui/material_ui.dart';

/// [SliverTabBarView] is a sliver that renders a list of pages (one per tab)
/// inside a [TabBarView]. Use it directly inside a [CustomScrollView]'s
/// `slivers` list.
///
/// Each page in [children] is expected to be scrollable on its own (for
/// example a [CustomScrollView], a [ListView] or a [GridView]);
/// [SliverTabBarView] adds the horizontal swipe between them and turns the
/// whole thing into a sliver with a bounded height:
///
/// * When [height] is provided the [TabBarView] is given that fixed height and
///   wrapped in a [SliverToBoxAdapter].
/// * Otherwise it fills the remaining viewport extent.
///
/// The [TabBar] itself is **not** part of this widget. Drive the tabs with
/// your own [TabController] (or a [DefaultTabController] ancestor) and place
/// the [TabBar] wherever you like.
///
/// Typical usage:
///
/// ```dart
/// DefaultTabController(
///   length: 2,
///   child: Scaffold(
///     body: CustomScrollView(
///       slivers: [
///         SliverToBoxAdapter(child: Text('Leading content')),
///         const SliverTabBarView(
///           children: [
///             CustomScrollView(
///               slivers: [
///                 SliverToBoxAdapter(child: Text('Page A')),
///               ],
///             ),
///             ListView(
///               children: [Text('Page B')],
///             ),
///           ],
///         ),
///         SliverToBoxAdapter(child: Text('Trailing content')),
///       ],
///     ),
///   ),
/// )
/// ```
class SliverTabBarView extends StatelessWidget {
  const SliverTabBarView({
    super.key,
    required this.children,
    this.controller,
    this.height,
  });

  /// One scrollable page per tab.
  final List<Widget> children;

  /// The [TabController] that drives the [TabBarView]. When null a
  /// [DefaultTabController] ancestor is used.
  final TabController? controller;

  /// The height given to the [TabBarView]. When null the [TabBarView] fills
  /// the remaining viewport extent.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final tabBarView = controller == null
        ? TabBarView(children: children)
        : TabBarView(controller: controller, children: children);

    final height = this.height;
    if (height != null) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: tabBarView,
        ),
      );
    }
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverToBoxAdapter(
        child: SizedBox(
          height: constraints.remainingPaintExtent,
          width: double.infinity,
          child: tabBarView,
        ),
      ),
    );
  }
}