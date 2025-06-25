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
      title: 'KRAKEN Reparaciones',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'NotoSans',
          bodyColor: Colors.teal[900],
          displayColor: Colors.teal[900],
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeTrackingScreen(),
        '/admin/login': (context) => const LoginScreen(),
        '/admin/panel': (context) => const AdminAccessGuard(),
      },
    );
  }
}

/// Protege el acceso al panel del admin
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
          Future.microtask(() {
            Navigator.pushReplacementNamed(context, '/admin/login');
          });
          return const SizedBox.shrink();
        }

        const allowedAdmins = [
          'dominguezmariajimena@gmail.com',
          'equiz.rec@gmail.com',
        ];

        if (allowedAdmins.contains(user.email?.toLowerCase())) {
          return const AdminPanel();
        } else {
          FirebaseAuth.instance.signOut();
          return const Scaffold(
            body: Center(
              child: Text(
                '🚫 Acceso denegado.\nSolo administradores autorizados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
