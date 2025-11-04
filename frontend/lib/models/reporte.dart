// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';

// Report status enumeration for type-safe state management
enum ReportStatus {
  pending('Pendiente', 'pendiente'),
  received('Recibido', 'received'),
  assigned('Asignado', 'assigned'),
  inProgress('En Proceso', 'in_progress'),
  completed('Resuelto', 'completed'),
  cancelled('Cancelado', 'cancelled');

  const ReportStatus(this.displayName, this.firestoreValue);
  final String displayName;
  final String firestoreValue;

  /// Creates ReportStatus from string value (from Firestore)
  static ReportStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
      case 'pending':
        return ReportStatus.pending;
      case 'recibido':
      case 'received':
        return ReportStatus.received;
      case 'asignado':
      case 'assigned':
        return ReportStatus.assigned;
      case 'en proceso':
      case 'en_proceso':
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'resuelto':
      case 'finalizado':
      case 'completed':
        return ReportStatus.completed;
      case 'cancelado':
      case 'cancelled':
        return ReportStatus.cancelled;
      default:
        return ReportStatus.pending;
    }
  }
}

// Se crea un modelo para los reportes

class Reporte {
  final String id;
  final String fotoUrl;
  final String? fotoBase64;
  final String ubicacion;
  final String clasificacion;
  final String estado;
  final String prioridad;
  final String tipoResiduo;
  final double lat;
  final double lng;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? deviceInfo;
  final double? accuracy;
  final String? userId;

  // AI Classification fields
  final double? aiConfidence; // AI confidence level (0.0 - 1.0)
  final int? aiProcessingTimeMs; // Processing time in milliseconds
  final DateTime? aiClassifiedAt; // Timestamp when AI classified
  final String? aiModelVersion; // Version of AI model used

  Reporte({
    required this.id,
    required this.fotoUrl,
    this.fotoBase64,
    required this.ubicacion,
    required this.clasificacion,
    required this.estado,
    required this.prioridad,
    required this.tipoResiduo,
    required this.lat,
    required this.lng,
    required this.createdAt,
    required this.updatedAt,
    this.deviceInfo,
    this.accuracy,
    this.userId,
    // AI fields
    this.aiConfidence,
    this.aiProcessingTimeMs,
    this.aiClassifiedAt,
    this.aiModelVersion,
  });

  /// Whether this report was classified by AI
  bool get isAiClassified => aiConfidence != null && aiConfidence! > 0;

  /// Gets the current report status as an enum
  ReportStatus get statusEnum => ReportStatus.fromString(estado);

  /// Creates a copy of this report with updated status
  Reporte copyWith({
    String? id,
    String? fotoUrl,
    String? fotoBase64,
    String? ubicacion,
    String? clasificacion,
    String? estado,
    String? prioridad,
    String? tipoResiduo,
    double? lat,
    double? lng,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceInfo,
    double? accuracy,
    String? userId,
    // AI fields
    double? aiConfidence,
    int? aiProcessingTimeMs,
    DateTime? aiClassifiedAt,
    String? aiModelVersion,
  }) {
    return Reporte(
      id: id ?? this.id,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fotoBase64: fotoBase64 ?? this.fotoBase64,
      ubicacion: ubicacion ?? this.ubicacion,
      clasificacion: clasificacion ?? this.clasificacion,
      estado: estado ?? this.estado,
      prioridad: prioridad ?? this.prioridad,
      tipoResiduo: tipoResiduo ?? this.tipoResiduo,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      accuracy: accuracy ?? this.accuracy,
      userId: userId ?? this.userId,
      // AI fields
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiProcessingTimeMs: aiProcessingTimeMs ?? this.aiProcessingTimeMs,
      aiClassifiedAt: aiClassifiedAt ?? this.aiClassifiedAt,
      aiModelVersion: aiModelVersion ?? this.aiModelVersion,
    );
  }

  /// Updates report status with enum value
  Reporte updateStatus(ReportStatus newStatus) {
    return copyWith(estado: newStatus.displayName, updatedAt: DateTime.now());
  }

  /// Convert Reporte to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'foto_url': fotoUrl,
      'foto_base64': fotoBase64,
      'ubicacion': ubicacion,
      'clasificacion': clasificacion,
      'estado': estado,
      'prioridad': prioridad,
      'tipo_residuo': tipoResiduo,
      'location': {
        'latitude': lat,
        'longitude': lng,
        'accuracy': accuracy ?? 0.0,
      },
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'device_info': deviceInfo,
      'user_id': userId,
      // AI fields
      if (aiConfidence != null) 'ai_confidence': aiConfidence,
      if (aiProcessingTimeMs != null)
        'ai_processing_time_ms': aiProcessingTimeMs,
      if (aiClassifiedAt != null)
        'ai_classified_at': Timestamp.fromDate(aiClassifiedAt!),
      if (aiModelVersion != null) 'ai_model_version': aiModelVersion,
    };
  }

  /// Create Reporte from Firestore document
  factory Reporte.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final location =
        (data['location'] as Map<String, dynamic>?) ??
        {'latitude': 0.0, 'longitude': 0.0, 'accuracy': 0.0};

    return Reporte(
      id: doc.id,
      fotoUrl: data['foto_url'] ?? '',
      fotoBase64: data['foto_base64'],
      ubicacion: data['ubicacion'] ?? '',
      clasificacion: data['clasificacion'] ?? '',
      estado: data['estado'] ?? 'Pendiente',
      prioridad: data['prioridad'] ?? 'Media',
      tipoResiduo: data['tipo_residuo'] ?? '',
      lat: (location['latitude'] as num).toDouble(),
      lng: (location['longitude'] as num).toDouble(),
      accuracy: (location['accuracy'] as num?)?.toDouble(),
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updated_at'] is Timestamp)
          ? (data['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
      deviceInfo: data['device_info'],
      userId: data['user_id'],
      // AI fields
      aiConfidence: (data['ai_confidence'] as num?)?.toDouble(),
      aiProcessingTimeMs: (data['ai_processing_time_ms'] as num?)?.toInt(),
      aiClassifiedAt: (data['ai_classified_at'] is Timestamp)
          ? (data['ai_classified_at'] as Timestamp).toDate()
          : null,
      aiModelVersion: data['ai_model_version'] as String?,
    );
  }

  /// Create Reporte from Firestore document data (for real-time listeners)
  factory Reporte.fromFirestoreData(String id, Map<String, dynamic> data) {
    final location =
        (data['location'] as Map<String, dynamic>?) ??
        {'latitude': 0.0, 'longitude': 0.0, 'accuracy': 0.0};

    return Reporte(
      id: id,
      fotoUrl: data['foto_url'] ?? '',
      fotoBase64: data['foto_base64'],
      ubicacion: data['ubicacion'] ?? '',
      clasificacion: data['clasificacion'] ?? '',
      estado: data['estado'] ?? 'Pendiente',
      prioridad: data['prioridad'] ?? 'Media',
      tipoResiduo: data['tipo_residuo'] ?? '',
      lat: (location['latitude'] as num).toDouble(),
      lng: (location['longitude'] as num).toDouble(),
      accuracy: (location['accuracy'] as num?)?.toDouble(),
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updated_at'] is Timestamp)
          ? (data['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
      deviceInfo: data['device_info'],
      userId: data['user_id'],
      // AI fields
      aiConfidence: (data['ai_confidence'] as num?)?.toDouble(),
      aiProcessingTimeMs: (data['ai_processing_time_ms'] as num?)?.toInt(),
      aiClassifiedAt: (data['ai_classified_at'] is Timestamp)
          ? (data['ai_classified_at'] as Timestamp).toDate()
          : null,
      aiModelVersion: data['ai_model_version'] as String?,
    );
  }

  /// Create a new Reporte with default values
  factory Reporte.create({
    required String id,
    required String fotoUrl,
    String? fotoBase64,
    required String ubicacion,
    required String clasificacion,
    required String tipoResiduo,
    required double lat,
    required double lng,
    String prioridad = 'Media',
    String estado = 'Pendiente',
    double? accuracy,
    String? deviceInfo,
    String? userId,
  }) {
    final now = DateTime.now();
    return Reporte(
      id: id,
      fotoUrl: fotoUrl,
      fotoBase64: fotoBase64,
      ubicacion: ubicacion,
      clasificacion: clasificacion,
      estado: estado,
      prioridad: prioridad,
      tipoResiduo: tipoResiduo,
      lat: lat,
      lng: lng,
      createdAt: now,
      updatedAt: now,
      accuracy: accuracy,
      deviceInfo: deviceInfo,
      userId: userId,
    );
  }
}
