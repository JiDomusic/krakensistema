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
  final _buscarFechaController = TextEditingController();
  final _buscarDniController = TextEditingController();

  bool isLoading = false;
  String? message;
  Map<String, dynamic>? reparacionData;
  List<Map<String, dynamic>> reparacionesPorFecha = [];
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
        final userEmail = user.email;
        
        // Verificar tanto custom claims como email hardcodeado
        final hasAdminClaim = idTokenResult.claims?['admin'] == true;
        final isAdminEmail = userEmail == "equiz.rec@gmail.com" || 
                            userEmail == "krakenserviciotecnico@gmail.com";
        
        setState(() {
          _isAdmin = hasAdminClaim || isAdminEmail;
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
    final dni = _dniController.text.trim();
    final marca = _marcaController.text.trim();
    final modelo = _modeloController.text.trim();
    final falla = _fallaController.text.trim();
    final telefono = _telefonoController.text.trim();

    if (dni.isEmpty || marca.isEmpty || modelo.isEmpty || falla.isEmpty || telefono.isEmpty) {
      setState(() => message = '⚠️ Completa todos los campos para agregar.');
      return;
    }
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('reparaciones').doc(dni).set({
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

  Future<void> _buscarTodasReparaciones() async {
    setState(() => isLoading = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('reparaciones')
          .orderBy('fecha', descending: true)
          .get();
      
      setState(() {
        reparacionesPorFecha = query.docs.map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        }).toList();
        message = reparacionesPorFecha.isEmpty 
            ? '❌ No hay reparaciones' 
            : '✅ ${reparacionesPorFecha.length} reparaciones encontradas';
        reparacionData = null;
      });
    } catch (e) {
      setState(() {
        message = '❌ Error: $e';
        reparacionesPorFecha = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _buscarPorDni() async {
    final dni = _buscarDniController.text.trim();
    if (dni.isEmpty) {
      setState(() {
        message = '⚠️ Ingresa el DNI para buscar';
        reparacionData = null;
      });
      return;
    }
    setState(() => isLoading = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('reparaciones')
          .where('dni', isEqualTo: dni)
          .get();
      
      if (query.docs.isEmpty) {
        setState(() {
          message = '❌ No se encontraron reparaciones para este DNI';
          reparacionData = null;
        });
      } else {
        final doc = query.docs.first;
        setState(() {
          reparacionData = doc.data();
          reparacionData!['id'] = doc.id;
          _dniController.text = reparacionData?['dni'] ?? '';
          _marcaController.text = reparacionData?['marca'] ?? '';
          _modeloController.text = reparacionData?['modelo'] ?? '';
          _fallaController.text = reparacionData?['falla'] ?? '';
          _telefonoController.text = reparacionData?['telefono'] ?? '';
          _fechaController.text = reparacionData?['fecha'] != null 
              ? (reparacionData!['fecha'] as Timestamp).toDate().toString()
              : '';
          message = query.docs.length > 1 
              ? '✅ Reparación encontrada (${query.docs.length} total)' 
              : '✅ Reparación encontrada';
          reparacionesPorFecha = [];
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

  void _seleccionarReparacion(Map<String, dynamic> reparacion) {
    setState(() {
      reparacionData = reparacion;
      _dniController.text = reparacion['dni'] ?? '';
      _marcaController.text = reparacion['marca'] ?? '';
      _modeloController.text = reparacion['modelo'] ?? '';
      _fallaController.text = reparacion['falla'] ?? '';
      _telefonoController.text = reparacion['telefono'] ?? '';
      _fechaController.text = reparacion['fecha'] != null 
          ? (reparacion['fecha'] as Timestamp).toDate().toString()
          : '';
      reparacionesPorFecha = [];
      message = null;
    });
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    if (reparacionData == null) return;
    final docId = reparacionData!['id'] ?? reparacionData!['codigo'];
    if (docId == null) return;

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('reparaciones')
          .doc(docId)
          .update({'estado': nuevoEstado});
      
      setState(() {
        reparacionData!['estado'] = nuevoEstado;
        message = '✅ Estado actualizado a "$nuevoEstado"';
      });
    } catch (e) {
      setState(() => message = '❌ Error al actualizar: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editarDatos() async {
    if (reparacionData == null) return;
    final dni = _dniController.text.trim();
    final marca = _marcaController.text.trim();
    final modelo = _modeloController.text.trim();
    final falla = _fallaController.text.trim();
    final telefono = _telefonoController.text.trim();
    if (dni.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('reparaciones').doc(dni).update({
        'dni': dni,
        'marca': marca,
        'modelo': modelo,
        'falla': falla,
        'telefono': telefono,
      });
      setState(() {
        reparacionData!['dni'] = dni;
        reparacionData!['marca'] = marca;
        reparacionData!['modelo'] = modelo;
        reparacionData!['falla'] = falla;
        reparacionData!['telefono'] = telefono;
      });
      setState(() => message = '✅ Datos actualizados correctamente.');
    } catch (e) {
      setState(() => message = '❌ Error al editar: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _eliminarReparacion() async {
    if (reparacionData == null) return;
    final docId = reparacionData!['id'] ?? reparacionData!['dni'];
    if (docId == null) return;

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('reparaciones').doc(docId).delete();
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

            // Búsquedas
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔍 Buscar Reparaciones',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 20),
                    
                    // Ver todas las reparaciones
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _buscarTodasReparaciones,
                      icon: const Icon(Icons.list),
                      label: const Text('Ver Todas las Reparaciones'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    
                    // Buscar por DNI
                    TextField(
                      controller: _buscarDniController,
                      decoration: InputDecoration(
                        labelText: 'Buscar por DNI',
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _buscarPorDni(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _buscarPorDni,
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar por DNI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Lista de reparaciones por fecha
            if (reparacionesPorFecha.isNotEmpty) ...[
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📋 Reparaciones encontradas (${reparacionesPorFecha.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 15),
                      ...reparacionesPorFecha.map((reparacion) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Text(
                              reparacion['dni']?.toString().substring(0, 2) ?? '??',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text('${reparacion['marca']} ${reparacion['modelo']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DNI: ${reparacion['dni']}'),
                              Text('Estado: ${reparacion['estado'] ?? 'Recibido'}'),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _seleccionarReparacion(reparacion),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

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
