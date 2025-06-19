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
              return const LoginScreen();
            }

            // Verificación simple por email (reemplaza con tu email admin)
            if (user.email == 'dominguezmariajimena@gmail.com') {
              return const AdminPanel();
            }

            // Si no es el email admin, cerrar sesión
            FirebaseAuth.instance.signOut();
            return const Scaffold(
              body: Center(
                child: Text('Acceso solo para administradores autorizados'),
              ),
            );
          },
        ),
        '/tracking': (context) => const RepairTrackingScreen(), // Público
      },
    );
  }
}