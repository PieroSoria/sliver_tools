import 'package:material_ui/material_ui.dart';

/// [SliverTabBarView] is a sliver that renders a list of slivers (one per tab)
/// inside a [TabBarView], so each tab can have its own scrollable sliver
/// content such as a [MultiSliver]. Use it directly inside a
/// [CustomScrollView]'s `slivers` list.
///
/// A sliver cannot live inside a [TabBarView] directly because its pages need a
/// bounded height in order to scroll. [SliverTabBarView] solves this by
/// wrapping each entry of [slivers] in its own [CustomScrollView], placing
/// those into the [TabBarView], and then turning the whole thing into a sliver:
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
///           slivers: [
///             MultiSliver(
///               children: [
///                 SliverToBoxAdapter(child: Text('Page A')),
///               ],
///             ),
///             MultiSliver(
///               children: [
///                 SliverToBoxAdapter(child: Text('Page B')),
///               ],
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
    required this.slivers,
    this.controller,
    this.physics,
    this.height,
  });

  /// One sliver (or multi-sliver group such as [MultiSliver]) per tab. Each
  /// entry is wrapped in its own [CustomScrollView].
  final List<Widget> slivers;

  /// The [TabController] that drives the [TabBarView]. When null a
  /// [DefaultTabController] ancestor is used.
  final TabController? controller;

  /// The scroll physics applied to each of the [CustomScrollView]s that wrap
  /// the entries of [slivers].
  final ScrollPhysics? physics;

  /// The height given to the [TabBarView]. When null the [TabBarView] fills
  /// the remaining viewport extent.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final pages = [
      for (final sliver in slivers)
        CustomScrollView(
          physics: physics,
          slivers: [sliver],
        ),
    ];

    final tabBarView = controller == null
        ? TabBarView(children: pages)
        : TabBarView(controller: controller, children: pages);

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