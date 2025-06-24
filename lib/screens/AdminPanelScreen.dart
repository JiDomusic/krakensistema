import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _dniController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  Map<String, dynamic>? _reparacion;

  final List<String> estados = [
    'En revisión',
    'En reparación',
    'Listo para retirar',
  ];

  Future<void> _buscarReparacion() async {
    final dni = _dniController.text.trim();
    if (dni.isEmpty) {
      setState(() {
        _message = 'Por favor ingresa un DNI';
        _reparacion = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _reparacion = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reparaciones')
          .where('dni', isEqualTo: dni)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _message = 'No se encontró ninguna reparación para ese DNI';
          _isLoading = false;
        });
        return;
      }

      final doc = querySnapshot.docs.first;
      setState(() {
        _reparacion = doc.data();
        _reparacion!['docId'] = doc.id;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error al consultar: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarEstado(String nuevoEstado) async {
    if (_reparacion == null || _reparacion!['docId'] == null) return;

    final docId = _reparacion!['docId'];

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await FirebaseFirestore.instance.collection('reparaciones').doc(docId).update({
        'estado': nuevoEstado,
        'historial': FieldValue.arrayUnion([
          {
            'etapa': nuevoEstado,
            'detalle': 'Estado actualizado por Admin',
            'fecha': DateTime.now().toIso8601String(),
          }
        ])
      });

      final doc = await FirebaseFirestore.instance.collection('reparaciones').doc(docId).get();
      setState(() {
        _reparacion = doc.data()!..['docId'] = doc.id;
        _message = '✅ Estado actualizado a "$nuevoEstado"';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error al actualizar: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Admin', style: GoogleFonts.notoSans()),
        backgroundColor: Colors.teal[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _dniController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'DNI del cliente',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _buscarReparacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Buscar Reparación', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _message!.startsWith('✅') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (_reparacion != null) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código: ${_reparacion!['codigo'] ?? 'N/A'}', style: GoogleFonts.notoSans(fontSize: 16)),
                      Text('Marca: ${_reparacion!['marca'] ?? 'N/A'}', style: GoogleFonts.notoSans(fontSize: 16)),
                      Text('Modelo: ${_reparacion!['modelo'] ?? 'N/A'}', style: GoogleFonts.notoSans(fontSize: 16)),
                      Text('Estado actual: ${_reparacion!['estado'] ?? 'N/A'}', style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Actualizar Estado:', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: estados.map((estado) {
                  return ElevatedButton(
                    onPressed: _isLoading ? null : () => _actualizarEstado(estado),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[400],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      estado,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
