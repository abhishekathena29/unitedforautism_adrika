import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'navigation/app_navigator.dart';
import 'state/auth_provider.dart';
import 'state/community_provider.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const App());
}

/// Direct port of `App.tsx`.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CommunityProvider>(
          create: (_) => CommunityProvider(),
          update: (_, auth, community) {
            final community_ = community ?? CommunityProvider();
            final userId = auth.isGuest ? null : auth.user?.id;
            community_.setUserId(userId);
            return community_;
          },
        ),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: AppColors.background,
        ),
        child: MaterialApp(
          title: 'United for Autism',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const Scaffold(
            backgroundColor: AppColors.background,
            body: AppNavigator(),
          ),
        ),
      ),
    );
  }
}
