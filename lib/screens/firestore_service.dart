import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> registrarReparacion({
  required String dni,
  required String cliente,
  required String telefono,
  required String descripcion,
  required String estadoInicial,
}) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance.collection('reparaciones').add({
    'dni': dni,
    'cliente': cliente,
    'telefono': telefono,
    'descripcion': descripcion,
    'estado': estadoInicial,
    'fechaIngreso': DateTime.now().toIso8601String(),
    'adminUid': uid,
  });
}
