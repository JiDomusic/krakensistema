import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _codigoController = TextEditingController();
  final _modeloController = TextEditingController();
  final _dniController = TextEditingController();
  final _estadoController = TextEditingController();

  bool isLoading = false;
  String? message;

  Future<void> _guardarReparacion() async {
    setState(() {
      message = null;
      isLoading = true;
    });

    try {
      final codigo = _codigoController.text.trim();

      if (codigo.isEmpty ||
          _modeloController.text.trim().isEmpty ||
          _dniController.text.trim().isEmpty ||
          _estadoController.text.trim().isEmpty) {
        setState(() {
          message = 'Completa todos los campos';
          isLoading = false;
        });
        return;
      }

      final docRef =
      FirebaseFirestore.instance.collection('reparaciones').doc(codigo);

      await docRef.set({
        'modelo': _modeloController.text.trim(),
        'dni': _dniController.text.trim(),
        'estado': _estadoController.text.trim(),
        'historial': [],
      });

      setState(() {
        message = '✅ Reparación guardada exitosamente';
        isLoading = false;
        _codigoController.clear();
        _modeloController.clear();
        _dniController.clear();
        _estadoController.clear();
      });
    } on FirebaseException catch (e) {
      setState(() {
        message = '⚠️ Error: ${e.message}';
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/admin/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Registrar nueva reparación',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: 'Modelo'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dniController,
                decoration: const InputDecoration(labelText: 'DNI del cliente'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _estadoController,
                decoration: const InputDecoration(labelText: 'Estado inicial'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _guardarReparacion,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar reparación'),
              ),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  style: TextStyle(
                    color: message!.startsWith('✅') ? Colors.green : Colors.red,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _modeloController.dispose();
    _dniController.dispose();
    _estadoController.dispose();
    super.dispose();
  }
}
