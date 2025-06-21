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
        message = 'Por favor completa ambos campos';
        isLoading = false;
      });
      return;
    }

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
      isLoading = false;
      _showTracking = true;
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Widget _buildPhoneIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.phone_android, size: 120, color: Colors.pink[100]),
        Icon(Icons.construction, size: 60, color: Colors.pink[300]),
      ],
    );
  }

  Widget _buildTimelineStep(String etapa, int index, bool isLast) {
    final etapas = ['Recibido', 'En tratamiento', 'Arreglado', 'Listo para retirar'];
    final iconos = [
      Icons.inventory,
      Icons.build,
      Icons.check_circle,
      Icons.local_shipping
    ];
    final colores = [
      Colors.pink[300]!,
      Colors.pink[400]!,
      Colors.pink[500]!,
      Colors.pink[600]!
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colores[index % colores.length],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(iconos[index % iconos.length], color: Colors.white),
              ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etapas[index % etapas.length],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[800],
                  ),
                ),
                Text(
                  etapa,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.pink[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultaForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              'Consulta tu reparación',
              style: GoogleFonts.notoSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código de reparación',
                labelStyle: TextStyle(color: Colors.pink[800]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.code, color: Colors.pink),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dniController,
              decoration: InputDecoration(
                labelText: 'DNI del cliente',
                labelStyle: TextStyle(color: Colors.pink[800]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.person, color: Colors.pink),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _consultarReparacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'CONSULTAR ESTADO',
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
              child: Text(
                'Acceso Administrador',
                style: TextStyle(
                  color: Colors.pink[600],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingInfo() {
    final historial = (reparacion?['historial'] as List?) ?? [];

    final pasosCompletos = historial.length;
    final pasosTotales = 4;
    final pasosFaltantes = pasosTotales - pasosCompletos;

    final todosPasos = [
      ...historial.map((e) => e.toString()),
      for (int i = 0; i < pasosFaltantes; i++) 'Pendiente...'
    ].take(pasosTotales).toList();

    return Column(
      children: [
        const SizedBox(height: 30),
        _buildPhoneIcon(),
        const SizedBox(height: 20),
        Text(
          '幸运龙维修跟踪', // "Seguimiento de Reparaciones Dragón de la Suerte"
          style: GoogleFonts.notoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.pink[800],
          ),
        ),
        const SizedBox(height: 30),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_android, color: Colors.pink[400]),
                    const SizedBox(width: 15),
                    Text(
                      'Modelo: ${reparacion?['modelo'] ?? 'No especificado'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.pink[400]),
                    const SizedBox(width: 15),
                    Text(
                      'Estado: ${reparacion?['estado'] ?? 'No especificado'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Progreso de tu reparación',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.pink[800],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                for (int i = 0; i < todosPasos.length; i++)
                  _buildTimelineStep(
                    todosPasos[i],
                    i,
                    i == todosPasos.length - 1,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => setState(() => _showTracking = false),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: const Text('Nueva Consulta', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'KRAKEN REPARACIONES',
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.pink[600],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink[50]!,
              Colors.pink[100]!,
            ],
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
