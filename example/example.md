# sliver_tools example

![Demo](https://raw.githubusercontent.com/Kavantix/sliver_tools/master/gifs/demo2.gif)

Run the example app:

```
cd example
flutter run
```

## SliverTabBarView example

The runnable app in `lib/main.dart` demonstrates `SliverTabBarView` with the
classic profile-page layout: a `SliverStack` whose main content is a
`MultiSliver` with a stretchable banner, a placeholder, a pinned `TabBar` and
the `SliverTabBarView`. Tab content **shares the parent's scroll**: only the
slivers of the active tab are inserted into the same `CustomScrollView`, so
header, posts and works all scroll together — there is no nested viewport.

Overlays (`InfoProfileWidget` style info and a floating settings button) are
kept on top with `SliverPositioned.fill`, exactly like the layout used by the
repo author's profile app.

* **Posts** – a `MultiSliver` containing a `SliverGrid` (like `GridPostsWidget`).
* **Obras** – a `MultiSliver` containing a `SliverList` (like `ListWorkWidget`).
* **Música** – a `MultiSliver` containing a `SliverList` (like `ListMusicWidget`).

The three tabs are driven by a `TabController` created in `_HomePageState`
(`TickerProviderStateMixin`) and shared by the `TabBar` and
`SliverTabBarView`.

Other example usage can be found
[HERE](https://github.com/Kavantix/hn_state_example/blob/master/lib/ui/pages/news/news_page.dart)
