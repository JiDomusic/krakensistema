import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'admin_panel.dart';
import 'repair_tracking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KRAKEN Sistema',
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(), // Público
        '/admin/login': (context) => const LoginScreen(),
        '/admin/panel': (context) => StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = snapshot.data;
            if (user == null) {
              return const LoginScreen(); // Redirige a login si no está autenticado
            }

            // Verificar si es admin
            return FutureBuilder<bool>(
              future: _esAdmin(user),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (adminSnapshot.data == true) {
                  return const AdminPanel();
                }

                // Si no es admin, cerrar sesión y mostrar mensaje
                FirebaseAuth.instance.signOut();
                return const Scaffold(
                  body: Center(
                    child: Text('Acceso solo para administradores'),
                  ),
                );
              },
            );
          },
        ),
        '/tracking': (context) => const RepairTrackingScreen(), // Público
      },
    );
  }

  Future<bool> _esAdmin(User user) async {
    final token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }
}