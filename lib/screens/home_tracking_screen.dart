import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _reparacion;
  bool _isLoading = false;

  Future<void> _buscarReparacion() async {
    setState(() {
      _isLoading = true;
      _reparacion = null;
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('reparaciones')
        .doc(_searchController.text.trim())
        .get();

    if (snapshot.exists) {
      setState(() => _reparacion = snapshot.data()!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reparación no encontrada')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _actualizarEstado(String nuevoEstado) async {
    if (_reparacion == null) return;

    final nuevoEvento = {
      "etapa": nuevoEstado,
      "detalle": "Actualizado por administrador",
      "fecha": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('reparaciones')
        .doc(_searchController.text.trim())
        .update({
      "estado": nuevoEstado,
      "historial": FieldValue.arrayUnion([nuevoEvento]),
    });

    setState(() {
      _reparacion!['estado'] = nuevoEstado;
      _reparacion!['historial'].add(nuevoEvento);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Estado actualizado a: $nuevoEstado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin - Gestión Rápida'),
        backgroundColor: Colors.pink[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
// Buscador
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Código de reparación',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _buscarReparacion,
                ),
              ),
            ),
            const SizedBox(height: 20),

// Tarjeta de información
            if (_reparacion != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Modelo: ${_reparacion!['modelo']}'),
                      Text('DNI: ${_reparacion!['dni']}'),
                      Text('Estado actual: ${_reparacion!['estado']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

// Botones de acción rápida
              const Text('Actualizar estado:',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildEstadoButton('Recibido', Colors.blue),
                  _buildEstadoButton('En reparación', Colors.orange),
                  _buildEstadoButton('Listo para retirar', Colors.green),
                ],
              ),
              const SizedBox(height: 30),

// Historial simplificado
              const Text('Última actualización:',
                  style: TextStyle(fontSize: 16)),
              if (_reparacion!['historial'].isNotEmpty)
                ..._reparacion!['historial'].reversed.take(3).map((evento) =>
                    ListTile(
                      leading: _getEstadoIcon(evento['etapa']),
                      title: Text(evento['etapa']),
                      subtitle: Text('${evento['detalle']}\n${evento['fecha'].toDate().toString()}'),
                    ),
                ).toList(),
            ],
            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoButton(String estado, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _actualizarEstado(estado),
      child: Text(estado),
    );
  }

  Widget _getEstadoIcon(String etapa) {
    switch (etapa.toLowerCase()) {
      case 'recibido':
        return const Icon(Icons.inventory, color: Colors.blue);
      case 'en reparación':
        return const Icon(Icons.build, color: Colors.orange);
      case 'listo para retirar':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.info);
    }
  }
}