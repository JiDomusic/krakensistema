// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> consultarPorDni(String dni) async {
    final query = await _db
        .collection('reparaciones')
        .where('dni', isEqualTo: dni)
        .get();

    return query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }

  static Future<void> guardarDatosUsuario({
    required String uid,
    required String dni,
    required String fechaString,
  }) async {
    await _db.collection('usuarios').doc(uid).set({
      'dni': dni,
      'fechaString': fechaString,
    }, SetOptions(merge: true));
  }

  static Future<void> guardarReparacion({
    required String codigo,
    required Map<String, dynamic> datos,
  }) async {
    await _db
        .collection('reparaciones')
        .doc(codigo)
        .set(datos, SetOptions(merge: true));
  }

  static Future<void> eliminarReparacion(String codigo) async {
    await _db.collection('reparaciones').doc(codigo).delete();
  }

  static Future<Map<String, dynamic>?> obtenerReparacion(String codigo) async {
    final doc = await _db.collection('reparaciones').doc(codigo).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> consultarPorDniYFecha(
      String dni, {
        String? fechaString,
      }) async {
    Query query =
    _db.collection('reparaciones').where('dni', isEqualTo: dni);
    if (fechaString != null) {
      query = query.where('fechaString', isEqualTo: fechaString);
    }
    final querySnapshot = await query.get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }
}
