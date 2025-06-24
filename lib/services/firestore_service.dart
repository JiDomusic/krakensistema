// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  /// Consulta todas las reparaciones con el mismo DNI.
  static Future<List<Map<String, dynamic>>> consultarPorDni(String dni) async {
    final query = await _db
        .collection('reparaciones')
        .where('dni', isEqualTo: dni)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }
}
