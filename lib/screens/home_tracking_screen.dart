import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeTrackingScreen extends StatefulWidget {
  const HomeTrackingScreen({super.key});
  @override
  State<HomeTrackingScreen> createState() => _HomeTrackingScreenState();
}

class _HomeTrackingScreenState extends State<HomeTrackingScreen> with SingleTickerProviderStateMixin {
  final _dniController = TextEditingController();
  final _codigoController = TextEditingController();
  bool isLoading = false;
  String? message;
  Map<String, dynamic>? reparacion;

  late AnimationController _animationController;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _color1 = ColorTween(
      begin: const Color(0xFFF8BBD0),
      end: const Color(0xFFE1BEE7),
    ).animate(_animationController);

    _color2 = ColorTween(
      begin: const Color(0xFFFCE4EC),
      end: const Color(0xFFF48FB1),
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _consultarReparacion() async {
    setState(() {
      message = null;
      reparacion = null;
      isLoading = true;
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
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        message = '❌ Error al consultar: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildTracking() {
    final estado = reparacion!['estado'] as String;
    final steps = ['Recibido', 'En revisión', 'Listo para retirar'];
    final currentIndex = steps.indexOf(estado);

    IconData getIcon(int index) {
      switch (index) {
        case 0:
          return Icons.inventory_2;
        case 1:
          return Icons.build_circle;
        case 2:
          return Icons.check_circle;
        default:
          return Icons.help;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('Seguimiento de tu reparación:',
            style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final isActive = index <= currentIndex;
            return Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isActive ? Colors.teal : Colors.grey[300],
                  child: Icon(getIcon(index), color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isActive ? Colors.teal[800] : Colors.grey,
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: (currentIndex + 1) / steps.length,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
          minHeight: 6,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color1.value!, _color2.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/logokraken.jpg'),
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        children: [
                          if (reparacion == null) ...[
                            Text('🔎 Consulta tu reparación',
                                style: GoogleFonts.notoSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[900])),
                            const SizedBox(height: 20),
                            TextField(
                                controller: _codigoController,
                                decoration: const InputDecoration(
                                    labelText: 'Código de reparación',
                                    prefixIcon: Icon(Icons.qr_code))),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _dniController,
                              decoration: const InputDecoration(
                                  labelText: 'DNI del cliente',
                                  prefixIcon: Icon(Icons.perm_identity)),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 25),
                            ElevatedButton.icon(
                              onPressed: isLoading ? null : _consultarReparacion,
                              icon: const Icon(Icons.search),
                              label: isLoading
                                  ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                                  : const Text('CONSULTAR ESTADO'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal[700],
                                  padding: const EdgeInsets.symmetric(vertical: 25)),
                            ),
                            if (message != null) ...[
                              const SizedBox(height: 20),
                              Text(message!,
                                  style: TextStyle(
                                      color: message!.startsWith('❌') || message!.startsWith('⚠️')
                                          ? Colors.red
                                          : Colors.green)),
                            ],
                          ] else ...[
                            Text('Modelo: ${reparacion!['modelo']}',
                                style: GoogleFonts.notoSans(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            _buildTracking(),
                            const SizedBox(height: 30),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  reparacion = null;
                                  _codigoController.clear();
                                  _dniController.clear();
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Nueva Consulta'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal[600],
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
                            ),
                          ],
                          const SizedBox(height: 40),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/admin/login');
                              },
                              icon: const Icon(Icons.admin_panel_settings),
                              label: const Text("Administración"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 6,
                                shadowColor: Colors.black38,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.pink[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '📌 Al dejar un equipo en reparación, el cliente acepta que:\n\n'
                                  '• El diagnóstico puede demorar entre 24 y 72 horas hábiles.\n'
                                  '• Los repuestos están sujetos a disponibilidad.\n'
                                  '• El presupuesto debe ser aprobado antes de realizar cualquier trabajo.\n'
                                  '• La garantía cubre exclusivamente la reparación realizada.\n'
                                  '• Equipos no retirados en 60 días se considerarán en abandono.',
                              style: GoogleFonts.notoSans(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
