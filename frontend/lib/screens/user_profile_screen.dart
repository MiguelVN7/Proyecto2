import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../colors.dart';
import '../services/firestore_service.dart';
import '../gamification/points_rules.dart';
import '../gamification/achievements.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? _dismissedAchievementKey;
  @override
  void initState() {
    super.initState();
    // Seed a profile if missing (safe no-op if exists)
    FirestoreService().ensureUserProfileSeed();
    // Reconcile achievements from deterministic counters (idempotent)
    // Useful if reports were created before awarding logic ran
    // or if the app lost connectivity during awarding.
    // We don't await here to keep UI responsive.
    // ignore: discarded_futures
    FirestoreService().reconcileAchievementsFromCounters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.primary,
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: FirestoreService().userProfileStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? {};
            final displayName = (data['displayName'] as String?) ?? 'EcoTrack';
            final email = data['email'] as String?;
            final photoUrl = data['photoUrl'] as String?;
            final points = (data['points'] as num?)?.toInt() ?? 0;
            final level = (points ~/ 100) + 1;
            final progress = ((points % 100) / 100.0).clamp(0.0, 1.0);
            final badges =
                (data['badges'] as List?)?.cast<String>() ?? const [];
            final achievementsCompleted =
                (data['achievementsCompleted'] as List?)?.cast<String>() ??
                const [];
            // If pending list is missing, compute from registry
            List<String> achievementsPending =
                (data['achievementsPending'] as List?)?.cast<String>() ??
                const [];
            if (achievementsPending.isEmpty) {
              final completedSet = achievementsCompleted.toSet();
              achievementsPending = Achievements.all
                  .map((a) => a.id)
                  .where((id) => !completedSet.contains(id))
                  .toList();
            }

            // Remove from Pending those achievements whose thresholds are already met
            // according to deterministic counters (so UI reflects progress even if awarding was delayed)
            final reportsTotal = (data['reports_total'] as num?)?.toInt() ?? 0;
            final finalizedTotal =
                (data['reports_finalized_total'] as num?)?.toInt() ?? 0;
            final metByCounters = <String>{
              for (final a in Achievements.all)
                if (a.type == AchievementType.totalReports &&
                    reportsTotal >= a.threshold)
                  a.id,
              for (final a in Achievements.all)
                if (a.type == AchievementType.finalizedReports &&
                    finalizedTotal >= a.threshold)
                  a.id,
            };
            achievementsPending = achievementsPending
                .where((id) => !metByCounters.contains(id))
                .toList();

            // Latest achievement banner (celebration)
            Map<String, dynamic>? latestAch;
            final achLog = (data['achievements_log'] as List?)?.cast() ?? [];
            DateTime? latestAt;
            for (final e in achLog) {
              if (e is Map<String, dynamic>) {
                final at =
                    _tsToDate(e['awarded_at']) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                if (latestAt == null || at.isAfter(latestAt)) {
                  latestAt = at;
                  latestAch = e;
                }
              }
            }

            return Stack(
              children: [
                Column(
                  children: [
                    // Header
                    Container(
                      color: EcoColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: EcoColors.onPrimary,
                            child: _buildAvatar(photoUrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: EcoColors.onPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (email != null)
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: EcoColors.onPrimary.withOpacity(
                                        0.8,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: EcoColors.onPrimary,
                            ),
                            onPressed: _onEditProfile,
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: EcoColors.surface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(45),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (latestAch != null)
                                _celebrationBanner(latestAch),
                              if (latestAch != null) const SizedBox(height: 16),
                              _levelCard(
                                level: level,
                                progress: progress,
                                points: points,
                              ),
                              const SizedBox(height: 16),
                              _pointsRulesTable(),
                              const SizedBox(height: 16),
                              _pointsHistorySection(),
                              const SizedBox(height: 16),
                              _badgesSection(badges),
                              const SizedBox(height: 16),
                              _achievementsSection(
                                achievementsCompleted: achievementsCompleted,
                                achievementsPending: achievementsPending,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pointsHistorySection() {
    final uid = FirestoreService().currentUserId;
    if (uid == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: EcoColors.accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de puntos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .where('user_id', isEqualTo: uid)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'No se pudo cargar el historial (${snapshot.error}).',
                  style: TextStyle(color: Colors.red.withOpacity(0.8)),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  'Sin movimientos aún. ¡Crea tu primer reporte! 🌱',
                  style: TextStyle(color: Colors.black.withOpacity(0.6)),
                );
              }

              final events = <_PointEvent>[];
              for (final doc in snapshot.data!.docs) {
                final data = doc.data();
                final createdAtTs = data['created_at'];
                final updatedAtTs = data['updated_at'];
                final createdAt =
                    _tsToDate(createdAtTs) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final updatedAt = _tsToDate(updatedAtTs) ?? createdAt;
                final tipo = (data['tipo_residuo'] as String?) ?? '';
                final prio = (data['prioridad'] as String?) ?? '';

                int? creationPts = (data['points_awarded'] as num?)?.toInt();
                // Fallback: derive from rules if field is missing
                if (creationPts == null || creationPts <= 0) {
                  creationPts = PointsRules.computePoints(
                    tipoResiduo: tipo,
                    prioridad: prio,
                  );
                }
                if (creationPts > 0) {
                  events.add(
                    _PointEvent(
                      points: creationPts,
                      label: 'Creación de reporte ($tipo $prio)',
                      date: createdAt,
                      kind: _PointEventKind.creation,
                    ),
                  );
                }

                final statusLog = (data['status_points_log'] as List?) ?? [];
                for (final e in statusLog) {
                  if (e is Map) {
                    final status = (e['status'] as String?) ?? 'Estado';
                    final pts = (e['points'] as num?)?.toInt() ?? 0;
                    final at = _tsToDate(e['awarded_at']) ?? updatedAt;
                    if (pts > 0) {
                      events.add(
                        _PointEvent(
                          points: pts,
                          label: status,
                          date: at,
                          kind: _PointEventKind.status,
                        ),
                      );
                    }
                  }
                }
              }

              // Sort newest first
              events.sort((a, b) => b.date.compareTo(a.date));
              final top = events.take(10).toList();

              if (top.isEmpty) {
                return Text(
                  'Sin movimientos aún. ¡Crea tu primer reporte! 🌱',
                  style: TextStyle(color: Colors.black.withOpacity(0.6)),
                );
              }

              return Column(
                children: top
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            _eventIcon(e),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '+${e.points} puntos — ${e.label}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(e.date),
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _eventIcon(_PointEvent e) {
    IconData icon;
    Color bg;
    switch (e.kind) {
      case _PointEventKind.creation:
        icon = Icons.add_circle;
        bg = Colors.green.withOpacity(0.15);
        break;
      case _PointEventKind.status:
        final label = e.label.toLowerCase();
        if (label.contains('finalizado')) {
          icon = Icons.emoji_events;
          bg = Colors.amber.withOpacity(0.2);
        } else if (label.contains('recogido')) {
          icon = Icons.check_circle;
          bg = Colors.lightGreen.withOpacity(0.2);
        } else if (label.contains('en recorrido')) {
          icon = Icons.route;
          bg = Colors.blue.withOpacity(0.15);
        } else if (label.contains('recibido')) {
          icon = Icons.inbox;
          bg = Colors.blueGrey.withOpacity(0.15);
        } else {
          icon = Icons.flag;
          bg = Colors.grey.withOpacity(0.15);
        }
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 20),
    );
  }

  DateTime? _tsToDate(dynamic ts) {
    if (ts == null) return null;
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    return null;
  }

  String _formatDate(DateTime dt) {
    // Formato compacto: dd/MM HH:mm
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  Widget _celebrationBanner(Map<String, dynamic> ach) {
    final id = (ach['id'] as String?) ?? 'logro';
    final title = (ach['title'] as String?) ?? 'Nuevo logro';
    final pts = (ach['points'] as num?)?.toInt() ?? 0;
    final at = _tsToDate(ach['awarded_at']) ?? DateTime.now();
    final key = '$id-${at.millisecondsSinceEpoch}';
    if (_dismissedAchievementKey == key) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Nuevo logro desbloqueado!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 14)),
                Text(
                  '+$pts puntos · ${_formatDate(at)}',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _dismissedAchievementKey = key),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _pointsRulesTable() {
    // Table with base points by type and multipliers by priority
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: EcoColors.secondary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tabla de acumulación de puntos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Base by type
          const Text('Puntos base por tipo de residuo:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PointsRules.canonicalTypes.map((type) {
              final key = type.toLowerCase();
              final base =
                  PointsRules.baseByType[key] ??
                  PointsRules.baseByType[key.replaceAll('ó', 'o')] ??
                  PointsRules.baseByType[key.replaceAll('á', 'a')] ??
                  5;
              return Chip(
                label: Text('$type: $base pts'),
                backgroundColor: EcoColors.accent.withOpacity(0.15),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Multiplicador por prioridad:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PointsRules.canonicalPriorities.map((p) {
              final mult =
                  PointsRules.multiplierByPriority[p.toLowerCase()] ?? 1.0;
              return Chip(
                label: Text('$p ×${mult.toStringAsFixed(1)}'),
                backgroundColor: Colors.blueGrey.withOpacity(0.12),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Ejemplo: Plástico Alta = 10 × 1.5 = 15 puntos',
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return const Icon(Icons.person, color: EcoColors.primary, size: 28);
    }
    if (photoUrl.startsWith('data:')) {
      Uint8List? decode(String raw) {
        try {
          var normalized = raw.trim();
          final commaIndex = normalized.indexOf(',');
          if (commaIndex >= 0)
            normalized = normalized.substring(commaIndex + 1);
          normalized = normalized.replaceAll(RegExp(r'\s'), '');
          final pad = normalized.length % 4;
          if (pad != 0)
            normalized = normalized.padRight(
              normalized.length + (4 - pad),
              '=',
            );
          return base64Decode(normalized);
        } catch (_) {
          return null;
        }
      }

      final bytes = decode(photoUrl);
      if (bytes != null) {
        return ClipOval(
          child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
        );
      }
      return const Icon(Icons.person, color: EcoColors.primary, size: 28);
    }
    return ClipOval(
      child: Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, color: EcoColors.primary, size: 28),
      ),
    );
  }

  Widget _levelCard({
    required int level,
    required double progress,
    required int points,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surface,
        borderRadius: BorderRadius.circular(45),
        border: Border.all(color: EcoColors.accent, width: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nivel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Lv $level',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: EcoColors.secondary.withOpacity(0.2),
              color: EcoColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$points puntos · ${(progress * 100).toStringAsFixed(0)}% hacia el siguiente nivel',
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _badgesSection(List<String> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insignias',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (badges.isEmpty)
          Text(
            'Aún no tienes insignias. ¡Sigue reportando! 😊',
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: badges
                .map(
                  (b) => Chip(
                    label: Text(b),
                    backgroundColor: EcoColors.accent.withOpacity(0.2),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _achievementsSection({
    required List<String> achievementsCompleted,
    required List<String> achievementsPending,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logros',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (achievementsCompleted.isEmpty && achievementsPending.isEmpty)
          Text(
            'Sin logros aún. ¡Empieza con tu primer reporte! 🌱',
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
          ),
        if (achievementsCompleted.isNotEmpty) ...[
          Text(
            'Completados',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: achievementsCompleted
                .map(
                  (a) => Chip(
                    label: Text(Achievements.labelFor(a)),
                    backgroundColor: Colors.green.withOpacity(0.15),
                    avatar: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (achievementsPending.isNotEmpty) ...[
          Text(
            'Pendientes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: achievementsPending
                .map(
                  (a) => Chip(
                    label: Text(Achievements.labelFor(a)),
                    backgroundColor: Colors.orange.withOpacity(0.15),
                    avatar: const Icon(
                      Icons.hourglass_top,
                      color: Colors.orange,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _onEditProfile() async {
    final controller = TextEditingController();
    final current = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirestoreService().currentUserId)
        .get();
    controller.text = (current.data()?['displayName'] as String?) ?? '';
    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tu nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await FirestoreService().updateUserProfile({'displayName': result});
  }
}

enum _PointEventKind { creation, status }

class _PointEvent {
  final int points;
  final String label;
  final DateTime date;
  final _PointEventKind kind;
  _PointEvent({
    required this.points,
    required this.label,
    required this.date,
    required this.kind,
  });
}
