import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'camera_screen.dart';
import 'colors.dart';
import 'models/reporte.dart';
import 'screens/mapa_reportes_screen.dart';
import 'screens/lista_reportes_screen.dart';

/// Entry point of the EcoTrack application.
///
/// Initializes and runs the EcoTrack app with proper theming
/// and Material Design configuration.
void main() {
  runApp(const EcoTrackApp());
}

/// Root widget of the EcoTrack application.
///
/// This widget sets up the main application structure including:
/// - Application title and metadata
/// - Theme configuration using EcoColors
/// - Material Design 3 components
/// - Navigation to the main screen
class EcoTrackApp extends StatelessWidget {
  /// Creates the main EcoTrack application widget.
  const EcoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Track',
      theme: ThemeData(
        colorScheme: EcoColorScheme.ecoTheme,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

/// Sample data for testing the reports functionality.
/// 
/// This list contains example reports with different types of waste,
/// locations, and status for development and testing purposes.
final List<Reporte> reportesEjemplo = [
  Reporte(
    id: '1',
    fotoUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=100&q=80',
    ubicacion: 'Calle 1 #2-3',
    clasificacion: 'Plástico',
    estado: 'Pendiente',
    prioridad: 'Alta',
    tipoResiduo: 'Plástico',
    lat: 6.244203,
    lng: -75.581212,
  ),
  Reporte(
    id: '2',
    fotoUrl: 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=100&q=80',
    ubicacion: 'Carrera 45 #10-20',
    clasificacion: 'Vidrio',
    estado: 'Completado',
    prioridad: 'Media',
    tipoResiduo: 'Vidrio',
    lat: 6.250000,
    lng: -75.570000,
  ),
  // More example reports can be added here
];

/// Main screen widget with bottom navigation.
///
/// This widget provides the primary navigation structure for the app,
/// featuring a bottom navigation bar with tabs for different sections:
/// - Home: Dashboard and progress tracking
/// - Statistics: Usage analytics and reports
/// - Camera: Quick access to camera functionality
/// - Map: Location-based features
/// - Profile: User settings and information
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

  /// List of screens corresponding to each navigation tab.
  ///
  /// The camera tab (index 2) doesn't use this list as it navigates
  /// to a separate screen rather than switching content.
  final List<Widget> _screens = [
    const HomeScreen(),
    ListaReportesScreen(reportes: reportesEjemplo), // Reports list screen
    const HomeScreen(), // Placeholder for camera (will navigate to separate screen)
    MapaReportesScreen(reportes: reportesEjemplo), // Map screen with reports
    const Center(child: Text('Profile')), // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: kBottomNavigationBarHeight + 24,
        decoration: BoxDecoration(
          color: EcoColors.primary,
          borderRadius: const BorderRadius.only(
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
class HomeScreen extends StatefulWidget {
  /// Creates the home screen dashboard.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State class for HomeScreen managing version info and UI updates.
class _HomeScreenState extends State<HomeScreen> {
  /// Current app version string displayed in the header.
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  /// Loads the application version information.
  ///
  /// Retrieves version and build number from package info,
  /// falling back to default values if unavailable.
  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      setState(() {
        _appVersion = 'v1.0.0+2';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            // Background sections: green header + light content area
            Column(
              children: [
                Container(
                  height: 100,
                  color: EcoColors.primary,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: EcoColors.onPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: EcoColors.onPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _appVersion,
                          style: TextStyle(
                            fontSize: 12,
                            color: EcoColors.onPrimary.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Light/beige background below header
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: EcoColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(45),
                      ),
                    ),
                    width: double.infinity,
                  ),
                ),
              ],
            ),

            // Current achievement progress box
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: EcoColors.surface,
                  borderRadius: BorderRadius.circular(45),
                  border: Border.all(color: EcoColors.accent, width: 4),
                ),
                child: const Center(
                  child: Text(
                    'Current Achievement Progress',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            // Row between boxes: circle + square
            Positioned(
              top:
                  335, // Position between upper box (bottom ~380) and lower box (top 500)
              left: 40,
              right: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Circle
                  Expanded(
                    child: Container(
                      height: 120,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: EcoColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: EcoColors.secondary,
                          width: 4,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Progress to\nNext\nLevel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Square
                  Expanded(
                    child: Container(
                      height: 120,
                      margin: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        color: EcoColors.surface,
                        border: Border.all(
                          color: EcoColors.secondary,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(45),
                      ),
                      child: const Center(
                        child: Text(
                          'Points',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Current report box
            Positioned(
              top: 500,
              left: 20,
              right: 20,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: EcoColors.surface,
                  borderRadius: BorderRadius.circular(45),
                  border: Border.all(color: EcoColors.accent, width: 4),
                ),
                child: const Center(
                  child: Text(
                    'Current Report',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            // Here you can add more content below the card (e.g. widget rows)
          ],
        ),
      ),
    );
  }
}
