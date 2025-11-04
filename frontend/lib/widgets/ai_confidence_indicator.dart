// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../colors.dart';

/// Widget to display AI classification confidence level
///
/// Shows a visual indicator of how confident the AI model is
/// in its waste classification prediction.
class AIConfidenceIndicator extends StatelessWidget {
  /// The confidence level from 0.0 to 1.0
  final double confidence;

  /// Whether to show in compact mode (for lists/cards)
  final bool compact;

  /// Whether to show the label text
  final bool showLabel;

  const AIConfidenceIndicator({
    super.key,
    required this.confidence,
    this.compact = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).toInt();
    final color = _getConfidenceColor(confidence);
    final icon = _getConfidenceIcon(confidence);
    final label = _getConfidenceLabel(confidence);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Clasificación IA',
                style: TextStyle(
                  fontSize: 11,
                  color: EcoColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get color based on confidence level
  Color _getConfidenceColor(double conf) {
    if (conf >= 0.85) return const Color(0xFF10B981); // Green
    if (conf >= 0.70) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red
  }

  /// Get icon based on confidence level
  IconData _getConfidenceIcon(double conf) {
    if (conf >= 0.85) return Icons.verified;
    if (conf >= 0.70) return Icons.info_outline;
    return Icons.warning_amber;
  }

  /// Get descriptive label based on confidence level
  String _getConfidenceLabel(double conf) {
    if (conf >= 0.85) return 'Alta';
    if (conf >= 0.70) return 'Media';
    return 'Baja';
  }
}

/// Specialized widget to show AI confidence in a badge style
class AIConfidenceBadge extends StatelessWidget {
  final double confidence;

  const AIConfidenceBadge({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    return AIConfidenceIndicator(
      confidence: confidence,
      compact: true,
      showLabel: false,
    );
  }
}

/// Widget to show detailed AI classification info
class AIClassificationDetails extends StatelessWidget {
  final double confidence;
  final String classification;
  final int? processingTimeMs;
  final String? modelVersion;

  const AIClassificationDetails({
    super.key,
    required this.confidence,
    required this.classification,
    this.processingTimeMs,
    this.modelVersion,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getConfidenceColor(confidence);
    final percentage = (confidence * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: EcoColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Clasificación Automática IA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: EcoColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Clasificación',
            classification,
            Icons.category_outlined,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Confianza',
            '$percentage%',
            Icons.analytics_outlined,
            color: color,
          ),
          if (processingTimeMs != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              'Tiempo de procesamiento',
              '${processingTimeMs}ms',
              Icons.speed_outlined,
            ),
          ],
          if (modelVersion != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              'Versión del modelo',
              modelVersion!,
              Icons.settings_suggest_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? EcoColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: EcoColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color ?? EcoColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double conf) {
    if (conf >= 0.85) return const Color(0xFF10B981);
    if (conf >= 0.70) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
