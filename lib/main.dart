import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'home_page.dart';
import 'landing_page.dart';
import 'services/app_services.dart';
import 'services/cart_service.dart';
import 'widgets/state_views.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.init();
  runApp(const TeraFarmApp());
}

class TeraFarmApp extends StatelessWidget {
  const TeraFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CartService>.value(
      value: AppServices.cart,
      child: MaterialApp(
        title: 'TeraFarm',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthWrapper(),
        builder: (context, child) {
          final content = child ?? const SizedBox.shrink();
          if (!AppConfig.demoMode) return content;
          return DemoBanner(child: content);
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppServices.initError != null && !AppConfig.demoMode) {
      return Scaffold(
        body: ErrorView(
          message: AppServices.initError!,
        ),
      );
    }

    return StreamBuilder(
      stream: AppServices.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingView(message: 'Starting TeraFarm…'),
          );
        }
        // Landing handles Get Started / auto-redirect for logged-in users.
        return const LandingPage();
      },
    );
  }
}

/// Convenience for tests that need a logged-in shell.
class AuthenticatedShell extends StatelessWidget {
  const AuthenticatedShell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppServices.auth.currentUser;
    if (user == null) return const LandingPage();
    return const HomePage();
  }
}
