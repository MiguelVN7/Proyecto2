class Achievement {
  final String id;
  final String title;
  final String description;
  final int rewardPoints;
  final AchievementType type;
  final int threshold;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    required this.type,
    required this.threshold,
  });
}

enum AchievementType {
  totalReports, // total reports created by user
  finalizedReports, // reports reached Finalizado by user
}

class Achievements {
  static const List<Achievement> all = [
    Achievement(
      id: 'primer_reporte',
      title: 'Primer reporte',
      description: 'Crea tu primer reporte ciudadano',
      rewardPoints: 20,
      type: AchievementType.totalReports,
      threshold: 1,
    ),
    Achievement(
      id: '5_reportes',
      title: '5 reportes',
      description: 'Crea 5 reportes ciudadanos',
      rewardPoints: 40,
      type: AchievementType.totalReports,
      threshold: 5,
    ),
    Achievement(
      id: '10_reportes',
      title: '10 reportes',
      description: 'Crea 10 reportes ciudadanos',
      rewardPoints: 80,
      type: AchievementType.totalReports,
      threshold: 10,
    ),
    Achievement(
      id: 'primer_finalizado',
      title: 'Primer reporte finalizado',
      description: 'Lleva un reporte hasta estado Finalizado',
      rewardPoints: 30,
      type: AchievementType.finalizedReports,
      threshold: 1,
    ),
    Achievement(
      id: '5_finalizados',
      title: '5 reportes finalizados',
      description: 'Consigue 5 reportes con estado Finalizado',
      rewardPoints: 60,
      type: AchievementType.finalizedReports,
      threshold: 5,
    ),
  ];

  static Map<String, Achievement> get byId => {for (final a in all) a.id: a};

  static String labelFor(String id) => byId[id]?.title ?? id;
}
