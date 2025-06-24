import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:krakensistema/screens/AdminReparacionScreen.dart';
import 'package:krakensistema/screens/home_tracking_screen.dart';
import 'package:krakensistema/screens/login_screen.dart';
import 'home_tracking_screen.dart';  // Tu pantalla Home ya creada
import 'admin_login_screen.dart';    // Pantalla login admin (tendrás que crearla)
import 'admin_reparacion_screen.dart'; // Panel admin para cargar reparaciones

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kraken Reparaciones',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeTrackingScreen(),
        '/admin/login': (context) => const LoginScreen(),
        '/admin/panel': (context) => const AdminReparacionScreen(),
      },
    );
  }
}
