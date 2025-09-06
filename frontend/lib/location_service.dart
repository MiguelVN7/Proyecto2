import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'colors.dart';

class LocationService {
  static const double requiredAccuracy =
      10.0; // Precisión requerida: ±10 metros

  static Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error(
          'Los servicios de ubicación están deshabilitados. '
          'Por favor, habilita la ubicación en la configuración de tu dispositivo.',
        );
      }

      // 2. Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.error(
            'Permisos de ubicación denegados. '
            'La app necesita acceso a tu ubicación para registrar el reporte.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error(
          'Los permisos de ubicación han sido denegados permanentemente. '
          'Ve a configuración y habilita los permisos manualmente.',
        );
      }

      // 3. Obtener ubicación con configuración de alta precisión
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0, // Sin filtro de distancia para mayor precisión
        ),
      ).timeout(const Duration(seconds: 30)); // Timeout de 30 segundos

      // 4. Verificar si la precisión cumple los requisitos (±10 metros)
      if (position.accuracy > requiredAccuracy) {
        return LocationResult.lowAccuracy(
          position.latitude,
          position.longitude,
          position.accuracy,
          'La precisión actual es de ±${position.accuracy.toStringAsFixed(1)}m. '
          'Se requiere ±${requiredAccuracy.toStringAsFixed(1)}m o mejor. '
          '¿Deseas usar esta ubicación o intentar de nuevo?',
        );
      }

      return LocationResult.success(
        position.latitude,
        position.longitude,
        position.accuracy,
      );
    } catch (e) {
      return LocationResult.error(
        'Error al obtener la ubicación: $e. '
        'Puedes ingresar la ubicación manualmente.',
      );
    }
  }

  static bool validateManualCoordinates(double? latitude, double? longitude) {
    // Validar que las coordenadas están en rangos válidos
    // Latitud: -90 a 90, Longitud: -180 a 180
    // También validar que no sean coordenadas por defecto como (0,0)
    if (latitude == null || longitude == null) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    if (latitude == 0 && longitude == 0) {
      return false; // Evitar coordenadas (0,0)
    }

    return true;
  }

  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}

class LocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? errorMessage;
  final bool isLowAccuracy;

  LocationResult._({
    required this.success,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.errorMessage,
    this.isLowAccuracy = false,
  });

  factory LocationResult.success(
    double latitude,
    double longitude,
    double accuracy,
  ) {
    return LocationResult._(
      success: true,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
  }

  factory LocationResult.error(String message) {
    return LocationResult._(success: false, errorMessage: message);
  }

  factory LocationResult.lowAccuracy(
    double latitude,
    double longitude,
    double accuracy,
    String message,
  ) {
    return LocationResult._(
      success: true,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      errorMessage: message,
      isLowAccuracy: true,
    );
  }
}

// Widget para mostrar diálogo de ubicación manual
class ManualLocationDialog extends StatefulWidget {
  const ManualLocationDialog({super.key});

  @override
  State<ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _validateAndReturn() {
    final latText = _latitudeController.text.trim();
    final lonText = _longitudeController.text.trim();

    if (latText.isEmpty || lonText.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa ambas coordenadas';
      });
      return;
    }

    final double? latitude = double.tryParse(latText);
    final double? longitude = double.tryParse(lonText);

    if (!LocationService.validateManualCoordinates(latitude, longitude)) {
      setState(() {
        _errorMessage =
            'Coordenadas inválidas. '
            'Latitud: -90 a 90, Longitud: -180 a 180';
      });
      return;
    }

    Navigator.of(
      context,
    ).pop(LocationResult.success(latitude!, longitude!, 0.0));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ingreso Manual de Ubicación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ingresa las coordenadas GPS del lugar donde encontraste el residuo:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _latitudeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Latitud',
              hintText: 'Ej: 4.624335',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _longitudeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Longitud',
              hintText: 'Ej: -74.063644',
              border: OutlineInputBorder(),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: EcoColors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Tip: Puedes obtener las coordenadas desde Google Maps',
            style: TextStyle(fontSize: 11, color: EcoColors.grey500),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _validateAndReturn,
          style: ElevatedButton.styleFrom(backgroundColor: EcoColors.secondary),
          child: const Text('Usar Ubicación'),
        ),
      ],
    );
  }
}
