import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/forgot_password_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/welcome_screen.dart';
import '../state/auth_provider.dart';
import '../theme/theme.dart';
import '../widgets/chatbot_button.dart';
import 'main_tabs.dart';
import 'nav.dart';

/// Direct port of `AppNavigator()` in `src/navigation/AppNavigator.tsx`:
/// picks the root route (auth flow vs. main app) and overlays the floating
/// ChatbotButton on every screen except the hidden set.
class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    ActiveRoute.instance.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    ActiveRoute.instance.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    // `RouteNameObserver.didPush` fires synchronously from inside a
    // `Navigator`'s own build/transition (including the very first frame,
    // when `AppNavigator`'s own `Navigator` pushes its `initialRoute`).
    // Calling `setState` immediately would re-enter this element's build
    // while it's still on the dirty-elements stack, tripping a `!_dirty`
    // assertion — so defer the rebuild until the current frame is done.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final builders = <String, WidgetBuilder>{
      'Welcome': (_) => const WelcomeScreen(),
      'Signup': (_) => const SignupScreen(),
      'Login': (_) => const LoginScreen(),
      'ForgotPassword': (_) => const ForgotPasswordScreen(),
      'MainTabs': (_) => const MainTabsScreen(),
    };
    final builder = builders[settings.name] ?? builders['Welcome']!;
    return MaterialPageRoute(builder: builder, settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const ColoredBox(
        color: AppColors.background,
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final initialRoute =
        (auth.session != null || auth.isGuest) ? 'MainTabs' : 'Welcome';
    final showChatbot =
        !kChatbotHiddenScreens.contains(ActiveRoute.instance.name);

    return Stack(
      children: [
        Navigator(
          key: _rootNavigatorKey,
          initialRoute: initialRoute,
          observers: [RouteNameObserver()],
          onGenerateRoute: _onGenerateRoute,
        ),
        if (showChatbot) const ChatbotButton(),
      ],
    );
  }
}
