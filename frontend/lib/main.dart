import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'camera_screen.dart';
import 'colors.dart';

void main() {
  runApp(const EcoTrackApp());
}

class EcoTrackApp extends StatelessWidget {
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text('Estadísticas')), // Placeholder
    const HomeScreen(), // Placeholder for camera (will navigate to separate screen)
    const Center(child: Text('Mapa')), // Placeholder
    const Center(child: Text('Perfil')), // Placeholder
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
                // Camera tab
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = 'v${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      setState(() {
        _version = 'v1.0.0+2';
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
                        'Inicio',
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
                          _version,
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

                // light/beige background below header
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

            // Caja con Progreso Logro Actual
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
                    'Progreso logro actual',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            // Row entre las dos cajas: círculo + cuadrado
            Positioned(
              top:
                  335, // posición entre la caja superior (bottom ~380) y la inferior (top 500)
              left: 40,
              right: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Circulo
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
                          'Progreso al\nsiguiente\nnivel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Cuadrado
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
                          'Puntos',
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

            // Caja con Reporte Actual
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
                    'Reporte actual',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            // Aquí puedes añadir más contenido bajo la tarjeta (ej. filas de widgets)
          ],
        ),
      ),
    );
  }
}
