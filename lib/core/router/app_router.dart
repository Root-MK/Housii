import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/home_provider.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/pending_approval_screen.dart';
import '../../features/home_management/presentation/screens/home_selection_screen.dart';
import '../../features/home_management/presentation/screens/create_home_screen.dart';
import '../../features/home_management/presentation/screens/join_home_screen.dart';
import '../../features/home_management/presentation/screens/home_settings_screen.dart';
import '../../features/main_shell/presentation/screens/main_shell_screen.dart';
import '../../features/shopping/presentation/screens/shopping_screen.dart';
import '../../features/lists/presentation/screens/lists_screen.dart';
import '../../features/food/presentation/screens/food_screen.dart';
import '../../features/garden/presentation/screens/garden_screen.dart';

/// Route paths
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String pendingApproval = '/pending-approval';
  static const String homeSelection = '/home-selection';
  static const String createHome = '/create-home';
  static const String joinHome = '/join-home';
  static const String homeSettings = '/home-settings';
  static const String main = '/main';
  static const String shopping = '/main/shopping';
  static const String lists = '/main/lists';
  static const String food = '/main/food';
  static const String garden = '/main/garden';
}

/// Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userAsync = ref.watch(currentUserProvider);
  final currentHome = ref.watch(currentHomeProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnLogin = state.matchedLocation == AppRoutes.login;
      final isOnPendingApproval = state.matchedLocation == AppRoutes.pendingApproval;
      final isOnHomeSelection = state.matchedLocation == AppRoutes.homeSelection;
      final isOnCreateHome = state.matchedLocation == AppRoutes.createHome;
      final isOnJoinHome = state.matchedLocation == AppRoutes.joinHome;
      
      // Loading state - stay on splash
      if (authState.isLoading) {
        return isOnSplash ? null : AppRoutes.splash;
      }
      
      // Not logged in - go to login
      final user = authState.value;
      if (user == null) {
        return isOnLogin ? null : AppRoutes.login;
      }
      
      // Logged in but user data loading
      if (userAsync.isLoading) {
        return isOnSplash ? null : AppRoutes.splash;
      }
      
      // User data loaded - check approval status
      final userData = userAsync.value;
      
      // If user data is null (not in Firestore) or not approved, show pending
      if (userData == null || !userData.adminAccepted) {
        return isOnPendingApproval ? null : AppRoutes.pendingApproval;
      }
      
      // Approved but no home - go to home selection
      if (currentHome.isLoading) {
        return isOnSplash ? null : AppRoutes.splash;
      }
      
      final home = currentHome.value;
      if (home == null) {
        if (isOnHomeSelection || isOnCreateHome || isOnJoinHome) {
          return null;
        }
        return AppRoutes.homeSelection;
      }
      
      // Has home - go to main if on auth routes
      if (isOnLogin || isOnSplash || isOnPendingApproval || isOnHomeSelection) {
        return AppRoutes.shopping;
      }
      
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      
      // Home Management
      GoRoute(
        path: AppRoutes.homeSelection,
        builder: (context, state) => const HomeSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.createHome,
        builder: (context, state) => const CreateHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.joinHome,
        builder: (context, state) => const JoinHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.homeSettings,
        builder: (context, state) => const HomeSettingsScreen(),
      ),
      
      // Main Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.shopping,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ShoppingScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.lists,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ListsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.food,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FoodScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.garden,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GardenScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
