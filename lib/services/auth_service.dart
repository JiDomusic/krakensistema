// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

final List<String> allowedEmails = [
  'equiz.rec@gmail.com',
  'krakenserviciotecnico@gmail.com',
];

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (!allowedEmails.contains(user?.email)) {
        await _auth.signOut(); // cierra sesión si el correo no está autorizado
        throw FirebaseAuthException(
          code: 'unauthorized',
          message: 'Correo no autorizado para acceder como administrador',
        );
      }

      print('✔️ Bienvenido administrador: ${user!.email}');
      return user;

    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
