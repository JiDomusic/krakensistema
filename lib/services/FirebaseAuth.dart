import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Función principal: login solo si es admin
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      if (result.user != null) {
        bool isAdmin = await _isAdmin(result.user!);
        if (isAdmin) {
          if (kDebugMode) {
            print("✅ Acceso autorizado: el usuario es administrador.");
          }
          return result;
        } else {
          if (kDebugMode) {
            print("⛔ El usuario NO tiene permisos de administrador.");
          }
          await _auth.signOut(); // Cierra sesión si no es admin
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print("❌ Error al iniciar sesión: $e");
      return null;
    }
  }

  // Verifica si el UID está en la colección 'admins' con admins == true
  Future<bool> _isAdmin(User user) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (snapshot.exists && snapshot.get('admins') == true) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("❌ Error al verificar administrador: $e");
      return false;
    }
  }

  // Cerrar sesión manualmente
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;
}
