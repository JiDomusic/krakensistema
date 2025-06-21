import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUpdateScreen extends StatefulWidget {
  const AdminUpdateScreen({super.key});

  @override
  State<AdminUpdateScreen> createState() => _AdminUpdateScreenState();
}

class _AdminUpdateScreenState extends State<AdminUpdateScreen> {
  final _codigoController = TextEditingController();
  final _mensajeController = TextEditingController();
  String? _selectedEstado;
  bool isLoading = false;

  final List<String> estados = [
    'Recibido',
    'En tratamiento',
    'Arreglado',
    'Listo para retirar',
  ];

  Future<void> _actualizarEstado() async {
    final codigo = _codigoController.text.trim();
    final mensaje = _mensajeController.text.trim();

    if (codigo.isEmpty || _selectedEstado == null || mensaje.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Completa todos los campos')),
      );
      return;
    }

    setState(() => isLoading = true);

    final docRef = FirebaseFirestore.instance.collection('reparaciones').doc(codigo);
    final doc = await docRef.get();

    if (!doc.exists) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Reparación no encontrada')),
      );
      return;
    }

    final historial = List<String>.from(doc['historial'] ?? []);
    historial.add(mensaje);

    await docRef.update({
      'estado': _selectedEstado,
      'historial': historial,
    });

    setState(() {
      isLoading = false;
      _codigoController.clear();
      _mensajeController.clear();
      _selectedEstado = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Reparación actualizada con éxito')),
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        backgroundColor: Colors.pink[600],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código de reparación',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedEstado,
              decoration: InputDecoration(
                labelText: 'Nuevo estado',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.edit),
              ),
              items: estados
                  .map((estado) => DropdownMenuItem(
                value: estado,
                child: Text(estado),
              ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedEstado = value),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _mensajeController,
              decoration: InputDecoration(
                labelText: 'Mensaje para el cliente',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.message),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _actualizarEstado,
                icon: const Icon(Icons.save),
                label: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar actualización'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
