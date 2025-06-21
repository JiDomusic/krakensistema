import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/admin_panel.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_tracking_screen.dart'; // Pantalla unificada
import 'screens/login_screen.dart';
import 'screens/admin_panel.dart' hide AdminPanel;

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
      theme: ThemeData(
        primarySwatch: Colors.pink, // Color principal cambiado a rosa
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeTrackingScreen(), // Pantalla unificada
        '/admin/login': (context) => const LoginScreen(),
        '/admin/panel': (context) => const AdminAccessGuard(),
        // Se eliminó la ruta '/tracking' (ahora está integrada)
      },
    );
  }
}

// Widget que protege el acceso a /admin/panel
class AdminAccessGuard extends StatelessWidget {
  const AdminAccessGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // No logueado: ir al login
          Future.microtask(() =>
              Navigator.pushReplacementNamed(context, '/admin/login'));
          return const SizedBox();
        }

        const allowedAdmins = [
          '',
          'equiz.rec@gmail.com',
          'krakenserviciotecnico@gmail.com',
        ];

        if (allowedAdmins.contains(user.email?.toLowerCase())) {
          // Usuario autorizado
          return const AdminPanel();
        } else {
          // Usuario no autorizado
          FirebaseAuth.instance.signOut();
          return const Scaffold(
            body: Center(
              child: Text(
                '🚫 Acceso denegado.\nSolo administradores autorizados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
        }
      },
    );
  }
}
