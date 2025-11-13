// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart'
    show kReleaseMode; // Detectar modo release vs debug
import 'dart:async';

// Project imports:
import 'camera_screen.dart';
import 'colors.dart';
import 'models/reporte.dart';
import 'screens/mapa_reportes_screen.dart';
import 'screens/firestore_reports_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/home_screen.dart';
import 'services/fcm_service.dart';
import 'services/firestore_service.dart';
import 'core/routing/app_router.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/user_repository.dart';
import 'features/auth/state/auth_bloc.dart';

/// Entry point of the EcoTrack application.
///
/// Initializes Firebase, FCM, and runs the EcoTrack app with proper theming
/// and Material Design configuration.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');

    // Initialize Firebase App Check (opcional) — desactivado por defecto en desarrollo.
    // Actívalo con: flutter run --dart-define=ENABLE_APPCHECK=true
    const bool appCheckEnabled = bool.fromEnvironment(
      'ENABLE_APPCHECK',
      defaultValue: false,
    );
    if (appCheckEnabled) {
      try {
        const AndroidProvider selectedAndroidProvider = kReleaseMode
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug;
        await FirebaseAppCheck.instance.activate(
          androidProvider: selectedAndroidProvider,
          appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
        );
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
        debugPrint(
          '✅ App Check activado (fase 1) con provider Android: '
          '${selectedAndroidProvider == AndroidProvider.debug ? 'Debug' : 'PlayIntegrity'}',
        );
        _scheduleAppCheckTokenFetch();
      } catch (e) {
        debugPrint('❌ Error activando App Check: $e');
      }
    } else {
      debugPrint(
        'ℹ️ App Check desactivado (desarrollo). Para activarlo: --dart-define=ENABLE_APPCHECK=true',
      );
    }

    // Initialize Firestore/Storage service early so uploads use the right bucket
    try {
      await FirestoreService().initialize();
      debugPrint('✅ Firestore initialized in main()');
    } catch (e) {
      debugPrint('⚠️ FirestoreService initialize error (non-fatal): $e');
    }

    // Try to set background message handler (optional for Note 9 compatibility)
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('✅ Firebase Messaging initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Firebase Messaging not available (this is OK): $e');
      // Continue without Firebase Messaging - authentication will still work
    }
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
    // For now, continue without Firebase - you can add fallback logic here
  }

  runApp(const EcoTrackApp());
}

/// Programa la obtención del token de App Check con reintentos y backoff exponencial
void _scheduleAppCheckTokenFetch({int attempt = 1}) {
  // Máximo 5 intentos
  if (attempt > 5) {
    debugPrint(
      '🛡️ App Check: se alcanzó el máximo de intentos para obtener token.',
    );
    return;
  }

  // Backoff exponencial simple: 1s, 2s, 4s, 8s, 16s
  final delay = Duration(seconds: 1 << (attempt - 1));
  debugPrint(
    '🛡️ App Check: programando intento $attempt para obtener token en ${delay.inSeconds}s',
  );

  Future.delayed(delay, () async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint(
          '🛡️ App Check intento $attempt: token aún vacío, reintentando...',
        );
        _scheduleAppCheckTokenFetch(attempt: attempt + 1);
      } else {
        debugPrint(
          '🛡️ App Check token obtenido en intento $attempt: ${token.substring(0, token.length.clamp(0, 12))}...',
        );
      }
    } catch (e) {
      final msg = e.toString();
      debugPrint('⚠️ App Check intento $attempt falló: $msg');

      // Detecta API no habilitada / deshabilitada (403) -> detener reintentos hasta que el dev la active
      if (msg.contains('firebaseappcheck.googleapis.com') &&
          (msg.contains('has not been used') ||
              msg.contains('it is disabled'))) {
        debugPrint(
          '🛑 App Check: API deshabilitada/no usada. Habilítala en Google Cloud Console y reinicia la app. No se seguirán haciendo reintentos.',
        );
        return;
      }
      // Attestation (Play Integrity / provider) falló -> requiere acción manual (registro SHA / registro App Check)
      if (msg.contains('App attestation failed')) {
        debugPrint('''🛑 App Check: attestation failed. Verifica que:
 - Diste clic en "Registrar" en App Check para la app Android (debe mostrarse el proveedor asignado)
 - Elegiste Play Integrity (o estás usando Debug provider) y añadiste el debug token en la consola
 - Agregaste la huella SHA-256 correcta del keystore (debug o release) en Firebase > Configuración del proyecto > Tus apps
 - Activaste la API App Check y esperaste 2–5 minutos a que propague
 - No hay VPN / proxy que bloquee Play Integrity
No se seguirán haciendo reintentos hasta corregir esto.''');
        return;
      }
      // Demasiados intentos (rate limiting) -> no insistir más inmediatamente
      if (msg.contains('Too many attempts')) {
        debugPrint(
          '🛑 App Check: rate limited. Espera unos minutos antes de reiniciar la app.',
        );
        return;
      }
      _scheduleAppCheckTokenFetch(attempt: attempt + 1);
    }
  });
}

/// Root widget of the EcoTrack application.
///
/// This widget sets up the main application structure including:
/// - Application title and metadata
/// - Theme configuration using EcoColors
/// - Material Design 3 components
/// - Authentication-aware routing system
class EcoTrackApp extends StatelessWidget {
  /// Creates the main EcoTrack application widget.
  const EcoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: AuthRepository(),
            userRepository: UserRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'EcoTrack',
        theme: ThemeData(
          colorScheme: EcoColorScheme.ecoTheme,
          useMaterial3: true,
        ),
        initialRoute: '/',
        onGenerateRoute: AppRouter.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Sample data for testing the reports functionality.
///
/// This list contains example reports with different types of waste,
/// locations, and status for development and testing purposes.
final List<Reporte> reportesEjemplo = [
  Reporte.create(
    id: '1',
    fotoUrl:
        'https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=100&q=80',
    ubicacion: 'Calle 1 #2-3',
    clasificacion: 'Plástico',
    tipoResiduo: 'Plástico',
    lat: 6.244203,
    lng: -75.581212,
    prioridad: 'Alta',
    estado: 'Recibido',
  ),
  Reporte.create(
    id: '2',
    fotoUrl:
        'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=100&q=80',
    ubicacion: 'Carrera 45 #10-20',
    clasificacion: 'Vidrio',
    tipoResiduo: 'Vidrio',
    lat: 6.250000,
    lng: -75.570000,
    prioridad: 'Media',
    estado: 'Completado',
  ),
  // More example reports can be added here
];

class MainScreen extends StatefulWidget {
  /// Creates the main screen with navigation.
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// State class for MainScreen managing navigation and screen content.
class _MainScreenState extends State<MainScreen> {
  /// Currently selected tab index.
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  /// Initialize FCM and Firestore services
  Future<void> _initializeFCM() async {
    try {
      // Initialize Firestore service
      try {
        await FirestoreService().initialize();
        debugPrint('✅ Firestore initialized in MainScreen');
      } catch (e) {
        debugPrint('⚠️ Firestore not available (this is OK): $e');
      }

      // Initialize FCM service (optional for Note 9 compatibility)
      try {
        await FCMService().initialize();

        // Set up navigation callback for notification taps
        FCMService().setNavigationCallback((reportId, type) {
          _handleNotificationNavigation(reportId, type);
        });

        debugPrint('✅ FCM initialized in MainScreen');
      } catch (e) {
        debugPrint('⚠️ FCM not available (this is OK): $e');
      }
    } catch (e) {
      debugPrint('❌ Error initializing services in MainScreen: $e');
      // Continue without Firebase services - the app will still work
    }
  }

  /// Handle navigation from push notifications
  void _handleNotificationNavigation(String reportId, String type) {
    debugPrint('🧭 Navigation requested for report: $reportId (type: $type)');

    // Show a snackbar with report information
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report Update: $reportId'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View Reports',
            onPressed: () {
              // Navigate to reports list
              setState(() {
                _currentIndex = 1; // Reports tab
              });
            },
          ),
        ),
      );
    }
  }

  /// List of screens corresponding to each navigation tab.
  ///
  /// The camera tab (index 2) doesn't use this list as it navigates
  /// to a separate screen rather than switching content.
  final List<Widget> _screens = [
    const HomeScreen(),
    const FirestoreReportsScreen(), // Real-time Firestore reports screen
    const HomeScreen(), // Placeholder for camera (will navigate to separate screen)
    const MapaReportesScreen(), // Map screen with real-time Firestore reports
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: kBottomNavigationBarHeight + 24,
        decoration: const BoxDecoration(
          color: EcoColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(45),
            topRight: Radius.circular(45),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: EcoColors.onPrimary,
            unselectedItemColor: EcoColors.onPrimary.withOpacity(0.7),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedFontSize: 0,
            unselectedFontSize: 0,
            iconSize: 35,
            onTap: (index) {
              if (index == 2) {
                // Camera tab - navigate to separate screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
              } else {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            items: const [
              // Labels must be non-null, use empty strings to hide them
              BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home screen displaying the main dashboard.
///
/// This screen shows the user's progress, achievements, and current reports.
/// Features include:
/// - Progress tracking for current achievements
/// - Level progression indicators
/// - Points display
/// - Current report status
/// - App version information
// HomeScreen now lives in screens/home_screen.dart
