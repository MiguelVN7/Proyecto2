class PointsRules {
  // Base points by waste type (case-insensitive keys)
  static const Map<String, int> baseByType = {
    'orgánico': 8,
    'organico': 8,
    'plástico': 10,
    'plastico': 10,
    'vidrio': 10,
    'papel': 8,
    'cartón': 8,
    'carton': 8,
    'papel/cartón': 8,
    'papel/carton': 8,
    'metal': 12,
    'electrónicos': 15,
    'electronicos': 15,
    'peligrosos': 20,
    'otro': 5,
  };

  // Multipliers by priority
  static const Map<String, double> multiplierByPriority = {
    'baja': 1.0,
    'media': 1.2,
    'alta': 1.5,
  };

  static int computePoints({
    required String tipoResiduo,
    required String prioridad,
  }) {
    final tipoKey = tipoResiduo.trim().toLowerCase();
    final prioKey = prioridad.trim().toLowerCase();
    final base = baseByType[tipoKey] ?? 5;
    final mult = multiplierByPriority[prioKey] ?? 1.2; // default to Media
    return (base * mult).round();
  }

  // Canonical list of types to show in the UI table
  static const List<String> canonicalTypes = [
    'Orgánico',
    'Plástico',
    'Vidrio',
    'Papel/Cartón',
    'Metal',
    'Electrónicos',
    'Peligrosos',
    'Otro',
  ];

  // Canonical priorities to show in the UI
  static const List<String> canonicalPriorities = ['Baja', 'Media', 'Alta'];

  // Bonus points per status change
  // Keys must be lowercase and match ReportStatus.displayName in lowercase
  static const Map<String, int> bonusByStatus = {
    'recibido': 2,
    'en recorrido': 3,
    'recogido': 5,
    'finalizado': 10,
    // 'pendiente': 0, // usually not a change target
  };

  static int statusBonus(String statusDisplayName) {
    return bonusByStatus[statusDisplayName.trim().toLowerCase()] ?? 0;
  }
}
