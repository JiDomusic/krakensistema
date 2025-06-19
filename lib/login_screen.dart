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

      // Autenticar con Firebase
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verificar email autorizado (reemplaza con tu email admin)
      if (credential.user?.email?.toLowerCase() != 'dominguezmariajimena@gmail.com') {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          errorMessage = 'No tienes permisos de administrador';
          isLoading = false;
        });
        return;
      }

      // Navegar al panel admin
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/admin/panel');
    } on FirebaseAuthException catch (e) {
      String errorText;
      switch (e.code) {
        case 'invalid-email':
          errorText = 'Email inválido';
          break;
        case 'user-disabled':
          errorText = 'Usuario deshabilitado';
          break;
        case 'user-not-found':
        case 'wrong-password':
          errorText = 'Email o contraseña incorrectos';
          break;
        case 'too-many-requests':
          errorText = 'Demasiados intentos. Intenta más tarde';
          break;
        default:
          errorText = 'Error al iniciar sesión: ${e.message}';
      }

      setState(() {
        errorMessage = errorText;
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
      appBar: AppBar(title: const Text('Acceso Admin')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu email';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  if (value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
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
    );
  }
}