import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeTrackingScreen extends StatefulWidget {
  const HomeTrackingScreen({super.key});

  @override
  State<HomeTrackingScreen> createState() => _HomeTrackingScreenState();
}

class _HomeTrackingScreenState extends State<HomeTrackingScreen> {
  final _dniController = TextEditingController();
  final _codigoController = TextEditingController();
  bool isLoading = false;
  String? message;
  Map<String, dynamic>? reparacion;
  bool _showTracking = false;

  Future<void> _consultarReparacion() async {
    setState(() {
      message = null;
      reparacion = null;
      isLoading = true;
      _showTracking = false;
    });

    final codigo = _codigoController.text.trim();
    final dni = _dniController.text.trim();

    if (codigo.isEmpty || dni.isEmpty) {
      setState(() {
        message = '⚠️ Por favor completa ambos campos';
        isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('reparaciones')
          .doc(codigo)
          .get();

      if (!doc.exists) {
        setState(() {
          message = '❌ Reparación no encontrada';
          isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      if (data['dni'] != dni) {
        setState(() {
          message = '⚠️ DNI incorrecto para ese código';
          isLoading = false;
        });
        return;
      }

      setState(() {
        reparacion = data;
        _showTracking = true;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        message = '❌ Error al consultar: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Widget _buildLogoImage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Image.asset(
        'assets/images/logokraken.jpg',
        width: 180,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildConsultaForm() {
    return Card(
      color: Colors.teal[100],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '🔎 Consulta tu reparación',
              style: GoogleFonts.notoSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código de reparación',
                prefixIcon: const Icon(Icons.qr_code),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dniController,
              decoration: InputDecoration(
                labelText: 'DNI del cliente',
                prefixIcon: const Icon(Icons.perm_identity),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _consultarReparacion,
                icon: const Icon(Icons.search),
                label: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CONSULTAR ESTADO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message!.startsWith('❌') || message!.startsWith('⚠️')
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message!,
                  style: TextStyle(
                    color: message!.startsWith('❌') || message!.startsWith('⚠️')
                        ? Colors.red[800]
                        : Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/admin/login'),
              child: const Text(
                'Acceso Administrador',
                style: TextStyle(
                  color: Colors.teal,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String texto, int index, bool isLast) {
    final iconos = [
      Icons.inventory,
      Icons.build,
      Icons.settings,
      Icons.check_circle,
    ];
    final colores = [
      Colors.pink[300],
      Colors.pink[400],
      Colors.pink[500],
      Colors.pink[600],
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: colores[index % colores.length],
              child: Icon(iconos[index % iconos.length], color: Colors.white),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 60,
                color: Colors.pink[200],
              ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              texto,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingInfo() {
    final historial = (reparacion?['historial'] as List?) ?? [];

    return Column(
      children: [
        const SizedBox(height: 30),
        _buildLogoImage(),
        const SizedBox(height: 10),
        Text(
          'Seguimiento de reparación',
          style: GoogleFonts.notoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.pink[800],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_android, color: Colors.pink),
                    const SizedBox(width: 8),
                    Text('Modelo: ${reparacion?['modelo'] ?? 'Sin especificar'}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.pink),
                    const SizedBox(width: 8),
                    Text('Estado: ${reparacion?['estado'] ?? 'Sin especificar'}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '📈 Historial de reparaciones',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: historial.isEmpty
                  ? [const Text('Sin historial aún.')]
                  : historial.asMap().entries.map((entry) {
                final index = entry.key;
                final evento = entry.value;
                final detalle = evento['detalle'] ?? '';
                final etapa = evento['etapa'] ?? '';
                final fecha = (evento['fecha'] as Timestamp?)?.toDate();
                final fechaStr = fecha != null
                    ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'
                    : 'Sin fecha';

                return _buildTimelineStep(
                  '$etapa\n📝 $detalle\n⏱️ $fechaStr',
                  index,
                  index == historial.length - 1,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () => setState(() => _showTracking = false),
          icon: const Icon(Icons.refresh),
          label: const Text('Nueva Consulta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[600],
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KRAKEN REPARACIONES'),
        backgroundColor: Colors.teal[700],
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[50]!, Colors.pink[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (!_showTracking) _buildConsultaForm(),
              if (_showTracking) _buildTrackingInfo(),
            ],
          ),
        ),
      ),
    );
  }
}
