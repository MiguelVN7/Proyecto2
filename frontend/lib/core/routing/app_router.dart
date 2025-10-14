// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/state/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../main.dart';

/// Application router with authentication guards.
///
/// This class manages navigation and authentication state,
/// ensuring users can only access appropriate screens based
/// on their authentication and verification status.
class AppRouter {
  /// Creates routes for the application.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/splash':
        return MaterialPageRoute(
          builder: (_) => const AuthWrapper(),
          settings: settings,
        );

      case '/login':
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) {
              final bloc = AuthBloc(
                authRepository: AuthRepository(),
                userRepository: UserRepository(),
              );
              bloc.add(const AuthInitialized());
              return bloc;
            },
            child: const LoginPage(),
          ),
          settings: settings,
        );

      case '/register':
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) {
              final bloc = AuthBloc(
                authRepository: AuthRepository(),
                userRepository: UserRepository(),
              );
              bloc.add(const AuthInitialized());
              return bloc;
            },
            child: const RegisterPage(),
          ),
          settings: settings,
        );

      case '/verify-email':
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => AuthBloc(
              authRepository: AuthRepository(),
              userRepository: UserRepository(),
            ),
            child: const VerifyEmailPage(),
          ),
          settings: settings,
        );

      case '/home':
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(child: MainScreen()),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundPage(),
          settings: settings,
        );
    }
  }
}

/// Authentication wrapper that determines the initial screen.
///
/// This widget checks the current authentication state and
/// directs users to the appropriate screen.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = AuthBloc(
          authRepository: AuthRepository(),
          userRepository: UserRepository(),
        );
        bloc.add(const AuthInitialized());
        return bloc;
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const SplashScreen();
          } else if (state is AuthAuthenticated) {
            return const MainScreen();
          } else if (state is AuthAwaitingVerification ||
              state is AuthEmailVerificationSent) {
            return const VerifyEmailPage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}

/// Authentication guard that protects routes requiring authentication.
///
/// This widget wraps protected screens and ensures only authenticated
/// and verified users can access them.
class AuthGuard extends StatelessWidget {
  /// The child widget to display if authentication passes.
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = AuthBloc(
          authRepository: AuthRepository(),
          userRepository: UserRepository(),
        );
        bloc.add(const AuthInitialized());
        return bloc;
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const SplashScreen();
          } else if (state is AuthAuthenticated) {
            // User is authenticated and verified
            return child;
          } else if (state is AuthAwaitingVerification ||
              state is AuthEmailVerificationSent) {
            // User is authenticated but not verified
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/verify-email');
            });
            return const VerifyEmailPage();
          } else {
            // User is not authenticated
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/login');
            });
            return const LoginPage();
          }
        },
      ),
    );
  }
}

/// Splash screen shown while checking authentication state.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF708090), // EcoColors.primary
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              height: 120,
              width: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco,
                size: 60,
                color: Color(0xFF708090), // EcoColors.primary
              ),
            ),

            const SizedBox(height: 32),

            // App name
            const Text(
              'EcoTrack',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),

            const SizedBox(height: 32),

            // Version
            const Text(
              'v1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// 404 Not Found page for unknown routes.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // EcoColors.background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 404 icon
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Color(0xFF708090), // EcoColors.primary
            ),

            const SizedBox(height: 24),

            // 404 title
            const Text(
              '404',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D), // EcoColors.textPrimary
              ),
            ),

            const SizedBox(height: 16),

            // 404 message
            const Text(
              'Página no encontrada',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF2D2D2D), // EcoColors.textPrimary
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'La página que buscas no existe',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF616161), // EcoColors.textSecondary
              ),
            ),

            const SizedBox(height: 32),

            // Go back button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF708090), // EcoColors.primary
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ir al inicio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation extensions for easier route management.
extension NavigationExtensions on BuildContext {
  /// Navigates to login page.
  void goToLogin() {
    Navigator.of(this).pushReplacementNamed('/login');
  }

  /// Navigates to register page.
  void goToRegister() {
    Navigator.of(this).pushReplacementNamed('/register');
  }

  /// Navigates to verify email page.
  void goToVerifyEmail() {
    Navigator.of(this).pushReplacementNamed('/verify-email');
  }

  /// Navigates to home page.
  void goToHome() {
    Navigator.of(this).pushReplacementNamed('/home');
  }

  /// Navigates back or to home if no back route.
  void goBackOrHome() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    } else {
      Navigator.of(this).pushReplacementNamed('/home');
    }
  }
}
