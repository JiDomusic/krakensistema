import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RepairTrackingScreen extends StatefulWidget {
  const RepairTrackingScreen({super.key});

  @override
  State<RepairTrackingScreen> createState() => _RepairTrackingScreenState();
}

class _RepairTrackingScreenState extends State<RepairTrackingScreen> {
  final _codigoController = TextEditingController();
  final _dniController = TextEditingController();
  Map<String, dynamic>? reparacion;
  String? error;

  Future<void> buscarReparacion() async {
    final codigo = _codigoController.text.trim();
    final dni = int.tryParse(_dniController.text.trim());

    if (codigo.isEmpty || dni == null) {
      setState(() => error = 'Ingrese un código y un DNI válidos.');
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('reparaciones').doc(codigo).get();

    if (!doc.exists) {
      setState(() => error = 'No se encontró la reparación con ese código.');
      return;
    }

    final data = doc.data()!;
    if (data['dni'] != dni) {
      setState(() => error = 'El DNI no coincide con el registro.');
      return;
    }

    setState(() {
      reparacion = data;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento de reparación')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codigoController,
              decoration: const InputDecoration(labelText: 'Código de reparación'),
            ),
            TextField(
              controller: _dniController,
              decoration: const InputDecoration(labelText: 'DNI'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: buscarReparacion,
              child: const Text('Buscar'),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            if (reparacion != null) ...[
              const SizedBox(height: 24),
              Text('Estado: ${reparacion!['estado']}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              const Text('Historial:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...List<Widget>.from(
                (reparacion!['historial'] as List).map((item) => ListTile(
                  title: Text(item['etapa'] ?? ''),
                  subtitle: Text('${item['detalle']}\n${item['fecha']}'),
                )),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
