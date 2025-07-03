import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeTrackingScreen extends StatefulWidget {
  const HomeTrackingScreen({super.key});

  @override
  State<HomeTrackingScreen> createState() => _HomeTrackingScreenState();
}

class _HomeTrackingScreenState extends State<HomeTrackingScreen>
    with SingleTickerProviderStateMixin {
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
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _color1 = ColorTween(
      begin: const Color(0xFF00BFA6),
      end: const Color(0xFFC044EF),
    ).animate(_animationController);

    _color2 = ColorTween(
      begin: const Color(0xFF7E43C6),
      end: const Color(0xFF1F8888),
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
        _codigoController.clear();
        _dniController.clear();
      });
    } catch (e) {
      setState(() {
        message = '❌ Error al consultar: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildTimeline() {
    final estado = reparacion!['estado'] as String;
    final steps = ['Recibido', 'En revisión', 'Listo para retirar'];
    final currentIndex = steps.indexOf(estado);

    final icons = [
      Icons.inbox_rounded,
      Icons.build_rounded,
      Icons.emoji_people_rounded
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seguimiento de tu reparación:',
            style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        Column(
          children: List.generate(steps.length, (index) {
            final isActive = index <= currentIndex;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? Colors.greenAccent : Colors.grey[400],
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                      child: Icon(icons[index],
                          size: 16, color: isActive ? Colors.black : Colors.white),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 4,
                        height: 50,
                        color: isActive ? Colors.greenAccent : Colors.grey[400],
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isActive ? Colors.black87 : Colors.black38,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 30),
        LinearProgressIndicator(
          value: (currentIndex + 1) / steps.length,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
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
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink[900])),
                            const SizedBox(height: 40),
                            TextField(
                              controller: _codigoController,
                              decoration: const InputDecoration(
                                labelText: 'Código de reparación',
                                prefixIcon: Icon(Icons.add_circle),
                              ),
                            ),
                            const SizedBox(height: 35),
                            TextField(
                              controller: _dniController,
                              decoration: const InputDecoration(
                                labelText: 'DNI del cliente',
                                prefixIcon: Icon(Icons.perm_identity),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 35),
                            ElevatedButton.icon(
                              onPressed: isLoading ? null : _consultarReparacion,
                              icon: const Icon(Icons.search),
                              label: isLoading
                                  ? const SizedBox(
                                  width: 60,
                                  height: 56,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 5, color: Colors.white))
                                  : const Text('CONSULTAR ESTADO'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                padding: const EdgeInsets.symmetric(vertical: 35),
                              ),
                            ),
                            if (message != null) ...[
                              const SizedBox(height: 20),
                              Text(
                                message!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: message!.startsWith('❌') || message!.startsWith('⚠️')
                                      ? Colors.red
                                      : Colors.amber,
                                ),
                              ),
                            ],
                          ] else ...[
                            Text('Modelo: ${reparacion!['modelo']}',
                                style: GoogleFonts.notoSans(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text('Teléfono: ${reparacion!['telefono']}',
                                style: GoogleFonts.notoSans(
                                    fontSize: 18, color: Colors.black87)),
                            const SizedBox(height: 10),
                            Text('Falla: ${reparacion!['falla']}',
                                style: GoogleFonts.notoSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            const SizedBox(height: 30),
                            _buildTimeline(),
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
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              ),
                            ),
                          ],
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '''El cliente abajo firmante, libera de cualquier responsabilidad a KRAKEN S.T por la procedencia de este equipo. Asegura que es de su propiedad y su unico(a) representante. El equipo en cuestión está siendo dejado en el taller de KRAKEN S.T solo para diagnostico técnico y/o reparación.Entrega el equipo sin sim card(chip) y sin tarjeta SD (memoria) y/o cualquier otro accesorio, caso contrario KRAKEN S.T no se hace responsable por la pérdida o extravio de los mismos. Las fallas reportadas por el cliente al momento de solicitar el servicio, no son únicas ni absolutas y serán verificadas al momento de la revisión y las fallas encontradas serán notificadas al cliente para validar la reparación. Los equipos que se reciben completamente apagados no son verificables por lo que se desconoce el funcionamiento total o parcial del equipo o alguna caracteristica en particular y KRAKEN S.T no asume ninguna responsabilidad por ello. Los equipos golpeados y/o mojados pueden sufrir más daños, degradación o deterioro posteriores, al momento de revisarlos o incluso despues de reparadosya que tanto los golpes como la humedad ocasionan daños paulatinos por lo que KRAKEN S.T no asume responsabilidad sobre esos daños posteriores ni extendemos ningún tipo de garantía. La reparación puede tardar de 1 a 20 días hábiles, respetando el orden de recepción y la disponibilidad de repuestos. Luego de recibir aviso de terminación del servicio el cliente secompromete a cancelar el monto acordado en un laxo no mayor de 24 horas, de lo contrario se somete a los ajustes de precios por inflación. KRAKEN S.T no se hace responsable por equipos que tengan más de 60 días continuos en el taller luego de avisado para el retiro, tomado en cuenta que pasado dicho periodo se consideraque el cliente abandona el equipo y renuncia a su derecho sobre el mismo y ya que el equipo genera un gasto y trabajo especializado, se dispondrá de él para compensar dichos gastos de repuestos y servicio técnico originados, siendo el caso que el equipo en cuestión será retirado del sistema de ordenes de reparaciones y el taller pasará a reciclarlo, desecharlo o venderlo en partes o en su totalidad dependiendo del equipo. KRAKEN S.T no se hace responsable si durante el punto anterior, el equipo sufre daños o se genera un hecho de inseguiridad en nuestras instalaciones. Se ruegra puntualidad al momento de dar aviso cuando el equipo está listo para la entrega. Sin más aclaraciones queda usted notificado de nuestro método de trabajo''',
                              style: GoogleFonts.notoSans(fontSize: 13, height: 1.5),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          const SizedBox(height: 40),
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

