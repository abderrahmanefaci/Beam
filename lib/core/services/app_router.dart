import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:beam/core/services/auth_provider.dart';
import 'package:beam/features/auth/login_screen.dart';
import 'package:beam/features/auth/signup_screen.dart';
import 'package:beam/features/splash/splash_screen.dart';
import 'package:beam/features/onboarding/onboarding_screen.dart';
import 'package:beam/features/home/home_screen.dart';
import 'package:beam/features/scanner/scanner_screen.dart';
import 'package:beam/features/library/library_screen.dart';
import 'package:beam/features/document_viewer/document_viewer_screen.dart';
import 'package:beam/features/ai/ai_result_screen.dart';
import 'package:beam/features/profile/profile_screen.dart';
import 'package:beam/features/paywall/paywall_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  redirect: (BuildContext context, GoRouterState state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isAuthenticated;
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    final isPublicRoute = state.matchedLocation == '/splash' || state.matchedLocation == '/onboarding';

    if (!isLoggedIn && !isAuthRoute && !isPublicRoute) {
      return '/login';
    }
    if (isLoggedIn && isAuthRoute) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/scanner', builder: (context, state) => const ScannerScreen()),
    GoRoute(path: '/library', builder: (context, state) => const LibraryScreen()),
    GoRoute(path: '/document-viewer', builder: (context, state) => DocumentViewerScreen(document: state.extra as Map<String, dynamic>?)),
    GoRoute(path: '/ai-result', builder: (context, state) => AIResultScreen(
      task: (state.extra as Map<String, dynamic>)['task'] as String,
      result: (state.extra as Map<String, dynamic>)['result'] as String,
      modelUsed: (state.extra as Map<String, dynamic>)['model_used'] as String,
      tokensUsed: (state.extra as Map<String, dynamic>)['tokens_used'] as int,
    )),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/paywall', builder: (context, state) => const PaywallScreen()),
  ],
);