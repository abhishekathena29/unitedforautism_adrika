import 'package:flutter/material.dart';

/// Small navigation helpers used across every screen, replacing React
/// Navigation's `navigation.navigate(name, params)` / `route.params`.

/// Reads the current route's arguments, mirroring `route.params` in RN.
Map<String, dynamic> routeArgs(BuildContext context) {
  final args = ModalRoute.of(context)?.settings.arguments;
  return args is Map<String, dynamic> ? args : <String, dynamic>{};
}

extension NavigationX on BuildContext {
  /// Equivalent of `navigation.navigate('RouteName', params)` when pushing
  /// a new screen onto the current tab's stack.
  Future<T?> pushNamed<T extends Object?>(String routeName,
      {Map<String, dynamic>? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Equivalent of `navigation.goBack()`.
  void goBack<T extends Object?>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  bool get canGoBack => Navigator.of(this).canPop();
}

/// Tracks the name of the topmost active route across the whole app so the
/// floating ChatbotButton can hide itself on the same screens the RN app
/// hides it on (see `CHATBOT_HIDDEN_SCREENS` in AppNavigator.tsx).
class ActiveRoute extends ChangeNotifier {
  ActiveRoute._();
  static final ActiveRoute instance = ActiveRoute._();

  String? name;

  void update(String? routeName) {
    if (routeName == null || routeName == name) return;
    name = routeName;
    notifyListeners();
  }
}

/// Lets a screen reload its data when it regains focus (a
/// `RouteAware.didPopNext`), mirroring React Navigation's `useFocusEffect`.
/// Each tab in `main_tabs.dart` has its own dedicated `RouteObserver<PageRoute>`
/// (a single shared instance can't observe more than one `Navigator` at once —
/// and `MainTabsScreen`'s `IndexedStack` keeps all 4 tab `Navigator`s mounted
/// simultaneously), so [AppRouteAware] finds the right one by looking through
/// the nearest ancestor `Navigator`'s own `observers` list instead of
/// referencing a single global instance.
mixin AppRouteAware<T extends StatefulWidget> on State<T>
    implements RouteAware {
  RouteObserver<PageRoute>? _routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    RouteObserver<PageRoute>? observer;
    if (route is PageRoute) {
      for (final o in Navigator.of(context).widget.observers) {
        if (o is RouteObserver<PageRoute>) {
          observer = o;
          break;
        }
      }
    }
    if (identical(observer, _routeObserver)) return;
    _routeObserver?.unsubscribe(this);
    _routeObserver = observer;
    if (route is PageRoute) observer?.subscribe(this, route);
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}

  @override
  void didPopNext() => onRefocus();

  /// Called when this screen becomes visible again after a screen pushed
  /// on top of it is popped, matching RN's `useFocusEffect` re-run.
  void onRefocus();
}

class RouteNameObserver extends NavigatorObserver {
  void _report(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) ActiveRoute.instance.update(name);
  }

  @override
  void didPush(Route route, Route? previousRoute) => _report(route);

  @override
  void didPop(Route route, Route? previousRoute) => _report(previousRoute);

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _report(newRoute);
}

/// Screens hidden from the floating chatbot, ported verbatim from
/// `CHATBOT_HIDDEN_SCREENS` in `src/navigation/AppNavigator.tsx`.
const Set<String> kChatbotHiddenScreens = {
  'Welcome',
  'Signup',
  'Login',
  'ForgotPassword',
  'EmotionalShareReplies',
  'SpaceDetail',
  'CreatePost',
  'PostDetail',
};

/// Lets any screen jump to a different bottom tab, mirroring
/// `navigation.navigate('EventsTab')` from a nested stack screen.
class MainTabsController extends ChangeNotifier {
  MainTabsController._();
  static final MainTabsController instance = MainTabsController._();

  int index = 0;

  static const Map<String, int> tabIndexByName = {
    'HomeTab': 0,
    'SpacesTab': 1,
    'EventsTab': 2,
    'LearnTab': 3,
  };

  /// Each tab's own `Navigator` key, registered by `main_tabs.dart`, so a
  /// screen on one tab can push a route onto a *different* tab's stack
  /// (mirrors RN's `navigation.navigate('HomeTab', { screen: 'Profile' })`).
  final List<GlobalKey<NavigatorState>?> tabNavigatorKeys =
      List.filled(4, null);

  void switchTo(String tabName) {
    final i = tabIndexByName[tabName];
    if (i == null || i == index) return;
    index = i;
    notifyListeners();
  }

  void switchToIndex(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }

  /// Switches to [tabName] and pushes [routeName] onto that tab's own
  /// stack, equivalent to `navigation.navigate('SomeTab', { screen, params })`.
  Future<T?> pushOnTab<T extends Object?>(
    String tabName,
    String routeName, {
    Map<String, dynamic>? arguments,
  }) async {
    final i = tabIndexByName[tabName];
    if (i == null) return null;
    switchToIndex(i);
    // Let the IndexedStack build the target tab before pushing onto it.
    await Future<void>.delayed(Duration.zero);
    return tabNavigatorKeys[i]
        ?.currentState
        ?.pushNamed<T>(routeName, arguments: arguments);
  }
}
