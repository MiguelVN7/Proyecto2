import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'report_service.dart';
import 'colors.dart';
import 'location_service.dart';

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

  /// Initializes the camera with optimal settings.
  ///
  /// Sets up camera controller with high resolution preset and configures
  /// the appropriate camera (rear by default, front if toggled).
  Future<void> _initializeCamera() async {
    debugPrint('🎥 Starting camera configuration...');

    setState(() {
      _isLoading = true;
    });

    try {
      _cameras = await availableCameras();
      debugPrint('📱 Available cameras: ${_cameras!.length}');

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

        debugPrint('✅ Camera initialized successfully');
        debugPrint('📸 Resolution: ${_cameraController!.value.previewSize}');
        debugPrint('🔍 Selected camera: ${selectedCamera.name}');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('💥 Error initializing camera: $e');
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

  /// Captures a photo and processes it for waste classification.
  ///
  /// This method performs the complete photo capture workflow:
  /// 1. Takes a photo using the camera controller
  /// 2. Saves it to temporary directory
  /// 3. Analyzes the image for waste classification
  /// 4. Gets location information
  /// 5. Navigates to confirmation screen
  Future<void> _takePicture() async {
    debugPrint('🚀 Starting _takePicture() method');
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('❌ Camera not initialized - returning');
      return;
    }

    try {
      debugPrint('📸 Capturing photo...');
      final XFile picture = await _cameraController!.takePicture();

      debugPrint('💾 Saving photo to temporary directory...');
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await picture.saveTo(imagePath);

      debugPrint('✅ Photo saved at: $imagePath');

      // Execute analysis immediately
      debugPrint('🔍 Starting immediate analysis...');
      final analysisResult = await _performImageAnalysis();

      debugPrint('📍 Getting location...');
      final locationResult = await _getLocationInfo();

      debugPrint('🧾 Navigating to confirmation screen...');
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
      debugPrint('💥 Error in _takePicture(): $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
    }
  }

  /// List of waste classifications for random analysis simulation.
  ///
  /// These classifications represent different types of waste that can be
  /// identified by the image analysis system.
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

  /// Performs image analysis simulation.
  ///
  /// Simulates AI processing by returning a random waste classification
  /// from the predefined list. In a real implementation, this would
  /// use machine learning models to analyze the captured image.
  Future<String> _performImageAnalysis() async {
    debugPrint('=== Starting image analysis ===');

    // Simulate AI processing
    await Future.delayed(const Duration(seconds: 1));

    // Select random classification
    final randomIndex = _random.nextInt(_wasteClassifications.length);
    final selectedClassification = _wasteClassifications[randomIndex];

    debugPrint('=== Random classification debug ===');
    debugPrint('Total waste types: ${_wasteClassifications.length}');
    debugPrint('Selected random index: $randomIndex');
    debugPrint('Selected classification: $selectedClassification');
    debugPrint('===================================');

    return selectedClassification;
  }

  /// Gets location information for the captured photo.
  ///
  /// Uses LocationService to get current GPS coordinates with high accuracy.
  /// Falls back to default Medellín location if GPS is unavailable.
  Future<String> _getLocationInfo() async {
    debugPrint('📍 Getting location information...');

    try {
      // Get real location using LocationService
      debugPrint('🔍 Calling LocationService.getCurrentLocation()...');
      debugPrint('🔍 Before calling getCurrentLocation()');
      final locationResult = await LocationService.getCurrentLocation();
      debugPrint('🔍 After calling getCurrentLocation()');
      debugPrint(
        '📱 LocationService responded: success=${locationResult.success}',
      );

      if (locationResult.success &&
          locationResult.latitude != null &&
          locationResult.longitude != null) {
        final locationString =
            '${locationResult.latitude}, ${locationResult.longitude}';
        debugPrint('📍 Real location obtained: $locationString');
        debugPrint('📍 Accuracy: ±${locationResult.accuracy}m');
        return locationString;
      } else {
        debugPrint(
          '⚠️ Could not get real location: ${locationResult.errorMessage}',
        );
        debugPrint('🔄 isLowAccuracy: ${locationResult.isLowAccuracy}');
        // Fallback to default Medellín Centro location
        const fallbackLocation = '6.244203, -75.581212';
        debugPrint('📍 Using default location: $fallbackLocation');
        return fallbackLocation;
      }
    } catch (e) {
      debugPrint('💥 Error getting location: $e');
      debugPrint('💥 Stack trace: ${StackTrace.current}');
      // Fallback to default Medellín Centro location
      const fallbackLocation = '6.244203, -75.581212';
      debugPrint('📍 Using default location due to error: $fallbackLocation');
      return fallbackLocation;
    }
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
                'Initializing camera...',
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
            'Error initializing camera',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(child: CameraPreview(_cameraController!)),

          // Information overlay
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
                    'Point towards the waste and tap the button to classify it',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Capture button
                Center(
                  child: GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: EcoColors.secondary,
                          width: 4,
                        ),
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

                // Camera switch button
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

/// Screen for confirming photo capture and waste classification results.
///
/// Displays the captured photo along with analysis results and location
/// information. Allows user to confirm and submit the environmental report.
class PhotoConfirmationScreen extends StatefulWidget {
  /// Path to the captured image file.
  final String imagePath;

  /// Result of the waste classification analysis.
  final String analysisResult;

  /// Location information string in "lat, lng" format.
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
    debugPrint('🖼️ PhotoConfirmationScreen initialized');
    debugPrint('📊 Analysis result: ${widget.analysisResult}');
    debugPrint('📍 Location: ${widget.locationInfo}');
  }

  /// Registers the environmental report with the backend server.
  ///
  /// Sends the captured image, classification result, and location data
  /// to the backend API for storage and processing.
  Future<void> _registerReport() async {
    debugPrint('📝 Starting report registration...');

    setState(() {
      _isRegistering = true;
    });

    try {
      // Send real report to backend
      debugPrint('📤 Sending report to server...');

      // Parse location from string "lat, lon"
      final locationParts = widget.locationInfo.split(', ');
      final latitude = double.parse(locationParts[0]);
      final longitude = double.parse(locationParts[1]);

      final result = await ReportService.submitReport(
        imageFile: File(widget.imagePath),
        latitude: latitude,
        longitude: longitude,
        accuracy: 10.0, // Default accuracy
        classification: widget.analysisResult,
      );

      if (result.success) {
        final reportCode = result.reportCode!;
        debugPrint('✅ Report sent successfully with code: $reportCode');
      } else {
        debugPrint('❌ Error sending report: ${result.message}');
        throw Exception('Error sending report: ${result.message}');
      }

      final reportCode = result.reportCode!;

      if (mounted) {
        // Show success screen
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
      debugPrint('💥 Error registering report: $e');
      setState(() {
        _isRegistering = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering report: $e'),
            backgroundColor: EcoColors.error,
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
                border: Border.all(color: EcoColors.secondary, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
              ),
            ),
          ),

          // Analysis information
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
                  // Analysis result
                  Row(
                    children: [
                      const Icon(
                        Icons.recycling,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Classification:',
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

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Location:',
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

          // Action buttons
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
                      'Take again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Register button
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
                            'Register',
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

/// Screen displaying successful report submission.
///
/// Shows confirmation details including report code, waste type,
/// and location information after successful submission to backend.
class ReportSuccessScreen extends StatelessWidget {
  /// Unique identifier for the submitted report.
  final String reportCode;

  /// Type of waste that was classified.
  final String wasteType;

  /// Location where the report was created.
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

              // Title
              const Text(
                'Report Sent Successfully!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              // Subtitle
              const Text(
                'Report received successfully',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Report information
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Column(
                  children: [
                    // Report code
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

                    // Details
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Location: ',
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
                          'Classification: ',
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

              // Additional message
              const Text(
                'Save the report code for future reference.',
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
                        'Finish',
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
