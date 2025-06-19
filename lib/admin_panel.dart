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
  final _historialController = TextEditingController();

  bool isLoading = false;
  String? message;
  Map<String, dynamic>? reparacionActual;

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
        _clearFields();
      });
    } on FirebaseException catch (e) {
      setState(() {
        message = '⚠️ Error: ${e.message}';
        isLoading = false;
      });
    }
  }

  Future<void> _buscarReparacion() async {
    setState(() {
      reparacionActual = null;
      message = null;
      isLoading = true;
    });

    final codigo = _codigoController.text.trim();

    if (codigo.isEmpty) {
      setState(() {
        message = 'Ingresa el código a buscar';
        isLoading = false;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('reparaciones')
        .doc(codigo)
        .get();

    if (doc.exists) {
      setState(() {
        reparacionActual = doc.data();
        _modeloController.text = reparacionActual?['modelo'] ?? '';
        _dniController.text = reparacionActual?['dni'] ?? '';
        _estadoController.text = reparacionActual?['estado'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() {
        message = '❌ Reparación no encontrada';
        isLoading = false;
      });
    }
  }

  Future<void> _agregarHistorial() async {
    final nota = _historialController.text.trim();
    if (nota.isEmpty) return;

    final codigo = _codigoController.text.trim();
    final docRef =
    FirebaseFirestore.instance.collection('reparaciones').doc(codigo);

    await docRef.update({
      'historial': FieldValue.arrayUnion([nota]),
    });

    _historialController.clear();
    await _buscarReparacion(); // recarga los datos
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/admin/login');
  }

  void _clearFields() {
    _codigoController.clear();
    _modeloController.clear();
    _dniController.clear();
    _estadoController.clear();
    _historialController.clear();
    reparacionActual = null;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _modeloController.dispose();
    _dniController.dispose();
    _estadoController.dispose();
    _historialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historial = reparacionActual?['historial'] ?? [];

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
                'Gestión de Reparaciones',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código de reparación'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _buscarReparacion,
                      child: const Text('Buscar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _guardarReparacion,
                      child: const Text('Guardar nueva'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: 'Modelo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dniController,
                decoration: const InputDecoration(labelText: 'DNI del cliente'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _estadoController,
                decoration: const InputDecoration(labelText: 'Estado actual'),
              ),
              const SizedBox(height: 16),
              if (reparacionActual != null) ...[
                const Divider(height: 32),
                const Text(
                  'Historial',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                for (var nota in historial)
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(nota),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _historialController,
                  decoration: const InputDecoration(labelText: 'Agregar al historial'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isLoading ? null : _agregarHistorial,
                  child: const Text('Agregar'),
                ),
              ],
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
}
