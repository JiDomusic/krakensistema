// Este archivo representa el AdminPanel con funciones CRUD sobre reparaciones

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _dniController = TextEditingController();
  final _modeloController = TextEditingController();
  final _estadoController = TextEditingController();

  Future<void> agregarReparacion() async {
    if (_formKey.currentState!.validate()) {
      final codigo = _codigoController.text.trim();
      final dni = int.tryParse(_dniController.text.trim());
      final modelo = _modeloController.text.trim();
      final estado = _estadoController.text.trim();

      if (dni == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DNI inválido.')),
        );
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('reparaciones').doc(codigo);

      await docRef.set({
        'dni': dni,
        'modelo': modelo,
        'estado': estado,
        'historial': [
          {
            'etapa': 'Recibido',
            'detalle': 'Dispositivo ingresado',
            'fecha': DateTime.now().toIso8601String().split('T').first,
          },
        ],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reparación registrada.')),
      );

      _codigoController.clear();
      _dniController.clear();
      _modeloController.clear();
      _estadoController.clear();
    }
  }

  Future<void> actualizarEstado(String codigo, String nuevoEstado) async {
    await FirebaseFirestore.instance.collection('reparaciones').doc(codigo).update({
      'estado': nuevoEstado,
      'historial': FieldValue.arrayUnion([
        {
          'etapa': 'Actualización',
          'detalle': nuevoEstado,
          'fecha': DateTime.now().toIso8601String().split('T').first,
        }
      ])
    });
  }

  Future<void> eliminarReparacion(String codigo) async {
    await FirebaseFirestore.instance.collection('reparaciones').doc(codigo).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _codigoController,
                    decoration: const InputDecoration(labelText: 'Código de reparación'),
                    validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    controller: _dniController,
                    decoration: const InputDecoration(labelText: 'DNI'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    controller: _modeloController,
                    decoration: const InputDecoration(labelText: 'Modelo del equipo'),
                    validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    controller: _estadoController,
                    decoration: const InputDecoration(labelText: 'Estado actual'),
                    validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: agregarReparacion,
                    child: const Text('Agregar reparación'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const Text('Acciones rápidas'),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Código a actualizar o borrar'),
              controller: _codigoController,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nuevo estado'),
              controller: _estadoController,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => actualizarEstado(_codigoController.text, _estadoController.text),
                  child: const Text('Actualizar estado'),
                ),
                ElevatedButton(
                  onPressed: () => eliminarReparacion(_codigoController.text),
                  child: const Text('Eliminar reparación'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
