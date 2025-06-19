import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RepairTrackingScreen extends StatefulWidget {
  const RepairTrackingScreen({super.key});

  @override
  State<RepairTrackingScreen> createState() => _RepairTrackingScreenState();
}

class _RepairTrackingScreenState extends State<RepairTrackingScreen> {
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  Map<String, dynamic>? repairData;
  String? errorMessage;

  void fetchRepairData() async {
    setState(() {
      repairData = null;
      errorMessage = null;
    });

    final dni = int.tryParse(_dniController.text.trim());
    final code = _codeController.text.trim();

    if (dni == null || code.isEmpty) {
      setState(() => errorMessage = 'Por favor ingresa un DNI válido y un código.');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('reparaciones').doc(code).get();
      if (!doc.exists) {
        setState(() => errorMessage = 'No se encontró ninguna reparación con ese código.');
        return;
      }

      final data = doc.data()!;
      if (data['dni'] != dni) {
        setState(() => errorMessage = 'El DNI no coincide con el código ingresado.');
        return;
      }

      setState(() => repairData = data);
    } catch (e) {
      setState(() => errorMessage = 'Error al buscar la reparación.');
    }
  }

  Widget buildStatusMap() {
    final historial = repairData?['historial'] as List<dynamic>?;
    if (historial == null || historial.isEmpty) return const Text('Sin historial disponible.');

    return Column(
      children: historial.asMap().entries.map((entry) {
        final etapa = entry.value['etapa'] ?? 'Etapa desconocida';
        final detalle = entry.value['detalle'] ?? '';
        final fecha = entry.value['fecha'] ?? '';
        final color = entry.key % 2 == 0 ? Colors.blue : Colors.redAccent;

        return Card(
          color: color.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Icon(Icons.construction, color: color),
            title: Text(etapa, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            subtitle: Text('$detalle\nFecha: $fecha'),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento de Reparación')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Consulta el estado de tu equipo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _dniController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'DNI'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Código de reparación'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchRepairData,
              child: const Text('Consultar'),
            ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.pink)),
            if (repairData != null) Expanded(child: buildStatusMap()),
          ],
        ),
      ),
    );
  }
}