// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:geolocator/geolocator.dart';

// Project imports:
import 'colors.dart';

/// Service class for handling GPS location operations.
///
/// This service provides methods for getting the current location with
/// high accuracy requirements, validating coordinates, and handling
/// location-related errors following best practices.
///
/// The service implements the official Dart naming conventions and
/// follows Material Design error handling patterns.
class LocationService {
  /// Private constructor to prevent instantiation.
  ///
  /// This class is designed to be used as a static utility class.
  const LocationService._();

  /// Required accuracy threshold in meters.
  ///
  /// Location readings must be within ±10 meters to be considered
  /// acceptable for environmental reporting purposes.
  static const double requiredAccuracy = 10.0;

  /// Gets the current GPS location with high accuracy requirements.
  ///
  /// This method performs the following operations:
  /// 1. Checks if location services are enabled
  /// 2. Requests location permissions if needed
  /// 3. Retrieves GPS position with high accuracy settings
  /// 4. Validates accuracy meets requirements
  ///
  /// Returns a [LocationResult] containing either:
  /// - Success with coordinates and accuracy
  /// - Low accuracy warning with option to proceed
  /// - Error with descriptive message
  ///
  /// Example usage:
  /// ```dart
  /// final result = await LocationService.getCurrentLocation();
  /// if (result.success) {
  ///   print('Location: ${result.latitude}, ${result.longitude}');
  /// }
  /// ```
  static Future<LocationResult> getCurrentLocation() async {
    try {
      debugPrint('📍 LocationService: Starting getCurrentLocation()');

      // 1. Check if location services are enabled
      debugPrint('📍 LocationService: Checking location services...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📍 LocationService: Services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        debugPrint('❌ LocationService: Location services disabled');
        return LocationResult.error(
          'Location services are disabled. '
          'Please enable location in your device settings.',
        );
      }

      // 2. Check permissions
      debugPrint('📍 LocationService: Checking permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 LocationService: Current permissions: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('📍 LocationService: Requesting permissions...');
        permission = await Geolocator.requestPermission();
        debugPrint(
          '📍 LocationService: Permissions after request: $permission',
        );

        if (permission == LocationPermission.denied) {
          debugPrint('❌ LocationService: Permissions denied');
          return LocationResult.error(
            'Location permissions denied. '
            'The app needs access to your location to register the report.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ LocationService: Permissions permanently denied');
        return LocationResult.error(
          'Location permissions have been permanently denied. '
          'Go to settings and enable permissions manually.',
        );
      }

      // 3. Get location with high precision settings
      debugPrint('📍 LocationService: Getting GPS position...');
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0, // No distance filter for maximum precision
        ),
      ).timeout(const Duration(seconds: 30)); // 30 second timeout

      debugPrint(
        '📍 LocationService: Position obtained - Lat: ${position.latitude}, Lng: ${position.longitude}, Accuracy: ±${position.accuracy}m',
      );

      // 4. Check if accuracy meets requirements (±10 meters)
      if (position.accuracy > requiredAccuracy) {
        debugPrint(
          '⚠️ LocationService: Low accuracy - required: ±${requiredAccuracy}m, actual: ±${position.accuracy}m',
        );
        return LocationResult.lowAccuracy(
          position.latitude,
          position.longitude,
          position.accuracy,
          'Current accuracy is ±${position.accuracy.toStringAsFixed(1)}m. '
          'Required: ±${requiredAccuracy.toStringAsFixed(1)}m or better. '
          'Do you want to use this location or try again?',
        );
      }

      debugPrint('✅ LocationService: Successful location - returning result');
      return LocationResult.success(
        position.latitude,
        position.longitude,
        position.accuracy,
      );
    } catch (e) {
      debugPrint('💥 LocationService: Error - $e');
      return LocationResult.error(
        'Error getting location: $e. '
        'You can enter the location manually.',
      );
    }
  }

  /// Validates manually entered GPS coordinates.
  ///
  /// Checks that coordinates are within valid ranges:
  /// - Latitude: -90 to 90 degrees
  /// - Longitude: -180 to 180 degrees
  /// - Not default coordinates like (0,0)
  ///
  /// Returns `true` if coordinates are valid, `false` otherwise.
  static bool validateManualCoordinates(double? latitude, double? longitude) {
    // Validate coordinates are in valid ranges
    // Latitude: -90 to 90, Longitude: -180 to 180
    // Also validate they're not default coordinates like (0,0)
    if (latitude == null || longitude == null) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    if (latitude == 0 && longitude == 0) {
      return false; // Avoid (0,0) coordinates
    }

    return true;
  }

  /// Formats coordinates to a standardized string representation.
  ///
  /// Returns coordinates formatted to 6 decimal places for precision,
  /// separated by a comma and space.
  ///
  /// Example: "4.624335, -74.063644"
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}

/// Result class for location operations.
///
/// Encapsulates the result of a location request, including success/failure
/// status, coordinates, accuracy information, and error messages.
///
/// This class uses factory constructors to create different types of results:
/// - [LocationResult.success] for successful location retrieval
/// - [LocationResult.error] for failed operations
/// - [LocationResult.lowAccuracy] for successful but low-accuracy results
class LocationResult {
  /// Whether the location operation was successful.
  final bool success;

  /// The latitude coordinate in degrees.
  final double? latitude;

  /// The longitude coordinate in degrees.
  final double? longitude;

  /// The accuracy of the location in meters.
  final double? accuracy;

  /// Error message if the operation failed.
  final String? errorMessage;

  /// Whether the result has low accuracy but is still usable.
  final bool isLowAccuracy;

  /// Private constructor for creating LocationResult instances.
  LocationResult._({
    required this.success,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.errorMessage,
    this.isLowAccuracy = false,
  });

  /// Creates a successful location result.
  ///
  /// Use this factory when location was successfully obtained with
  /// acceptable accuracy.
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

  /// Creates an error result.
  ///
  /// Use this factory when location operation failed.
  factory LocationResult.error(String message) {
    return LocationResult._(success: false, errorMessage: message);
  }

  /// Creates a low accuracy result.
  ///
  /// Use this factory when location was obtained but accuracy
  /// doesn't meet requirements. User can decide whether to proceed.
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

/// Widget for displaying manual location input dialog.
///
/// This dialog allows users to manually enter GPS coordinates when
/// automatic location detection fails or provides insufficient accuracy.
///
/// The dialog validates input coordinates and returns a [LocationResult]
/// with the manually entered coordinates.
class ManualLocationDialog extends StatefulWidget {
  /// Creates a manual location input dialog.
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

  /// Validates input coordinates and returns result.
  ///
  /// Checks if both coordinates are entered, parses them as doubles,
  /// and validates they're within acceptable ranges before returning
  /// the result to the caller.
  void _validateAndReturn() {
    final latText = _latitudeController.text.trim();
    final lonText = _longitudeController.text.trim();

    if (latText.isEmpty || lonText.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both coordinates';
      });
      return;
    }

    final double? latitude = double.tryParse(latText);
    final double? longitude = double.tryParse(lonText);

    if (!LocationService.validateManualCoordinates(latitude, longitude)) {
      setState(() {
        _errorMessage =
            'Invalid coordinates. '
            'Latitude: -90 to 90, Longitude: -180 to 180';
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
      title: const Text('Manual Location Entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter the GPS coordinates of the place where you found the waste:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _latitudeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Latitude',
              hintText: 'Ex: 4.624335',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _longitudeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Longitude',
              hintText: 'Ex: -74.063644',
              border: OutlineInputBorder(),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: EcoColors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Tip: You can get coordinates from Google Maps',
            style: TextStyle(fontSize: 11, color: EcoColors.grey500),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _validateAndReturn,
          style: ElevatedButton.styleFrom(backgroundColor: EcoColors.secondary),
          child: const Text('Use Location'),
        ),
      ],
    );
  }
}
