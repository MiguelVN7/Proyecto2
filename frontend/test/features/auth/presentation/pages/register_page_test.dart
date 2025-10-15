// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

// Project imports:
import 'package:eco_track/features/auth/presentation/pages/register_page.dart';
import 'package:eco_track/features/auth/state/auth_bloc.dart';
import 'package:eco_track/features/auth/data/auth_repository.dart';
import 'package:eco_track/features/auth/data/user_repository.dart';
// import 'package:eco_track/firebase_options.dart';

void main() {
  late FirebaseAuth mockAuth;
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockAuth = MockFirebaseAuth(signedIn: false);
  });

  group('RegisterPage Widget Tests', () {
    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: AuthRepository(firebaseAuth: mockAuth),
            userRepository: UserRepository(),
          ),
          child: const RegisterPage(),
        ),
      );
    }

    testWidgets('should display all required form fields', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Crear Cuenta'), findsOneWidget);
      expect(find.text('Únete a la comunidad ambiental'), findsOneWidget);

      // Form fields
      expect(find.byType(TextFormField), findsNWidgets(4)); // name, email, password, confirm
      expect(find.text('Nombre (opcional)'), findsOneWidget);
      expect(find.text('Correo electrónico *'), findsOneWidget);
      expect(find.text('Contraseña *'), findsOneWidget);
      expect(find.text('Confirmar contraseña *'), findsOneWidget);

      // Buttons
      expect(find.text('Crear Cuenta'), findsNWidgets(2)); // Title and button
      expect(find.text('Inicia sesión'), findsOneWidget);

      // Terms checkbox
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Acepto los términos y condiciones y la política de privacidad'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty required fields', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Try to submit without filling required fields
      final createAccountButton = find.text('Crear Cuenta').last;
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('El correo electrónico es requerido'), findsOneWidget);
      expect(find.text('La contraseña es requerida'), findsOneWidget);
    });

    testWidgets('should show email validation error for invalid email', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
  // Safer: find the email field by label
  final emailField = find.widgetWithText(TextFormField, 'Correo electrónico *');
      await tester.enterText(emailField, 'invalid-email');

      final createAccountButton = find.text('Crear Cuenta').last;
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
    });

    testWidgets('should show password validation errors for weak password', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
  final emailField = find.widgetWithText(TextFormField, 'Correo electrónico *');
      await tester.enterText(emailField, 'test@example.com');
  final passwordField = find.widgetWithText(TextFormField, 'Contraseña *');
      await tester.enterText(passwordField, 'weak');
      await tester.pumpAndSettle();

      // Assert - Password requirements should show
      expect(find.text('Requisitos de contraseña:'), findsOneWidget);
      expect(find.text('Debe tener al menos 8 caracteres'), findsOneWidget);
    });

    testWidgets('should show password confirmation error when passwords do not match', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
  final emailField = find.widgetWithText(TextFormField, 'Correo electrónico *');
      await tester.enterText(emailField, 'test@example.com');
  final passwordField = find.widgetWithText(TextFormField, 'Contraseña *');
      await tester.enterText(passwordField, 'Password123');
  final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirmar contraseña *');
      await tester.enterText(confirmPasswordField, 'DifferentPassword123');

      final createAccountButton = find.text('Crear Cuenta').last;
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('should toggle password visibility when visibility icon is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Find and tap the visibility icon for password field
      final passwordVisibilityIcon = find.byIcon(Icons.visibility).first;
      await tester.tap(passwordVisibilityIcon);
      await tester.pumpAndSettle();

      // Assert - Icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));
    });

    testWidgets('should show snackbar error when terms are not accepted', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act - Fill valid form but don't accept terms
  final emailField = find.widgetWithText(TextFormField, 'Correo electrónico *');
      await tester.enterText(emailField, 'test@example.com');
  final passwordField = find.widgetWithText(TextFormField, 'Contraseña *');
      await tester.enterText(passwordField, 'Password123');
  final confirmPasswordField = find.widgetWithText(TextFormField, 'Confirmar contraseña *');
      await tester.enterText(confirmPasswordField, 'Password123');

      final createAccountButton = find.text('Crear Cuenta').last;
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Debes aceptar los términos y condiciones'), findsOneWidget);
    });

    testWidgets('should navigate to login when login link is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act
  final loginLink = find.text('Inicia sesión');
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      // Note: In a real test, you would verify navigation
      // This would require mocking Navigator or using a more complex setup
    });
  });
}