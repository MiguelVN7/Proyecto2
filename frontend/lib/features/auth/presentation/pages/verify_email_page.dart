// Flutter imports:
import 'package:flutter/material.dart';
import 'dart:async';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import '../../../../colors.dart';
import '../../state/auth_bloc.dart';

/// Email verification page shown after registration or when email is not verified.
///
/// This page guides users through the email verification process,
/// allowing them to resend verification emails and check their verification status.
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _checkVerificationTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _checkVerificationTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Starts a timer to periodically check email verification status
  void _startVerificationCheck() {
    _checkVerificationTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) {
      context.read<AuthBloc>().add(const AuthUserReloaded());
    });
  }

  /// Resends email verification with cooldown protection
  void _onResendVerification() {
    if (_resendCooldown > 0) return;

    context.read<AuthBloc>().add(const AuthEmailVerificationRequested());
    _startResendCooldown();
  }

  /// Starts cooldown timer for resend button
  void _startResendCooldown() {
    setState(() {
      _resendCooldown = 60; // 60 seconds cooldown
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown--;
      });

      if (_resendCooldown <= 0) {
        timer.cancel();
      }
    });
  }

  /// Manually checks verification status
  void _onCheckVerification() {
    context.read<AuthBloc>().add(const AuthUserReloaded());
  }

  /// Logs out the user
  void _onLogout() {
    _checkVerificationTimer?.cancel();
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Email verified, navigate to home
            Navigator.of(context).pushReplacementNamed('/home');
          } else if (state is AuthUnauthenticated) {
            // User logged out, go to login
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        child: SafeArea(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Email verification icon
                    Container(
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: EcoColors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: EcoColors.warning, width: 2),
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 60,
                        color: EcoColors.warning,
                      ),
                    ),

                    // Title
                    const Text(
                      'Verifica tu email',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: EcoColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Instructions
                    const Text(
                      'Te hemos enviado un email de verificación a:',
                      style: TextStyle(
                        fontSize: 16,
                        color: EcoColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // User email
                    if (state is AuthAwaitingVerification)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: EcoColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: EcoColors.grey300),
                        ),
                        child: Text(
                          state.user.email,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: EcoColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Instructions text
                    const Text(
                      'Haz clic en el enlace del email para verificar tu cuenta y poder acceder a la aplicación.',
                      style: TextStyle(
                        fontSize: 14,
                        color: EcoColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Check verification button
                    ElevatedButton.icon(
                      onPressed: _onCheckVerification,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Verificar ahora'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EcoColors.primary,
                        foregroundColor: EcoColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Resend verification button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading =
                            state is AuthAwaitingVerification &&
                            state.isLoading;
                        final canResend = _resendCooldown <= 0 && !isLoading;

                        return OutlinedButton.icon(
                          onPressed: canResend ? _onResendVerification : null,
                          icon: isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _resendCooldown > 0
                                ? 'Reenviar en ${_resendCooldown}s'
                                : 'Reenviar verificación',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: EcoColors.primary,
                            side: const BorderSide(color: EcoColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Success/Error messages
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthAwaitingVerification) {
                          if (state.message != null) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: EcoColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: EcoColors.success),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: EcoColors.success,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state.message!,
                                      style: const TextStyle(
                                        color: EcoColors.success,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (state.error != null) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: EcoColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: EcoColors.error),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: EcoColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state.error!,
                                      style: const TextStyle(
                                        color: EcoColors.error,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }

                        return const SizedBox.shrink();
                      },
                    ),

                    // Help text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EcoColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: EcoColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: EcoColors.info,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Consejos útiles:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: EcoColors.info,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Revisa tu bandeja de entrada y carpeta de spam\n'
                            '• El email puede tardar unos minutos en llegar\n'
                            '• Asegúrate de tener conexión a internet\n'
                            '• Usa un navegador actualizado para abrir el enlace',
                            style: TextStyle(
                              fontSize: 12,
                              color: EcoColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Logout button
                    TextButton(
                      onPressed: _onLogout,
                      style: TextButton.styleFrom(
                        foregroundColor: EcoColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // App version
                    const Center(
                      child: Text(
                        'EcoTrack v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: EcoColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
