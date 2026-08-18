import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/inbox/screens/inbox_screen.dart';
import '../../features/inbox/screens/email_detail_screen.dart';
import '../../features/deadlines/screens/deadline_screen.dart';
import '../../features/deadlines/screens/add_deadline_screen.dart';
import '../../features/applications/screens/applications_screen.dart';
import '../../features/applications/screens/application_detail_screen.dart';
import '../../features/applications/screens/add_application_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../widgets/shell_scaffold.dart';

// ─── Route Names ──────────────────────────────────────────
class Routes {
  static const splash = '/';
  static const signIn = '/sign-in';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const inbox = '/inbox';
  static const emailDetail = '/inbox/:id';
  static const deadlines = '/deadlines';
  static const addDeadline = '/deadlines/add';
  static const applications = '/applications';
  static const applicationDetail = '/applications/:id';
  static const addApplication = '/applications/add';
  static const notifications = '/notifications';
  static const search = '/search';
  static const settings = '/settings';
  static const admin = '/admin';
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// GoRouter provider with redirect guards and refreshListenable.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isOnboarded = authState.isOnboarded;
      final location = state.matchedLocation;

      final isAuthRoute = location == Routes.signIn || location == Routes.onboarding || location == Routes.splash;

      if (!isAuthenticated && !isAuthRoute) {
        return Routes.signIn;
      }

      if (isAuthenticated && !isOnboarded && location != Routes.onboarding) {
        return Routes.onboarding;
      }

      if (isAuthenticated && isAuthRoute && location != Routes.splash) {
        return Routes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.search,
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.admin,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      // Shell routes share the bottom navigation bar
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: Routes.inbox,
            builder: (_, __) => const InboxScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => EmailDetailScreen(
                  emailId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.deadlines,
            builder: (_, __) => const DeadlineScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, __) => const AddDeadlineScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.applications,
            builder: (_, __) => const ApplicationsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, __) => const AddApplicationScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => ApplicationDetailScreen(
                  applicationId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
