import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'firebase_options.dart';
import 'screens/home_tracking_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_panel.dart';


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
      title: 'Kraken Reparaciones',
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeTrackingScreen(),
        '/admin/login': (context) => const LoginScreen(),
        '/admin/panel': (context) => const AdminGuard(child: AdminPanel()),

      },
    );
  }
}

class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Si no está logueado, manda al login
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/admin/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child;
  }
}
