import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      const allowedAdmins = [
        'dominguezmariajimena@gmail.com',
        'equiz.rec@gmail.com'
      ];

      if (!allowedAdmins.contains(credential.user?.email?.toLowerCase())) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          errorMessage = 'No tienes permisos de administrador';
          isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin/panel');
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = switch (e.code) {
          'invalid-email' => 'Email inválido',
          'user-disabled' => 'Usuario deshabilitado',
          'user-not-found' || 'wrong-password' =>
          'Email o contraseña incorrectos',
          'too-many-requests' => 'Demasiados intentos. Intenta más tarde',
          _ => 'Error: ${e.message}',
        };
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error inesperado: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text('Acceso Administrador'),
        backgroundColor: Colors.pink[600],
      ),
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logokraken.jpg', width: 120),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                    value == null || !value.contains('@')
                        ? 'Ingresa un email válido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (value) =>
                    value == null || value.length < 6
                        ? 'Mínimo 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[400],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Ingresar'),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
