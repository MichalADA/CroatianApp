import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/learning/presentation/learning_session_screen.dart';
import '../../features/learning/presentation/review_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/rooms/presentation/room_screen.dart';
import '../../features/alphabet/presentation/alphabet_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../widgets/splash_screen.dart';
import 'routes.dart';

/// GoRouter z guardem opartym o [AuthState]. Router słucha zmian stanu
/// autoryzacji (`refreshListenable`) i przekierowuje automatycznie:
///  - `Unknown` → splash
///  - `Unauthenticated` → /login
///  - `Authenticated` → docelowa strona (default dashboard)
final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthStateListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.dashboardPath,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isAuthRoute =
          location == AppRoutes.loginPath || location == AppRoutes.registerPath;

      return switch (auth) {
        AuthUnknown() => null, // splash sam obsłuży
        AuthUnauthenticated() when !isAuthRoute => AppRoutes.loginPath,
        AuthAuthenticated() when isAuthRoute => AppRoutes.dashboardPath,
        _ => null,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerPath,
        name: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboardPath,
        name: AppRoutes.dashboard,
        builder: (context, state) {
          final auth = ref.read(authControllerProvider);
          if (auth is AuthUnknown) return const SplashScreen();
          return const DashboardScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.profilePath,
        name: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.roomPath,
        name: AppRoutes.room,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['roomId'] ?? '') ?? 1;
          return RoomScreen(roomId: id);
        },
        routes: [
          GoRoute(
            path: 'learning',
            name: AppRoutes.learning,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['roomId'] ?? '') ?? 1;
              return LearningSessionScreen(roomId: id);
            },
          ),
          GoRoute(
            path: 'review',
            name: AppRoutes.review,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['roomId'] ?? '') ?? 1;
              return ReviewScreen(roomId: id);
            },
          ),
          GoRoute(
            path: 'alphabet',
            name: AppRoutes.alphabet,
            builder: (context, state) => const AlphabetScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Nie znaleziono strony: ${state.uri}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    ),
  );
});

/// Adapter [AuthState] → [Listenable] wymagany przez [GoRouter.refreshListenable].
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(this._ref) {
    _sub = _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
  ProviderSubscription<AuthState>? _sub;

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }
}
