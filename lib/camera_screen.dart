import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'dart:io';
import 'location_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isRearCameraSelected = true;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Verificar si estamos en un simulador
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No hay cámaras disponibles en este dispositivo. Usa un dispositivo físico para probar la funcionalidad de cámara.';
          _isLoading = false;
        });
        return;
      }

      await _setupCamera(_isRearCameraSelected ? 0 : 1);
    } catch (e) {
      setState(() {
        if (e.toString().contains('MissingPluginException')) {
          _errorMessage = 'Funcionalidad de cámara no disponible en simulador. Usa un dispositivo físico para probar esta función.';
        } else {
          _errorMessage = 'Error al inicializar la cámara: $e';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    // Asegurar que el índice esté en rango
    if (cameraIndex >= _cameras!.length) {
      cameraIndex = 0;
    }

    _controller = CameraController(
      _cameras![cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();

    await _initializeControllerFuture;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras!.length < 2) return;

    setState(() {
      _isLoading = true;
      _isRearCameraSelected = !_isRearCameraSelected;
    });

    await _controller?.dispose();
    await _setupCamera(_isRearCameraSelected ? 0 : 1);
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final directory = await getTemporaryDirectory();
      final imagePath = path.join(
        directory.path,
        'waste_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final XFile picture = await _controller!.takePicture();

      // Verificar resolución
      final File imageFile = File(picture.path);

      // Validar resolución mínima (800x600)
      final bool isValidResolution = await _validateImageResolution(imageFile);

      if (!isValidResolution) {
        _showErrorDialog(
          'La imagen debe tener una resolución mínima de 800x600 píxeles',
        );
        return;
      }

      // Copiar a ubicación permanente
      await imageFile.copy(imagePath);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => PhotoPreviewScreen(imagePath: imagePath),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error al tomar la foto: $e');
    }
  }

  Future<bool> _validateImageResolution(File imageFile) async {
    try {
      // TODO(human): Implementar validación de resolución de imagen
      // Debes verificar que la imagen tenga al menos 800x600 píxeles
      // Puedes usar paquetes como image o flutter's dart:ui para obtener las dimensiones
      // Por ahora retornamos true como placeholder
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return false;

      return image.width >= 800 && image.height >= 600;
    } catch (e) {
      return false;
    }
  }

  Future<void> _simulatePhotoCapture() async {
    // Crear una imagen simulada para propósitos de desarrollo
    final directory = await getTemporaryDirectory();
    final imagePath = path.join(
      directory.path,
      'simulated_waste_photo_${DateTime.now().millisecondsSinceEpoch}.txt',
    );

    // Crear un archivo de texto que simule una imagen para testing
    await File(imagePath).writeAsString(
      'Esta es una imagen simulada para propósitos de desarrollo.\n'
      'Resolución simulada: 1920x1080\n'
      'Fecha: ${DateTime.now()}\n'
      'Esta funcionalidad necesita un dispositivo físico para funcionar completamente.',
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => PhotoPreviewScreen(
            imagePath: imagePath,
            isSimulated: true,
          ),
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview or loading/error states
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(152, 196, 85, 1),
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initializeCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(152, 196, 85, 1),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Reintentar'),
                    ),
                    if (_errorMessage!.contains('simulador')) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _simulatePhotoCapture,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('Simular Captura (Demo)'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            // Camera preview with rounded corners
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.only(top: 120, bottom: 200),
                child: FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.grey.shade900,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CameraPreview(_controller!),
                        ),
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color.fromRGBO(152, 196, 85, 1),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),

          // Top controls (back button and flash)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  // Flash button
                  GestureDetector(
                    onTap: () {
                      // TODO: Implement flash toggle
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.flash_off,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gallery/Photos button
                  GestureDetector(
                    onTap: () {
                      // TODO: Open gallery
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // Capture button (main)
                  GestureDetector(
                    onTap: _errorMessage == null ? _takePicture : null,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Camera flip button
                  GestureDetector(
                    onTap: (_cameras != null && _cameras!.length > 1) ? _toggleCamera : null,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.flip_camera_ios_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoPreviewScreen extends StatefulWidget {
  final String imagePath;
  final bool isSimulated;

  const PhotoPreviewScreen({
    super.key,
    required this.imagePath,
    this.isSimulated = false,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  String? _identificationResult;
  bool _isAnalyzing = false;
  LocationResult? _locationResult;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
    _getCurrentLocation();
  }

  Future<void> _analyzeImage() async {
    setState(() {
      _isAnalyzing = true;
    });

    // TODO(human): Implementar lógica de identificación de residuos
    await Future.delayed(const Duration(seconds: 2)); // Simular procesamiento

    setState(() {
      if (widget.isSimulated) {
        _identificationResult = "Residuo simulado - Demo funcional";
      } else {
        _identificationResult = "Botella de plástico PET";
      }
      _isAnalyzing = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      LocationResult result = await LocationService.getCurrentLocation();
      
      setState(() {
        _locationResult = result;
        _isGettingLocation = false;
      });

      // Si hay baja precisión, mostrar opción al usuario
      if (result.isLowAccuracy) {
        _showLowAccuracyDialog(result);
      } else if (!result.success) {
        // Si falla completamente, ofrecer ingreso manual
        _showLocationErrorDialog(result.errorMessage!);
      }
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
        _locationResult = LocationResult.error('Error inesperado obteniendo ubicación');
      });
    }
  }

  void _showLowAccuracyDialog(LocationResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Precisión de Ubicación'),
          content: Text(result.errorMessage!),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _getCurrentLocation(); // Intentar de nuevo
              },
              child: const Text('Intentar de Nuevo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showManualLocationDialog();
              },
              child: const Text('Ingreso Manual'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Aceptar ubicación actual
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(152, 196, 85, 1),
              ),
              child: const Text('Usar Esta Ubicación'),
            ),
          ],
        );
      },
    );
  }

  void _showLocationErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error de Ubicación'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _getCurrentLocation(); // Intentar de nuevo
              },
              child: const Text('Intentar de Nuevo'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showManualLocationDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(152, 196, 85, 1),
              ),
              child: const Text('Ingreso Manual'),
            ),
          ],
        );
      },
    );
  }

  void _showManualLocationDialog() async {
    final LocationResult? result = await showDialog<LocationResult>(
      context: context,
      builder: (BuildContext context) => const ManualLocationDialog(),
    );

    if (result != null) {
      setState(() {
        _locationResult = result;
      });
    }
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.blue.shade700,
              size: 20,
            ),
            const SizedBox(width: 6),
            const Text(
              'Ubicación:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: _isGettingLocation
              ? const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Obteniendo ubicación GPS...'),
                  ],
                )
              : _locationResult != null && _locationResult!.success
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocationService.formatCoordinates(
                            _locationResult!.latitude!,
                            _locationResult!.longitude!,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Precisión: ±${_locationResult!.accuracy!.toStringAsFixed(1)}m',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationResult?.errorMessage ?? 'Error obteniendo ubicación',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showManualLocationDialog,
                          icon: const Icon(Icons.edit_location, size: 16),
                          label: const Text('Ingresar Manualmente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  bool _canRegisterWaste() {
    return _identificationResult != null && 
           !_isAnalyzing && 
           _locationResult != null && 
           _locationResult!.success && 
           !_isGettingLocation;
  }

  void _registerWaste() {
    // Aquí se guardaría el registro completo del residuo
    final wasteReport = {
      'identification': _identificationResult,
      'latitude': _locationResult!.latitude,
      'longitude': _locationResult!.longitude,
      'accuracy': _locationResult!.accuracy,
      'imagePath': widget.imagePath,
      'timestamp': DateTime.now().toIso8601String(),
      'isSimulated': widget.isSimulated,
    };
    
    // TODO: Implementar base de datos para guardar wasteReport
    // Por ahora solo mostramos la confirmación
    assert(wasteReport.isNotEmpty, 'wasteReport should not be empty');
    
    // Mostrar confirmación y regresar al home
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 64,
          ),
          title: const Text('¡Reporte Registrado!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tu reporte de residuo ha sido registrado exitosamente.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Residuo: $_identificationResult'),
                    Text('Ubicación: ${LocationService.formatCoordinates(
                      _locationResult!.latitude!,
                      _locationResult!.longitude!,
                    )}'),
                    Text('Precisión: ±${_locationResult!.accuracy!.toStringAsFixed(1)}m'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.popUntil(context, (route) => route.isFirst); // Regresar al home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(152, 196, 85, 1),
              ),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color.fromRGBO(152, 196, 85, 1),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: widget.isSimulated
                    ? Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Imagen Simulada',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Demo: Usa dispositivo físico\npara captura real',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Image.file(File(widget.imagePath), fit: BoxFit.cover),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBF5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_isAnalyzing)
                      const Column(
                        children: [
                          CircularProgressIndicator(
                            color: Color.fromRGBO(152, 196, 85, 1),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Analizando residuo...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else if (_identificationResult != null)
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.recycling,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Residuo identificado:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              _identificationResult!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLocationSection(),
                          const SizedBox(height: 20),
                          _buildActionButtons(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Volver a tomar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _canRegisterWaste()
                ? () {
                    _registerWaste();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(
                152,
                196,
                85,
                1,
              ),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Registrar'),
          ),
        ),
      ],
    );
  }
}
