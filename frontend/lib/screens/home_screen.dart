// Flutter imports:
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:typed_data';

// Project imports:
import '../colors.dart';
import '../models/reporte.dart';
import '../services/firestore_service.dart';
import '../screens/firestore_reports_screen.dart';
import '../screens/user_profile_screen.dart';
import '../widgets/ai_confidence_indicator.dart';

/// Professional, responsive Home screen for EcoTrack
///
/// - Header with user info (avatar, name, level, progress, notifications)
/// - Summary: latest report card + key metrics (day/week/month)
/// - Quick actions: new report, reports, map, profile
/// - Recent activity: last 5 reports with status
/// - Achievements: small widget with level progress
/// - Accessibility-first (contrast, sizes) and microinteractions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();

  // Derive a level from points: 100 pts per level
  (int level, double progress) _levelFromPoints(int points) {
    final level = (points ~/ 100) + 1;
    final progress = (points % 100) / 100.0;
    return (level, progress.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        final padding = EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: isDesktop ? 24 : 12,
        );

        return Scaffold(
          backgroundColor: EcoColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: padding,
                    child: _Header(fs: _fs, levelFromPoints: _levelFromPoints),
                  ),
                ),

                // Summary section: latest report + metrics
                SliverToBoxAdapter(
                  child: Padding(
                    padding: padding,
                    child: _Summary(fs: _fs),
                  ),
                ),

                // Quick actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: padding,
                    child: _QuickActions(
                      onNewReport: _onNewReport,
                      onOpenReports: _onOpenReports,
                      onOpenMap: _onOpenMap,
                      onOpenProfile: _onOpenProfile,
                      isCompact: !isDesktop && !isTablet,
                    ),
                  ),
                ),

                // Recent activity and achievements in a responsive row/grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: padding,
                    child: isDesktop || isTablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Recent activity (flex larger)
                              Expanded(
                                flex: 3,
                                child: _RecentActivity(fs: _fs),
                              ),
                              const SizedBox(width: 16),
                              // Achievements / progress (flex smaller)
                              Expanded(
                                flex: 2,
                                child: _Achievements(
                                  fs: _fs,
                                  levelFromPoints: _levelFromPoints,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _RecentActivity(fs: _fs),
                              const SizedBox(height: 16),
                              _Achievements(
                                fs: _fs,
                                levelFromPoints: _levelFromPoints,
                              ),
                            ],
                          ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Navigation handlers
  void _onNewReport() {
    // The camera flow is launched from the bottom nav in MainScreen; here we navigate to the Reports screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FirestoreReportsScreen()));
  }

  void _onOpenReports() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FirestoreReportsScreen()));
  }

  void _onOpenMap() {
    // Use a small sample for map if needed; pull recent reports for context if desired
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FirestoreReportsScreen()));
  }

  void _onOpenProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const UserProfileScreen()));
  }
}

/// Header with user avatar, name, level and notifications badge
class _Header extends StatelessWidget {
  final FirestoreService fs;
  final (int, double) Function(int) levelFromPoints;
  const _Header({required this.fs, required this.levelFromPoints});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: fs.userProfileStream(),
      builder: (context, snapshot) {
        final loading = !snapshot.hasData;
        final data = snapshot.data ?? const {};
        final name = (data['displayName'] as String?) ?? 'Ciudadano Eco';
        final photoUrl = data['photoUrl'] as String?;
        final points = (data['points'] as num?)?.toInt() ?? 0;
        final (level, progress) = levelFromPoints(points);
        final unread = (data['notifications_unread'] as num?)?.toInt() ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: EcoColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with subtle animation
              AnimatedScale(
                scale: loading ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'E',
                          style: const TextStyle(
                            color: EcoColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Name + level + progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: EcoColors.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: EcoColors.onPrimary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Nivel $level',
                              style: const TextStyle(
                                color: EcoColors.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: EcoColors.onPrimary.withOpacity(
                                0.15,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                EcoColors.secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Notifications with badge
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: IconButton(
                        tooltip: 'Notificaciones',
                        onPressed: () {},
                        color: EcoColors.onPrimary,
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Summary section with latest report card and metrics dashboard
class _Summary extends StatelessWidget {
  final FirestoreService fs;
  const _Summary({required this.fs});

  @override
  Widget build(BuildContext context) {
    final userId = fs.currentUserId;
    final latest$ = fs.getReportsStream(limit: 1, userId: userId);
    final recent$ = fs.getReportsStream(limit: 50, userId: userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen',
          style: TextStyle(
            color: EcoColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Latest report
            Flexible(
              flex: 3,
              child: StreamBuilder<List<Reporte>>(
                stream: latest$,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _ErrorCard(
                      message: 'Error cargando último reporte',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const _LoadingCard(height: 140);
                  }
                  final reports = snapshot.data!;
                  if (reports.isEmpty) {
                    return _EmptyCard(
                      title: 'Aún no has enviado reportes',
                      subtitle:
                          'Crea tu primer reporte para ver el resumen aquí',
                      ctaLabel: 'Nuevo reporte',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FirestoreReportsScreen(),
                        ),
                      ),
                    );
                  }
                  final r = reports.first;
                  return _LatestReportCard(report: r);
                },
              ),
            ),
            const SizedBox(width: 12),
            // Metrics dashboard
            Flexible(
              flex: 2,
              child: StreamBuilder<List<Reporte>>(
                stream: recent$,
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const _ErrorCard(message: 'Error en métricas');
                  if (!snapshot.hasData) return const _LoadingCard(height: 140);
                  final items = snapshot.data!;
                  final now = DateTime.now();
                  int today = 0, week = 0, month = 0;
                  for (final r in items) {
                    final d = r.createdAt;
                    if (d.year == now.year &&
                        d.month == now.month &&
                        d.day == now.day)
                      today++;
                    if (now.difference(d).inDays < 7) week++;
                    if (now.difference(d).inDays < 30) month++;
                  }
                  return _MetricsCard(today: today, week: week, month: month);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Quick actions row
class _QuickActions extends StatelessWidget {
  final VoidCallback onNewReport;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenProfile;
  final bool isCompact;

  const _QuickActions({
    required this.onNewReport,
    required this.onOpenReports,
    required this.onOpenMap,
    required this.onOpenProfile,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _ActionButton(
        icon: Icons.add_a_photo,
        label: 'Nuevo reporte',
        onTap: onNewReport,
      ),
      _ActionButton(
        icon: Icons.receipt_long,
        label: 'Ver reportes',
        onTap: onOpenReports,
      ),
      _ActionButton(icon: Icons.map, label: 'Mapa', onTap: onOpenMap),
      _ActionButton(
        icon: Icons.emoji_events,
        label: 'Perfil',
        onTap: onOpenProfile,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones rápidas',
          style: TextStyle(
            color: EcoColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: isCompact
              ? buttons
              : buttons.map((b) => SizedBox(width: 180, child: b)).toList(),
        ),
      ],
    );
  }
}

/// Recent activity list (last 5 reports)
class _RecentActivity extends StatelessWidget {
  final FirestoreService fs;
  const _RecentActivity({required this.fs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Actividad reciente',
              style: TextStyle(
                color: EcoColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FirestoreReportsScreen(),
                ),
              ),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Reporte>>(
          stream: fs.getReportsStream(limit: 5, userId: fs.currentUserId),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const _ErrorCard(message: 'Error cargando actividad');
            if (!snapshot.hasData) return const _LoadingCard(height: 180);
            final items = snapshot.data!;
            if (items.isEmpty)
              return const _EmptyStrip(message: 'Sin actividad reciente');
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _ReportListTile(report: items[i]),
            );
          },
        ),
      ],
    );
  }
}

/// Achievements / progress widget
class _Achievements extends StatelessWidget {
  final FirestoreService fs;
  final (int, double) Function(int) levelFromPoints;
  const _Achievements({required this.fs, required this.levelFromPoints});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: fs.userProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const _ErrorCard(message: 'Error cargando logros');
        if (!snapshot.hasData) return const _LoadingCard(height: 180);
        final data = snapshot.data ?? const {};
        final points = (data['points'] as num?)?.toInt() ?? 0;
        final completed = (data['achievementsCompleted'] as List?)?.length ?? 0;
        final pending = (data['achievementsPending'] as List?)?.length ?? 0;
        final (lvl, prog) = levelFromPoints(points);

        return Container(
          decoration: BoxDecoration(
            color: EcoColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EcoColors.grey300),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: EcoColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Progreso y logros',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Circular progress to next level
                  SizedBox(
                    height: 74,
                    width: 74,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: prog,
                          strokeWidth: 8,
                          color: EcoColors.secondary,
                          backgroundColor: EcoColors.grey300,
                        ),
                        Text(
                          'Lv $lvl',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Puntos: $points',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Logros: $completed completados • $pending pendientes',
                          style: const TextStyle(
                            color: EcoColors.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ————— UI helpers —————

class _LatestReportCard extends StatelessWidget {
  final Reporte report;
  const _LatestReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EcoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoColors.grey300),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          _Thumb(report: report, size: 68),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.clasificacion,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    // AI Confidence Badge
                    if (report.isAiClassified && report.aiConfidence != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: AIConfidenceBadge(
                          confidence: report.aiConfidence!,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  report.ubicacion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EcoColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: _StatusChip(label: report.estado),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _formatDate(report.createdAt),
                        style: const TextStyle(
                          color: EcoColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _MetricsCard extends StatelessWidget {
  final int today;
  final int week;
  final int month;
  const _MetricsCard({
    required this.today,
    required this.week,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile(String title, int value, IconData icon, Color color) =>
        Flexible(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EcoColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EcoColors.grey300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: EcoColors.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        '$value',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 380;

    if (isNarrow) {
      return Column(
        children: [
          Row(
            children: [
              tile('Hoy', today, Icons.today_outlined, EcoColors.info),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              tile(
                'Semana',
                week,
                Icons.date_range_outlined,
                EcoColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              tile(
                'Mes',
                month,
                Icons.calendar_month_outlined,
                EcoColors.accent,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        tile('Hoy', today, Icons.today_outlined, EcoColors.info),
        const SizedBox(width: 4),
        tile('Semana', week, Icons.date_range_outlined, EcoColors.secondary),
        const SizedBox(width: 4),
        tile('Mes', month, Icons.calendar_month_outlined, EcoColors.accent),
      ],
    );
  }
}

class _ReportListTile extends StatelessWidget {
  final Reporte report;
  const _ReportListTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: EcoColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EcoColors.grey300),
        ),
        child: Row(
          children: [
            _Thumb(report: report, size: 44),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.clasificacion,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      // AI Badge for list items
                      if (report.isAiClassified && report.aiConfidence != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: AIConfidenceBadge(
                            confidence: report.aiConfidence!,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: _StatusChip(label: report.estado),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _formatDateTime(report.createdAt),
                          style: const TextStyle(
                            color: EcoColors.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} $hh:$mm';
  }
}

class _Thumb extends StatelessWidget {
  final Reporte report;
  final double size;
  const _Thumb({required this.report, this.size = 60});

  @override
  Widget build(BuildContext context) {
    // Try base64 first (robust against data URLs and missing padding), then fallback to URL, then placeholder.
    Uint8List? tryDecodeBase64(String raw) {
      try {
        var normalized = raw.trim();
        // Strip data URL prefix if present, e.g. "data:image/png;base64,xxxx"
        final commaIdx = normalized.indexOf(',');
        if (normalized.startsWith('data:') && commaIdx != -1) {
          normalized = normalized.substring(commaIdx + 1);
        }
        // Remove whitespace that could break decoding
        normalized = normalized.replaceAll(RegExp(r'\s'), '');
        // Fix missing padding
        final pad = normalized.length % 4;
        if (pad != 0) {
          normalized = normalized.padRight(normalized.length + (4 - pad), '=');
        }
        return base64Decode(normalized);
      } catch (_) {
        return null;
      }
    }

    Widget image;
    final hasBase64 =
        (report.fotoBase64 != null && report.fotoBase64!.isNotEmpty);
    final bytes = hasBase64 ? tryDecodeBase64(report.fotoBase64!) : null;
    if (bytes != null) {
      image = Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (report.fotoUrl.isNotEmpty) {
      image = Image.network(
        report.fotoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: EcoColors.grey300,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    } else {
      image = Container(
        width: size,
        height: size,
        color: EcoColors.grey300,
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }

    return ClipRRect(borderRadius: BorderRadius.circular(10), child: image);
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});
  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (label.toLowerCase()) {
      case 'pendiente':
      case 'recibido':
      case 'en recorrido':
        bg = Colors.blue.shade200;
        break;
      case 'recogido':
      case 'finalizado':
        bg = Colors.green.shade300;
        break;
      default:
        bg = Colors.grey.shade300;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({this.height = 120});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: EcoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoColors.grey300),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;
  const _EmptyCard({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoColors.grey300),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: EcoColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: EcoColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 0,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ElevatedButton(onPressed: onTap, child: Text(ctaLabel)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: EcoColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStrip extends StatelessWidget {
  final String message;
  const _EmptyStrip({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: EcoColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EcoColors.grey300),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: EcoColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: EcoColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EcoColors.grey300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: EcoColors.secondary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
