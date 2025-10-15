import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:eco_track/services/report_query.dart';

void main() {
  test('userReports devuelve solo reportes del usuario, ordenados desc por created_at', () async {
    final db = FakeFirebaseFirestore();
    final q = ReportQuery(db: db);

    // Datos de prueba
    await db.collection('reports').add({
      'user_id': 'u1',
      'estado': 'Pendiente',
      'created_at': DateTime(2025, 10, 13),
      'titulo': 'R1-u1',
    });
    await db.collection('reports').add({
      'user_id': 'u2',
      'estado': 'Pendiente',
      'created_at': DateTime(2025, 10, 12),
      'titulo': 'R1-u2',
    });
    await db.collection('reports').add({
      'user_id': 'u1',
      'estado': 'Completado',
      'created_at': DateTime(2025, 10, 14),
      'titulo': 'R2-u1',
    });

    final snap = await q.userReports('u1').get();
    final titles = snap.docs.map((d) => d['titulo'] as String).toList();

    expect(titles, ['R2-u1', 'R1-u1']); // orden desc por created_at
    expect(titles.contains('R1-u2'), isFalse);
  });

  test('userReportsByEstado filtra por user_id y estado', () async {
    final db = FakeFirebaseFirestore();
    final q = ReportQuery(db: db);

    await db.collection('reports').add({
      'user_id': 'u1',
      'estado': 'Pendiente',
      'created_at': DateTime(2025, 10, 13),
      'titulo': 'R1-u1',
    });
    await db.collection('reports').add({
      'user_id': 'u1',
      'estado': 'Completado',
      'created_at': DateTime(2025, 10, 14),
      'titulo': 'R2-u1',
    });

    final snap = await q.userReportsByEstado('u1', 'Pendiente').get();
    expect(snap.docs.length, 1);
    expect(snap.docs.first['titulo'], 'R1-u1');
  });
}
