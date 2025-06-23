import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_tracking_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_panel.dart';
import 'firebase_options.dart';

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
        primarySwatch: Colors.pink,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
          Future.microtask(() =>
              Navigator.pushReplacementNamed(context, '/admin/login'));
          return const SizedBox();
        }

        const allowedAdmins = [
          'equiz.rec@gmail.com',
          'krakenserviciotecnico@gmail.com',
          'dominguezmariajimena@gmail.com'
        ];

        if (allowedAdmins.contains(user.email?.toLowerCase())) {
          return const AdminPanel();
        } else {
          Future.microtask(() async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/admin/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}