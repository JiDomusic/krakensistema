import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _fechaController = TextEditingController();
  final _dniController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _fallaController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool isLoading = false;
  String? message;
  Map<String, dynamic>? reparacionData;
  bool _isAdmin = false;

  bool get isAdmin => _isAdmin;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final idTokenResult = await user.getIdTokenResult();
        setState(() {
          _isAdmin = idTokenResult.claims?['admin'] == true;
        });
        if (!_isAdmin) {
          setState(() => message = '🔒 No tienes permisos de administrador.');
        }
      } catch (e) {
        setState(() {
          _isAdmin = false;
          message = '❌ Error verificando permisos: $e';
        });
      }
    } else {
      setState(() {
        _isAdmin = false;
        message = '🔒 Debes iniciar sesión como administrador.';
      });
    }
  }

  Future<void> _agregarReparacion() async {
    if (!isAdmin) {
      setState(() => message = '🔒 Debes iniciar sesión como administrador.');
      return;
    }
    final fecha = _fechaController.text.trim();
    final dni = _dniController.text.trim();
    final marca = _marcaController.text.trim();
    final modelo = _modeloController.text.trim();
    final falla = _fallaController.text.trim();
    final telefono = _telefonoController.text.trim();

    if (fecha.isEmpty || dni.isEmpty || marca.isEmpty || modelo.isEmpty || falla.isEmpty || telefono.isEmpty) {
      setState(() => message = '⚠️ Completa todos los campos para agregar.');
      return;
    }
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('reparaciones').doc(fecha).set({
        'fecha_documento': fecha,
        'dni': dni,
        'marca': marca,
        'modelo': modelo,
        'falla': falla,
        'telefono': telefono,
        'estado': 'Recibido',
        'fecha': FieldValue.serverTimestamp(),
        'historial': [],
      });
      setState(() {
        message = '✅ Reparación agregada correctamente.';
        _fechaController.clear();
        _dniController.clear();
        _marcaController.clear();
        _modeloController.clear();
        _fallaController.clear();
        _telefonoController.clear();
      });
    } catch (e) {
      setState(() => message = '❌ Error al guardar: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _buscarReparacion() async {
    final fecha = _fechaController.text.trim();
    if (fecha.isEmpty) {
      setState(() {
        message = '⚠️ Ingresa la fecha de reparación';
        reparacionData = null;
      });
      return;
    }
    setState(() => isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('reparaciones').doc(fecha).get();
      if (!doc.exists) {
        setState(() {
          message = '❌ Reparación no encontrada';
          reparacionData = null;
        });
      } else {
        setState(() {
          reparacionData = doc.data();
          _dniController.text = reparacionData?['dni'] ?? '';
          _marcaController.text = reparacionData?['marca'] ?? '';
          _modeloController.text = reparacionData?['modelo'] ?? '';
          _fallaController.text = reparacionData?['falla'] ?? '';
          _telefonoController.text = reparacionData?['telefono'] ?? '';
          message = null;
        });
      }
    } catch (e) {
      setState(() {
        message = '❌ Error: $e';
        reparacionData = null;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    if (!isAdmin) {
      setState(() => message = '🔒 Debes iniciar sesión como administrador.');
      return;
    }
    final fecha = _fechaController.text.trim();
    if (fecha.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('reparaciones')
          .doc(fecha)
          .update({'estado': nuevoEstado});
      await _buscarReparacion();
      setState(() => message = '✅ Estado actualizado a "$nuevoEstado"');
    } catch (e) {
      setState(() => message = '❌ Error al actualizar: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editarDatos() async {
    if (!isAdmin) {
      setState(() => message = '🔒 Debes iniciar sesión como administrador.');
      return;
    }
    final fecha = _fechaController.text.trim();
    final dni = _dniController.text.trim();
    final marca = _marcaController.text.trim();
    final modelo = _modeloController.text.trim();
    final falla = _fallaController.text.trim();
    final telefono = _telefonoController.text.trim();
    if (fecha.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('reparaciones').doc(fecha).update({
        'dni': dni,
        'marca': marca,
        'modelo': modelo,
        'falla': falla,
        'telefono': telefono,
      });
      await _buscarReparacion();
      setState(() => message = '✅ Datos actualizados correctamente.');
    } catch (e) {
      setState(() => message = '❌ Error al editar: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _eliminarReparacion() async {
    if (!isAdmin) {
      setState(() => message = '🔒 Debes iniciar sesión como administrador.');
      return;
    }
    final fecha = _fechaController.text.trim();
    if (fecha.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('reparaciones').doc(fecha).delete();
      setState(() {
        message = '✅ Reparación eliminada.';
        reparacionData = null;
        _fechaController.clear();
        _dniController.clear();
        _marcaController.clear();
        _modeloController.clear();
        _fallaController.clear();
        _telefonoController.clear();
      });
    } catch (e) {
      setState(() => message = '❌ Error al eliminar: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal[800]),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildStatusButton(String estado, String estadoActual, IconData icon) {
    // Función para determinar el color basado en el estado actual
    Color getButtonColor() {
      if (estado == estadoActual) {
        // Color más oscuro cuando es el estado actual
        return {
          'Recibido': Colors.teal[700]!,
          'En revisión': Colors.blueGrey[700]!,
          'Listo para retirar': Colors.green[700]!,
        }[estado]!;
      } else {
        // Color normal cuando no es el estado actual
        return {
          'Recibido': Colors.teal[400]!,
          'En revisión': Colors.blueGrey[400]!,
          'Listo para retirar': Colors.green[400]!,
        }[estado]!;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _cambiarEstado(estado),
        style: ElevatedButton.styleFrom(
          backgroundColor: getButtonColor(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Text(estado, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoActual = reparacionData?['estado'] ?? 'Recibido'; // Estado actual con valor por defecto
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        title: const Text('Kraken • Panel Admin'),
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
            Center(child: Image.asset('assets/images/logokraken.jpg', width: 140)),
            const SizedBox(height: 30),

            // Formulario Agregar
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('➕ Agregar Nueva Reparación',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    TextField(controller: _fechaController, decoration: const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)')),
                    const SizedBox(height: 12),
                    TextField(controller: _dniController, decoration: const InputDecoration(labelText: 'DNI'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: _marcaController, decoration: const InputDecoration(labelText: 'Marca')),
                    const SizedBox(height: 12),
                    TextField(controller: _modeloController, decoration: const InputDecoration(labelText: 'Modelo')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fallaController,
                      decoration: const InputDecoration(labelText: 'Falla'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Reparación'),
                      onPressed: isLoading ? null : _agregarReparacion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size.fromHeight(55),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Buscar Reparación
            TextField(
              controller: _fechaController,
              decoration: InputDecoration(
                labelText: '🔍 Fecha de reparación (YYYY-MM-DD)',
                prefixIcon: const Icon(Icons.calendar_today),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _buscarReparacion(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _buscarReparacion,
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            ),

            const SizedBox(height: 30),

            if (reparacionData != null) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoTile(Icons.phone_android, 'Teléfono', reparacionData!['telefono'] ?? '—'),
                      const SizedBox(height: 12),
                      _buildInfoTile(Icons.devices_other, 'Marca', reparacionData!['marca'] ?? '—'),
                      const SizedBox(height: 12),
                      _buildInfoTile(Icons.phone_android, 'Modelo', reparacionData!['modelo'] ?? '—'),
                      const SizedBox(height: 12),
                      _buildInfoTile(Icons.description, 'Falla', reparacionData!['falla'] ?? '—'),
                      const SizedBox(height: 12),
                      _buildInfoTile(Icons.info_outline, 'Estado actual', estadoActual),
                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isLoading ? null : _editarDatos,
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                          ),
                          ElevatedButton.icon(
                            onPressed: isLoading ? null : _eliminarReparacion,
                            icon: const Icon(Icons.delete),
                            label: const Text('Eliminar'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          ),
                        ],
                      ),

                      const Divider(height: 30),

                      // Botones de estado que cambian de color
                      Column(
                        children: [
                          _buildStatusButton('Recibido', estadoActual, Icons.inbox),
                          _buildStatusButton('En revisión', estadoActual, Icons.search),
                          _buildStatusButton('Listo para retirar', estadoActual, Icons.done_all),
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
                  color: message!.startsWith('❌') ? Colors.red : Colors.green[800],
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