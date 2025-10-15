// Consultas testeables para "solo mis reportes".
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportQuery {
  final FirebaseFirestore db;
  ReportQuery({required this.db});

  Query<Map<String, dynamic>> userReports(String uid, {int limit = 50}) {
    return db
        .collection('reports')
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(limit);
  }

  Query<Map<String, dynamic>> userReportsByEstado(
    String uid,
    String estado, {
    int limit = 50,
  }) {
    return db
        .collection('reports')
        .where('estado', isEqualTo: estado)
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(limit);
  }
}
