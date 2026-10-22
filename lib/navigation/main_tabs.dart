import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';
import 'nav.dart';
import 'routes.dart';

/// One tab's own navigation stack, mirroring a `createNativeStackNavigator()`
/// tree from `AppNavigator.tsx` (HomeStack / SpacesStack / EventsStack / LearnStack).
class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final String initialRoute;
  final RouteObserver<PageRoute> routeObserver;

  const _TabNavigator({
    required this.navigatorKey,
    required this.initialRoute,
    required this.routeObserver,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      initialRoute: initialRoute,
      // Each tab needs its own dedicated `RouteObserver` instance — a single
      // shared one can't attach to more than one `Navigator` at a time, and
      // `IndexedStack` below keeps all 4 tab `Navigator`s mounted at once.
      observers: [RouteNameObserver(), routeObserver],
      onGenerateRoute: (settings) {
        final builder = innerScreenBuilders[settings.name] ??
            innerScreenBuilders[initialRoute]!;
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}

/// Direct port of `MainTabs()` in `src/navigation/AppNavigator.tsx`.
class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  final _tabKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());
  // One dedicated instance per tab, created once so it stays stable across
  // rebuilds (e.g. on every tab switch) instead of being replaced — a fresh
  // instance on every build would silently drop any screen's subscription
  // via `AppRouteAware`.
  final _tabRouteObservers =
      List.generate(4, (_) => RouteObserver<PageRoute>());
  final _controller = MainTabsController.instance;

  static const _initialRoutes = ['Home', 'Spaces', 'Events', 'Learn'];
  static const _labels = ['Home', 'Spaces', 'Events', 'Learn'];
  static const _icons = [
    LucideIcons.home,
    LucideIcons.users,
    LucideIcons.calendar,
    LucideIcons.bookOpen
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTabChanged);
    for (var i = 0; i < _tabKeys.length; i++) {
      _controller.tabNavigatorKeys[i] = _tabKeys[i];
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
    for (var i = 0; i < _controller.tabNavigatorKeys.length; i++) {
      if (_controller.tabNavigatorKeys[i] == _tabKeys[i]) {
        _controller.tabNavigatorKeys[i] = null;
      }
    }
    super.dispose();
  }

  void _onTabChanged() => setState(() {});

  void _onTap(int index) {
    if (index == _controller.index) {
      // Tapping the active tab again pops that stack back to its root,
      // matching React Navigation's default tab-bar behavior.
      _tabKeys[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    _controller.switchToIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final nav = _tabKeys[_controller.index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _controller.index,
          children: List.generate(
            4,
            (i) => _TabNavigator(
                navigatorKey: _tabKeys[i],
                initialRoute: _initialRoutes[i],
                routeObserver: _tabRouteObservers[i]),
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: List.generate(4, (i) {
                  final active = i == _controller.index;
                  final color =
                      active ? AppColors.primary : AppColors.mutedForeground;
                  return Expanded(
                    child: InkWell(
                      onTap: () => _onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_icons[i], color: color, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            _labels[i],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
