import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _dniController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _detalleEstadoController = TextEditingController();

  Map<String, dynamic>? _reparacion;
  bool _isLoading = false;
  bool _isSaving = false;

  Future<void> _agregarReparacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final codigo = _codigoController.text.trim();

      final data = {
        'codigo': codigo,
        'dni': _dniController.text.trim(),
        'marca': _marcaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'estado': 'Recibido',
        'fecha': FieldValue.serverTimestamp(),
        'historial': [],
      };

      await FirebaseFirestore.instance
          .collection('reparaciones')
          .doc(codigo)
          .set(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reparación guardada en Firestore!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        _clearInputs();
      }
    }
  }

  Future<void> _buscarReparacion() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('reparaciones')
          .doc(codigo)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Reparación no encontrada')),
          );
        }
        setState(() => _reparacion = null);
        return;
      }

      setState(() {
        _reparacion = doc.data();
        _reparacion!['id'] = doc.id;
        _dniController.text = _reparacion?['dni'] ?? '';
        _marcaController.text = _reparacion?['marca'] ?? '';
        _modeloController.text = _reparacion?['modelo'] ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _actualizarEstado(String estado) async {
    if (_reparacion == null) return;
    if (_detalleEstadoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📝 Por favor agrega un detalle')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final docId = _reparacion!['id'];
      final nuevoEvento = {
        'etapa': estado,
        'detalle': _detalleEstadoController.text.trim(),
        'fecha': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('reparaciones')
          .doc(docId)
          .update({
        'estado': estado,
        'historial': FieldValue.arrayUnion([nuevoEvento]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔥 Estado actualizado a: $estado'),
            backgroundColor: Colors.green,
          ),
        );
        _detalleEstadoController.clear();
        _buscarReparacion();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _eliminarReparacion() async {
    if (_reparacion == null) return;

    setState(() => _isSaving = true);

    try {
      final docId = _reparacion!['id'];
      await FirebaseFirestore.instance
          .collection('reparaciones')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Reparación eliminada'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _reparacion = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _editarReparacion() async {
    if (_reparacion == null) return;

    setState(() => _isSaving = true);

    try {
      final docId = _reparacion!['id'];
      await FirebaseFirestore.instance
          .collection('reparaciones')
          .doc(docId)
          .update({
        'dni': _dniController.text.trim(),
        'marca': _marcaController.text.trim(),
        'modelo': _modeloController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✏️ Datos actualizados!'),
            backgroundColor: Colors.blue,
          ),
        );
        _buscarReparacion();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clearInputs() {
    _codigoController.clear();
    _dniController.clear();
    _marcaController.clear();
    _modeloController.clear();
  }

  Widget _buildHistorial(List historial) {
    return Column(
      children: historial.reversed.map<Widget>((evento) {
        final fecha = (evento['fecha'] as Timestamp?)?.toDate();
        final fechaStr = fecha != null
            ? '${fecha.day}/${fecha.month} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'
            : 'sin fecha';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: Icon(_getEstadoIcon(evento['etapa'])),
            title: Text(
              evento['etapa'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${evento['detalle']}\n$fechaStr'),
            tileColor: _getEstadoColor(evento['etapa']).withOpacity(0.1),
          ),
        );
      }).toList(),
    );
  }

  IconData _getEstadoIcon(String? estado) {
    switch (estado) {
      case 'Recibido':
        return Icons.inventory;
      case 'En revisión':
        return Icons.build;
      case 'Listo para retirar':
        return Icons.check_circle;
      default:
        return Icons.history;
    }
  }

  Color _getEstadoColor(String? estado) {
    switch (estado) {
      case 'Recibido':
        return Colors.blue;
      case 'En revisión':
        return Colors.orange;
      case 'Listo para retirar':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final historial = _reparacion?['historial'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin - Kraken Reparaciones'),
        backgroundColor: Colors.teal[700],
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Formulario de datos
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _codigoController,
                            decoration: const InputDecoration(
                              labelText: 'Código de reparación',
                              prefixIcon: Icon(Icons.code),
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _dniController,
                            decoration: const InputDecoration(
                              labelText: 'DNI del cliente',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _marcaController,
                            decoration: const InputDecoration(
                              labelText: 'Marca',
                              prefixIcon: Icon(Icons.phone_android),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _modeloController,
                            decoration: const InputDecoration(
                              labelText: 'Modelo',
                              prefixIcon: Icon(Icons.devices),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar'),
                          onPressed: _isLoading ? null : _buscarReparacion,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                          onPressed: _isSaving ? null : _agregarReparacion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Sección de reparación encontrada
                  if (_reparacion != null) ...[
                    const SizedBox(height: 30),
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.phone_android, size: 40),
                              title: Text('${_reparacion!['marca']} ${_reparacion!['modelo']}'),
                              subtitle: Text('Código: ${_reparacion!['codigo']}'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: const Text('Cliente'),
                              subtitle: Text('DNI: ${_reparacion!['dni']}'),
                            ),
                            ListTile(
                              leading: Icon(Icons.circle, color: _getEstadoColor(_reparacion!['estado'])),
                              title: const Text('Estado actual'),
                              subtitle: Text(
                                _reparacion!['estado'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getEstadoColor(_reparacion!['estado']),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actualizar estado
                    const SizedBox(height: 20),
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text('Actualizar Estado',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _detalleEstadoController,
                              decoration: const InputDecoration(
                                labelText: 'Detalle del cambio',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildEstadoButton('Recibido', Icons.inventory, Colors.blue)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildEstadoButton('En revisión', Icons.build, Colors.orange)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildEstadoButton('Listo para retirar', Icons.check_circle, Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                            onPressed: _isSaving ? null : _editarReparacion,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('Eliminar'),
                            onPressed: _isSaving ? null : _eliminarReparacion,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Historial de Cambios',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (historial.isNotEmpty)
                      _buildHistorial(historial)
                    else
                      const Text('No hay historial registrado'),
                  ],
                ],
              ),
            ),
          ),
          if (_isLoading || _isSaving)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildEstadoButton(String texto, IconData icono, Color color) {
    return ElevatedButton.icon(
      icon: Icon(icono, color: Colors.white),
      label: Text(texto, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => _actualizarEstado(texto),
    );
  }
}
