import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/rooms/presentation/create_room_screen.dart';
import '../../features/rooms/presentation/join_room_screen.dart';
import '../../features/family_watch_room/presentation/family_watch_room_screen.dart';
import '../../features/family_watch_room/settings/room_settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoading = authState.isLoading;
      if (isLoading) return AppRoutes.splash;

      final isAuthenticated = authState.value?.session != null;
      final location = state.matchedLocation;
      final isOnSplash = location == AppRoutes.splash;
      final isOnLogin = location == AppRoutes.login;
      final isOnOnboarding = location == AppRoutes.onboarding;
      final isOnSignUp = location == AppRoutes.signUp;
      final isOnForgotPassword = location == AppRoutes.forgotPassword;
      final isOnResetPassword = location == AppRoutes.resetPassword;

      if (!isAuthenticated && !isOnLogin && !isOnSplash && !isOnOnboarding && !isOnSignUp && !isOnForgotPassword && !isOnResetPassword) return AppRoutes.onboarding;
      if (isAuthenticated && (isOnLogin || isOnSplash || isOnOnboarding || isOnSignUp || isOnForgotPassword || isOnResetPassword)) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.createRoom,
        builder: (context, state) => const CreateRoomScreen(),
      ),
      GoRoute(
        path: AppRoutes.joinRoom,
        builder: (context, state) => const JoinRoomScreen(),
      ),
      GoRoute(
        path: '/room/:id',
        builder: (context, state) => const FamilyWatchRoomScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) {
              final roomId = state.pathParameters['id']!;
              return RoomSettingsScreen(roomId: roomId);
            },
          ),
        ],
      ),
    ],
  );
});
