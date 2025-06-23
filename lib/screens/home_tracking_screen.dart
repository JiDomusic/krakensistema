import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tu_app/services/firestore_service.dart';


class HomeTrackingScreen extends StatefulWidget {
  const HomeTrackingScreen({super.key});

  @override
  State<HomeTrackingScreen> createState() => _HomeTrackingScreenState();
}

class _HomeTrackingScreenState extends State<HomeTrackingScreen> {
  final _dniController = TextEditingController();
  final _codigoController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  Map<String, dynamic>? _reparacion;
  bool _showTracking = false;
  bool _mostrarNotificacion = false;

  @override
  void initState() {
    super.initState();
    _checkNotificaciones();
  }

  Future<void> _checkNotificaciones() async {
    // Implementar lógica para verificar notificaciones pendientes
  }

  Future<void> _consultarReparacion() async {
    setState(() {
      _isLoading = true;
      _message = null;
      _reparacion = null;
      _showTracking = false;
      _mostrarNotificacion = false;
    });

    final codigo = _codigoController.text.trim();
    final dni = _dniController.text.trim();

    if (codigo.isEmpty || dni.isEmpty) {
      setState(() {
        _message = 'Por favor completa ambos campos';
        _isLoading = false;
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
          _message = '❌ Reparación no encontrada';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      if (data['dni'] != dni) {
        setState(() {
          _message = '⚠️ DNI incorrecto para ese código';
          _isLoading = false;
        });
        return;
      }

      if (data['estado'] == 'Listo para retirar') {
        _mostrarNotificacion = true;
      }

      setState(() {
        _reparacion = data;
        _isLoading = false;
        _showTracking = true;
      });

    } catch (e) {
      setState(() {
        _message = 'Error al conectar con el servidor';
        _isLoading = false;
      });
    }
  }

  Widget _buildConsultaForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.teal[400],
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              'Consulta tu reparación',
              style: GoogleFonts.notoSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código de reparación',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.3),
                prefixIcon: const Icon(Icons.confirmation_number, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dniController,
              decoration: InputDecoration(
                labelText: 'DNI del cliente',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.3),
                prefixIcon: const Icon(Icons.person, color: Colors.white),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _consultarReparacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
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
            if (_message != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message!.startsWith('❌') || _message!.startsWith('⚠️')
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.startsWith('❌') || _message!.startsWith('⚠️')
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
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final etapas = ['Recibido', 'En revisión', 'En reparación', 'Listo para retirar'];
    final iconos = [
      Icons.inventory,
      Icons.search,
      Icons.build,
      Icons.check_circle
    ];
    final colores = [
      Colors.blue[400]!,
      Colors.orange[400]!,
      Colors.deepOrange[400]!,
      Colors.green[400]!
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
                color: colores[index],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(iconos[index], color: Colors.white, size: 24),
              ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 60,
                color: Colors.grey[300],
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
                  etapas[index],
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  etapa,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingInfo() {
    final historial = (_reparacion?['historial'] as List?) ?? [];
    final pasosCompletos = historial.length;
    final pasosTotales = 4;
    final pasosFaltantes = pasosTotales - pasosCompletos;

    final todosPasos = [
      ...historial.map((e) => e['detalle'] ?? 'Sin detalles'),
      for (int i = 0; i < pasosFaltantes; i++) 'Pendiente...'
    ].take(pasosTotales).toList();

    return Column(
      children: [
        const SizedBox(height: 20),
        _buildPhoneIcon(),
        const SizedBox(height: 20),
        Text(
          'Seguimiento de Reparación',
          style: GoogleFonts.notoSans(
            fontSize: 22,
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
                      '${_reparacion?['marca'] ?? 'Marca'} ${_reparacion?['modelo'] ?? 'Modelo'}',
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
                      'Estado: ${_reparacion?['estado'] ?? 'No especificado'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getColorEstado(_reparacion?['estado']),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Icon(Icons.confirmation_number, color: Colors.pink[400]),
                    const SizedBox(width: 15),
                    Text(
                      'Código: ${_reparacion?['codigo'] ?? 'No especificado'}',
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
            fontSize: 18,
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
            backgroundColor: Colors.teal[400],
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

  Widget _buildNotificacionEquipoListo() {
    return Card(
      elevation: 6,
      color: Colors.green[600],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 40),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡TU EQUIPO ESTÁ LISTO!',
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Puedes pasar a retirarlo en nuestro local',
                    style: GoogleFonts.notoSans(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _mostrarNotificacion = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoImage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Image.asset(
        'assets/images/logokraken.jpg',
        width: 200,
        fit: BoxFit.contain,
      ),
    );
  }

  Color _getColorEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'en revisión':
        return Colors.blue;
      case 'en reparación':
        return Colors.orange;
      case 'listo para retirar':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic fecha) {
    if (fecha is String) {
      try {
        final dateTime = DateTime.parse(fecha);
        return DateFormat('dd/MM/yyyy - HH:mm').format(dateTime);
      } catch (e) {
        return fecha;
      }
    }
    return fecha.toString();
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
              Colors.amber[50]!,
            ],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildLogoImage(),
                  if (!_showTracking) _buildConsultaForm(),
                  if (_showTracking) _buildTrackingInfo(),
                ],
              ),
            ),
            if (_mostrarNotificacion)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildNotificacionEquipoListo(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dniController.dispose();
    _codigoController.dispose();
    super.dispose();
  }
}

