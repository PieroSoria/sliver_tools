import 'package:material_ui/material_ui.dart';

/// [SliverTabBarView] is a sliver that shows one of several sliver groups
/// depending on the active tab. Use it directly inside a
/// [CustomScrollView]'s `slivers` list.
///
/// Each entry in [children] is the content of one tab and must be a sliver
/// (for example a [MultiSliver] wrapping several slivers). Only the slivers of
/// the active tab are inserted into the [CustomScrollView], so the tab content
/// **shares the parent's scroll** — there is no nested viewport. This is the
/// classic profile-page layout where headers, posts and works all scroll
/// together.
///
/// Switching tabs is done through the [TabBar] (tab taps); there is no
/// horizontal swipe between tabs because the content is laid out as regular
/// slivers of the parent's viewport.
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
///         const SliverToBoxAdapter(child: Text('Leading content')),
///         const SliverTabBarView(
///           children: [
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
///         const SliverToBoxAdapter(child: Text('Trailing content')),
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
  });

  /// The content of each tab. Every entry must be a sliver (use a
  /// [MultiSliver] to group several slivers into one tab).
  final List<Widget> children;

  /// The [TabController] that drives the tabs. When null a
  /// [DefaultTabController] ancestor is used.
  final TabController? controller;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller ?? DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => children[controller.index],
    );
  }
}