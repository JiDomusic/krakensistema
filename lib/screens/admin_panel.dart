import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _codigoController = TextEditingController();
  final _dniController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();

  bool isLoading = false;
  String? message;
  Map<String, dynamic>? reparacionData;

  Future<void> _agregarReparacion() async {
    final codigo = _codigoController.text.trim();
    final dni = _dniController.text.trim();
    final marca = _marcaController.text.trim();
    final modelo = _modeloController.text.trim();

    if (codigo.isEmpty || dni.isEmpty || marca.isEmpty || modelo.isEmpty) {
      setState(() => message = '⚠️ Completa todos los campos para agregar.');
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      await FirebaseFirestore.instance.collection('reparaciones').doc(codigo).set({
        'codigo': codigo,
        'dni': dni,
        'marca': marca,
        'modelo': modelo,
        'estado': 'Recibido',
        'fecha': FieldValue.serverTimestamp(),
        'historial': [],
      });

      setState(() {
        message = '✅ Reparación agregada correctamente.';
        _codigoController.clear();
        _dniController.clear();
        _marcaController.clear();
        _modeloController.clear();
      });
    } catch (e) {
      setState(() {
        message = '❌ Error al guardar: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _buscarReparacion() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      setState(() {
        message = '⚠️ Ingresa el código de reparación';
        reparacionData = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('reparaciones').doc(codigo).get();
      if (!doc.exists) {
        setState(() {
          message = '❌ Reparación no encontrada';
          reparacionData = null;
        });
      } else {
        setState(() {
          reparacionData = doc.data();
          message = null;
        });
      }
    } catch (e) {
      setState(() {
        message = '❌ Error: $e';
        reparacionData = null;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) return;

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('reparaciones').doc(codigo);
      await docRef.update({'estado': nuevoEstado});
      _buscarReparacion(); // actualizar vista
      setState(() {
        message = '✅ Estado actualizado a "$nuevoEstado"';
      });
    } catch (e) {
      setState(() {
        message = '❌ Error al actualizar: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal[900]),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildTrackingStep(String label, bool isActive) {
    return Row(
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isActive ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoActual = reparacionData?['estado'];

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        backgroundColor: Colors.teal[700],
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Image.asset('assets/images/logokraken.jpg', width: 120),
            ),
            const SizedBox(height: 30),

            // FORMULARIO NUEVA REPARACIÓN
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Agregar Nueva Reparación', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _codigoController,
                      decoration: const InputDecoration(labelText: 'Código'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _dniController,
                      decoration: const InputDecoration(labelText: 'DNI'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _marcaController,
                      decoration: const InputDecoration(labelText: 'Marca'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _modeloController,
                      decoration: const InputDecoration(labelText: 'Modelo'),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Reparación'),
                      onPressed: isLoading ? null : _agregarReparacion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        minimumSize: const Size.fromHeight(45),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // CONSULTAR REPARACIÓN
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código de reparación',
                prefixIcon: const Icon(Icons.qr_code),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _buscarReparacion(),
            ),

            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _buscarReparacion,
              icon: const Icon(Icons.search),
              label: const Text('Buscar reparación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            const SizedBox(height: 20),

            if (reparacionData != null) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withOpacity(0.95),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoTile(Icons.precision_manufacturing, 'Marca', reparacionData!['marca'] ?? '—'),
                      const SizedBox(height: 10),
                      _buildInfoTile(Icons.phone_android, 'Modelo', reparacionData!['modelo'] ?? '—'),
                      const SizedBox(height: 10),
                      _buildInfoTile(Icons.info_outline, 'Estado actual', estadoActual ?? '—'),
                      const SizedBox(height: 20),
                      const Divider(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTrackingStep('Recibido', estadoActual == 'Recibido' || estadoActual == 'En revisión' || estadoActual == 'Listo para retirar'),
                          const SizedBox(height: 8),
                          _buildTrackingStep('En revisión', estadoActual == 'En revisión' || estadoActual == 'Listo para retirar'),
                          const SizedBox(height: 8),
                          _buildTrackingStep('Listo para retirar', estadoActual == 'Listo para retirar'),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton(
                            onPressed: isLoading ? null : () => _cambiarEstado('Recibido'),
                            child: const Text('Recibido'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                          ),
                          ElevatedButton(
                            onPressed: isLoading ? null : () => _cambiarEstado('En revisión'),
                            child: const Text('En revisión'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                          ),
                          ElevatedButton(
                            onPressed: isLoading ? null : () => _cambiarEstado('Listo para retirar'),
                            child: const Text('Listo para retirar'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (message != null) ...[
              const SizedBox(height: 20),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: message!.startsWith('❌') ? Colors.red : Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}