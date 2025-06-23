import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tu_app/services/firestore_service.dart'; // 👈 Personalizá este import

class SeguimientoReparaciones extends StatefulWidget {
  const SeguimientoReparaciones({super.key});

  @override
  State<SeguimientoReparaciones> createState() => _SeguimientoReparacionesState();
}

class _SeguimientoReparacionesState extends State<SeguimientoReparaciones> {
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
    // Opcional: lógica para notificaciones locales o persistentes
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
      final reparaciones = await FirestoreService.consultarPorDni(dni);
      final reparacion = reparaciones.firstWhere(
            (r) => r['id'] == codigo,
        orElse: () => {},
      );

      if (reparacion.isEmpty) {
        setState(() {
          _message = '❌ Reparación no encontrada';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _reparacion = reparacion;
        _isLoading = false;
        _showTracking = true;
        _mostrarNotificacion = reparacion['estado'] == 'Listo para retirar';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.teal[400],
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              'Consulta tu reparación',
              style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código de reparación',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.3),
                prefixIcon: const Icon(Icons.confirmation_number, color: Colors.white),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dniController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'DNI del cliente',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.3),
                prefixIcon: const Icon(Icons.person, color: Colors.white),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _consultarReparacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('CONSULTAR ESTADO',
                    style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message!.startsWith('❌') || _message!.startsWith('⚠️') ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                      color: _message!.startsWith('❌') || _message!.startsWith('⚠️') ? Colors.red[800] : Colors.green[800]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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

  Widget _buildTimelineStep(String paso, int index, bool isLast) {
    final iconos = [Icons.inventory, Icons.search, Icons.build, Icons.check_circle];
    final colores = [Colors.blue[400]!, Colors.orange[400]!, Colors.deepOrange[400]!, Colors.green[400]!];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: colores[index], shape: BoxShape.circle),
              child: Center(child: Icon(iconos[index], color: Colors.white, size: 24)),
            ),
            if (!isLast) Container(width: 3, height: 60, color: Colors.grey[300]),
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
                  paso,
                  style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
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
    final todosPasos = [
      ...historial.map((e) => e['detalle'] ?? 'Sin detalle'),
      for (int i = 0; i < 4 - historial.length; i++) 'Pendiente...'
    ];
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildPhoneIcon(),
        const SizedBox(height: 20),
        Text('Seguimiento de Reparación', style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink[800])),
        const SizedBox(height: 30),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(children: [
                  Icon(Icons.phone_android, color: Colors.pink[400]),
                  const SizedBox(width: 15),
                  Text('${_reparacion?['marca'] ?? 'Marca'} ${_reparacion?['modelo'] ?? 'Modelo'}', style: const TextStyle(fontSize: 16)),
                ]),
                const SizedBox(height: 15),
                Row(children: [
                  Icon(Icons.info_outline, color: Colors.pink[400]),
                  const SizedBox(width: 15),
                  Text('Estado: ${_reparacion?['estado'] ?? 'No especificado'}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getColorEstado(_reparacion?['estado']))),
                ]),
                const SizedBox(height: 15),
                Row(children: [
                  Icon(Icons.confirmation_number, color: Colors.pink[400]),
                  const SizedBox(width: 15),
                  Text('Código: ${_reparacion?['id'] ?? 'No especificado'}', style: const TextStyle(fontSize: 16)),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text('Progreso de tu reparación', style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink[800])),
        const SizedBox(height: 20),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              for (var i = 0; i < todosPasos.length; i++) _buildTimelineStep(todosPasos[i], i, i == todosPasos.length - 1),
            ]),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => setState(() => _showTracking = false),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[400],
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Nueva Consulta', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildNotificacionEquipoListo() {
    if (!_mostrarNotificacion) return const SizedBox.shrink();
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 6,
        color: Colors.green[600],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 40),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('¡TU EQUIPO ESTÁ LISTO!', style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Puedes pasar a retirarlo en nuestro local', style: GoogleFonts.notoSans(color: Colors.white, fontSize: 14)),
                ]),
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _mostrarNotificacion = false)),
            ],
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KRAKEN REPARACIONES', style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink[600],
        centerTitle: true,
      ),
      body: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.pink[50]!, Colors.amber[50]!))),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              SizedBox(height: 20),
              _showTracking ? _buildTrackingInfo() : _buildConsultaForm(),
            ]),
          ),
          if (_mostrarNotificacion) _buildNotificacionEquipoListo(),
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
