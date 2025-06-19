import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _codigoController = TextEditingController();
  final _dniController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codigoController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  void _consultarReparacion() {
    if (_codigoController.text.isEmpty || _dniController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa ambos campos')),
      );
      return;
    }
    setState(() => _isLoading = true);
    // Aquí iría tu lógica para consultar
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isLoading = false);
      Navigator.pushNamed(context, '/tracking', arguments: {
        'codigo': _codigoController.text,
        'dni': _dniController.text,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Decoración
            Positioned(
              top: -50,
              right: -50,
              child: Image.asset(
                'assets/images/telefono.png', //  imagen
                width: 200,
                color: Colors.red[100]?.withOpacity(0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Título con estilo chino
                  Text(
                    'KRAKEN REPARACIONES',
                    style: GoogleFonts.notoSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                      shadows: [
                        Shadow(
                          blurRadius: 5,
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '幸运龙维修系统', // "Dragón de la Suerte"
                    style: GoogleFonts.abel(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Tarjeta de consulta
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red[100]!,
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        Text(
                          'Consulta tu reparación',
                          style: GoogleFonts.notoSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Campo de código con estilo
                        TextField(
                          controller: _codigoController,
                          decoration: InputDecoration(
                            labelText: 'Código de seguimiento',
                            labelStyle: TextStyle(color: Colors.red[800]),
                            prefixIcon: Icon(Icons.confirmation_num, color: Colors.red[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.red[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red[400]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Campo de DNI con estilo
                        TextField(
                          controller: _dniController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Tu DNI',
                            labelStyle: TextStyle(color: Colors.red[800]),
                            prefixIcon: Icon(Icons.person_outline, color: Colors.red[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.red[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red[400]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        // Botón con estilo chino
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                              shadowColor: Colors.red[200],
                            ),
                            onPressed: _isLoading ? null : _consultarReparacion,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                              'CONSULTAR',
                              style: GoogleFonts.notoSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Acceso admin (pequeño y discreto)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/admin/login'),
                    child: Text(
                      'Acceso Administrador',
                      style: TextStyle(
                        color: Colors.red[800],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}