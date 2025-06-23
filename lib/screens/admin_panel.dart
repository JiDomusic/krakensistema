import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _searchController = TextEditingController();
  final _detalleController = TextEditingController();
  Map<String, dynamic>? _reparacion;
  bool _isLoading = false;
  String _estadoSeleccionado = 'En revisión';

  final List<String> _estados = [
    'En revisión',
    'En reparación',
    'Esperando repuesto',
    'Listo para retirar',
    'Entregado'
  ];

  Future<void> _buscarReparacion() async {
    setState(() {
      _isLoading = true;
      _reparacion = null;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('reparaciones')
          .where('codigo', isEqualTo: _searchController.text.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() => _reparacion = query.docs.first.data());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reparación no encontrada')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _actualizarEstado() async {
    if (_reparacion == null || _detalleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un detalle antes de actualizar')),
      );
      return;
    }

    final nuevoEvento = {
      'etapa': _estadoSeleccionado,
      'detalle': _detalleController.text,
      'fecha': DateTime.now().toIso8601String(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('reparaciones')
          .doc(_reparacion!['codigo'])
          .update({
        'estado': _estadoSeleccionado,
        'historial': FieldValue.arrayUnion([nuevoEvento]),
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      });

      setState(() {
        _reparacion!['estado'] = _estadoSeleccionado;
        _detalleController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Estado actualizado a: $_estadoSeleccionado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Panel Administrativo',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por código de reparación',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _buscarReparacion,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_reparacion != null) ...[
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Text('Cliente: ${_reparacion!['nombre'] ?? 'No especificado'}',
                          style: const TextStyle(fontSize: 18)),
                      Text('DNI: ${_reparacion!['dni']}'),
                      Text('Teléfono: ${_reparacion!['telefono'] ?? 'No especificado'}'),
                      const SizedBox(height: 10),
                      Text('Equipo: ${_reparacion!['marca']} ${_reparacion!['modelo']}'),
                      Text('Problema: ${_reparacion!['problema']}'),
                      const SizedBox(height: 10),
                      Text('Estado actual: ${_reparacion!['estado']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getColorEstado(_reparacion!['estado']),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                items: _estados.map((estado) {
                  return DropdownMenuItem(
                    value: estado,
                    child: Text(estado),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _estadoSeleccionado = value!),
                decoration: const InputDecoration(labelText: 'Nuevo estado'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _detalleController,
                decoration: const InputDecoration(
                  labelText: 'Detalles del estado',
                  hintText: 'Ej: "Se reemplazó la pantalla"',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _actualizarEstado,
                child: const Text('Actualizar Estado'),
              ),
            ],
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'En revisión':
        return Colors.blue;
      case 'En reparación':
        return Colors.orange;
      case 'Esperando repuesto':
        return Colors.purple;
      case 'Listo para retirar':
        return Colors.green;
      case 'Entregado':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}