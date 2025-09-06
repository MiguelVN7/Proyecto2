import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'report_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  bool _isRearCameraSelected = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    print('🎥 INICIANDO CONFIGURACIÓN DE CÁMARA...');

    setState(() {
      _isLoading = true;
    });

    try {
      _cameras = await availableCameras();
      print('📱 Cámaras disponibles: ${_cameras!.length}');

      if (_cameras!.isNotEmpty) {
        final selectedCamera = _isRearCameraSelected
            ? _cameras!.firstWhere(
                (camera) => camera.lensDirection == CameraLensDirection.back,
                orElse: () => _cameras![0],
              )
            : _cameras!.firstWhere(
                (camera) => camera.lensDirection == CameraLensDirection.front,
                orElse: () => _cameras![0],
              );

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.ultraHigh,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        print('✅ CÁMARA INICIALIZADA CORRECTAMENTE');
        print('📸 Resolución: ${_cameraController!.value.previewSize}');
        print('🔍 Cámara seleccionada: ${selectedCamera.name}');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('💥 ERROR AL INICIALIZAR CÁMARA: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    print('🚀 MÉTODO _takePicture() INICIADO');
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('❌ CAMERA NO INICIALIZADA - RETORNANDO');
      return;
    }

    try {
      print('📸 CAPTURANDO FOTO...');
      final XFile picture = await _cameraController!.takePicture();

      print('💾 GUARDANDO FOTO EN DIRECTORIO TEMPORAL...');
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await picture.saveTo(imagePath);

      print('✅ FOTO GUARDADA EN: $imagePath');

      // EJECUTAR ANÁLISIS INMEDIATAMENTE
      print('🔍 INICIANDO ANÁLISIS INMEDIATO...');
      final analysisResult = await _performImageAnalysis();

      print('📍 OBTENIENDO UBICACIÓN...');
      final locationResult = await _getLocationInfo();

      print('🧾 NAVEGANDO A PANTALLA DE CONFIRMACIÓN...');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoConfirmationScreen(
              imagePath: imagePath,
              analysisResult: analysisResult,
              locationInfo: locationResult,
            ),
          ),
        );
      }
    } catch (e) {
      print('💥 ERROR EN _takePicture(): $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al tomar la foto: $e')));
    }
  }

  // Lista de residuos para clasificación aleatoria
  final List<String> _wasteClassifications = [
    'Botella de plástico PET',
    'Lata de aluminio',
    'Cartón corrugado',
    'Papel de periódico',
    'Vidrio transparente',
    'Residuo orgánico (cáscara de fruta)',
    'Bolsa plástica',
    'Tetrapak (envase de jugo)',
    'Pilas usadas',
    'Residuo electrónico (celular viejo)',
  ];

  final Random _random = Random();

  Future<String> _performImageAnalysis() async {
    print('=== INICIANDO ANÁLISIS DE IMAGEN ===');

    // Simular procesamiento de IA
    await Future.delayed(const Duration(seconds: 1));

    // Seleccionar clasificación aleatoria
    final randomIndex = _random.nextInt(_wasteClassifications.length);
    final selectedClassification = _wasteClassifications[randomIndex];

    print('=== RANDOM CLASSIFICATION DEBUG ===');
    print('Lista total de residuos: ${_wasteClassifications.length}');
    print('Índice aleatorio seleccionado: $randomIndex');
    print('Clasificación seleccionada: $selectedClassification');
    print('===================================');

    return selectedClassification;
  }

  Future<String> _getLocationInfo() async {
    print('📍 OBTENIENDO INFORMACIÓN DE UBICACIÓN...');

    // Simular obtención de ubicación
    await Future.delayed(const Duration(milliseconds: 500));

    // Ubicación simulada realista para Medellín
    final List<String> locations = [
      '6.244203, -75.581212', // Medellín Centro
      '6.230833, -75.590553', // El Poblado
      '6.267417, -75.568389', // Universidad Nacional
      '6.208679, -75.568389', // Envigado
      '6.164217, -75.603889', // Sabaneta
    ];

    final randomLocation = locations[_random.nextInt(locations.length)];
    print('📍 Ubicación obtenida: $randomLocation');

    return randomLocation;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Inicializando cámara...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Error al inicializar la cámara',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vista previa de la cámara
          Positioned.fill(child: CameraPreview(_cameraController!)),

          // Overlay con información
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    '🌱 EcoTrack',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Apunta hacia el residuo y toca el botón para clasificarlo',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Controles inferiores
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Botón de captura
                Center(
                  child: GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Botón de cambio de cámara
                if (_cameras != null && _cameras!.length > 1)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.cameraswitch,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () async {
                        setState(() {
                          _isRearCameraSelected = !_isRearCameraSelected;
                          _isLoading = true;
                        });
                        await _initializeCamera();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de confirmación de foto con análisis ya completado
class PhotoConfirmationScreen extends StatefulWidget {
  final String imagePath;
  final String analysisResult;
  final String locationInfo;

  const PhotoConfirmationScreen({
    super.key,
    required this.imagePath,
    required this.analysisResult,
    required this.locationInfo,
  });

  @override
  State<PhotoConfirmationScreen> createState() =>
      _PhotoConfirmationScreenState();
}

class _PhotoConfirmationScreenState extends State<PhotoConfirmationScreen> {
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    print('🖼️ PhotoConfirmationScreen inicializada');
    print('📊 Resultado de análisis: ${widget.analysisResult}');
    print('📍 Ubicación: ${widget.locationInfo}');
  }

  Future<void> _registerReport() async {
    print('📝 INICIANDO REGISTRO DE REPORTE...');

    setState(() {
      _isRegistering = true;
    });

    try {
      // Enviar reporte real al backend
      print('📤 ENVIANDO REPORTE AL SERVIDOR...');

      // Parsear la ubicación desde el string "lat, lon"
      final locationParts = widget.locationInfo.split(', ');
      final latitude = double.parse(locationParts[0]);
      final longitude = double.parse(locationParts[1]);

      final result = await ReportService.submitReport(
        imageFile: File(widget.imagePath),
        latitude: latitude,
        longitude: longitude,
        accuracy: 10.0, // Accuracy por defecto
        classification: widget.analysisResult,
      );

      if (result.success) {
        final reportCode = result.reportCode!;
        print('✅ REPORTE ENVIADO EXITOSAMENTE CON CÓDIGO: $reportCode');
      } else {
        print('❌ ERROR AL ENVIAR REPORTE: ${result.message}');
        throw Exception('Error al enviar reporte: ${result.message}');
      }

      final reportCode = result.reportCode!;

      if (mounted) {
        // Mostrar pantalla de éxito
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReportSuccessScreen(
              reportCode: reportCode,
              wasteType: widget.analysisResult,
              location: widget.locationInfo,
            ),
          ),
        );
      }
    } catch (e) {
      print('💥 ERROR AL REGISTRAR REPORTE: $e');
      setState(() {
        _isRegistering = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Confirmar Captura',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Imagen capturada
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
              ),
            ),
          ),

          // Información del análisis
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resultado del análisis
                  Row(
                    children: [
                      const Icon(
                        Icons.recycling,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Clasificación:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Text(
                      widget.analysisResult,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ubicación
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Ubicación:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: Text(
                      widget.locationInfo,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Botón volver a tomar
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRegistering
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Volver a tomar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Botón registrar
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRegistering ? null : _registerReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isRegistering
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Registrar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de éxito del reporte
class ReportSuccessScreen extends StatelessWidget {
  final String reportCode;
  final String wasteType;
  final String location;

  const ReportSuccessScreen({
    super.key,
    required this.reportCode,
    required this.wasteType,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de éxito
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),

              const SizedBox(height: 30),

              // Título
              const Text(
                '¡Reporte Enviado Exitosamente!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              // Subtítulo
              const Text(
                'Reporte recibido exitosamente',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Información del reporte
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Column(
                  children: [
                    // Código de reporte
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reportCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Detalles
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ubicación: ',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(
                          Icons.recycling,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Clasificación: ',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Expanded(
                          child: Text(
                            wasteType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Mensaje adicional
              const Text(
                'Guarda el código de reporte para futuras consultas.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Volver a tomar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Finalizar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
