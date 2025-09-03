import 'package:flutter/material.dart';
import 'camera_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade400),
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
      backgroundColor: const Color(
        0xFFFFFBF5,
      ), // Same beige color as HomeScreen
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: kBottomNavigationBarHeight + 24,
        decoration: BoxDecoration(
          color: Color.fromRGBO(152, 196, 85, 1),
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
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 78, 172, 1),
      body: SafeArea(
        child: Stack(
          children: [
            // Background sections: green header + light content area
            Column(
              children: [
                Container(
                  height: 100,
                  color: Color.fromRGBO(51, 78, 172, 1),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'Inicio',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // light/beige background below header
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFBF5),
                      borderRadius: BorderRadius.vertical(
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(45),
                  border: Border.all(color: Colors.green.shade900, width: 4),
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.shade900,
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
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.green.shade900,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(45),
                  border: Border.all(color: Colors.green.shade900, width: 4),
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
