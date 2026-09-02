# sliver_tools example

![Demo](https://raw.githubusercontent.com/Kavantix/sliver_tools/master/gifs/demo2.gif)

Run the example app:

```
cd example
flutter run
```

## SliverTabBarView example

The runnable app in `lib/main.dart` demonstrates `SliverTabBarView`, which
renders one scrollable page (a `CustomScrollView`) per tab inside a
`TabBarView`. It is used **inside a `CustomScrollView`**, after a small
leading sliver:

* **Feed** – a `MultiSliver` with a pinned header and a lazy `SliverList`.
* **Grid** – a `MultiSliver` with a header and a `SliverGrid`.
* **Nested** – a `MultiSliver` stacking several sliver sections.

The `TabBar` lives in the `AppBar`, completely separate from
`SliverTabBarView`, and is synchronized through a `DefaultTabController`.

Other example usage can be found
[HERE](https://github.com/Kavantix/hn_state_example/blob/master/lib/ui/pages/news/news_page.dart)
