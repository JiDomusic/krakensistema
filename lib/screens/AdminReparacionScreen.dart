import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminReparacionScreen extends StatefulWidget {
  const AdminReparacionScreen({super.key});

  @override
  State<AdminReparacionScreen> createState() => _AdminReparacionScreenState();
}

class _AdminReparacionScreenState extends State<AdminReparacionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dniController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _codigoController = TextEditingController();

  String _estado = 'Recibido';

  bool _isLoading = false;
  String? _message;

  Future<void> _guardarReparacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final reparacionData = {
      'dni': _dniController.text.trim(),
      'marca': _marcaController.text.trim(),
      'modelo': _modeloController.text.trim(),
      'codigo': _codigoController.text.trim(),
      'estado': _estado,
      'historial': [
        {'detalle': 'Reparación registrada', 'fecha': DateTime.now().toIso8601String()}
      ],
    };

    try {
      await FirebaseFirestore.instance.collection('reparaciones').add(reparacionData);
      setState(() {
        _message = '✅ Reparación agregada correctamente';
        _isLoading = false;
      });
      _formKey.currentState!.reset();
      _estado = 'Recibido';
    } catch (e) {
      setState(() {
        _message = 'Error al guardar: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin - Nueva Reparación'),
        backgroundColor: Colors.teal[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _dniController,
                  decoration: const InputDecoration(
                    labelText: 'DNI',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Ingrese DNI' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _marcaController,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Ingrese marca' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _modeloController,
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Ingrese modelo' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código de reparación',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Ingrese código' : null,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Recibido',
                    'En revisión',
                    'En reparación',
                    'Listo para retirar',
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _estado = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _guardarReparacion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'GUARDAR REPARACIÓN',
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.startsWith('✅') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
