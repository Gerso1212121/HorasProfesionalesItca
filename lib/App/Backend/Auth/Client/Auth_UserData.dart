/*----------|IMPORTACIONES BASICAS|----------*/
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
/*----------|FIREBASE|----------*/
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
/*----------|MODULOS|----------*/
import 'Auth_Login.dart';
import '../../../utils/Utils_ServiceLog.dart';
import '../../../../Frontend/Widgets/auth/custom_input_field.dart'; // Asumiendo que tienes este widget

class UserDataScreen extends StatefulWidget {
  const UserDataScreen({Key? key}) : super(key: key);

  @override
  State<UserDataScreen> createState() => UuserDataScreenState();
}

class UuserDataScreenState extends State<UserDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController sedeController = TextEditingController();
  final TextEditingController carreraController = TextEditingController();
  final TextEditingController anioController = TextEditingController();

  bool esItca = false;
  bool _isLoading = false;
  User? user;
  String? correo;

  @override
  void initState() {
    super.initState();
    verificarCorreoItca();
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    sedeController.dispose();
    carreraController.dispose();
    anioController.dispose();
    super.dispose();
  }

  String? _validateNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa un nombre y un apellido';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu teléfono';
    }
    if (value.length < 8) {
      return 'El teléfono debe tener al menos 8 dígitos';
    }
    return null;
  }

  String? _validateSede(String? value) {
    if (esItca && (value == null || value.isEmpty)) {
      return 'Por favor ingresa tu sede';
    }
    return null;
  }

  String? _validateCarrera(String? value) {
    if (esItca && (value == null || value.isEmpty)) {
      return 'Por favor ingresa tu carrera';
    }
    return null;
  }

  String? _validateAnio(String? value) {
    if (esItca && (value == null || value.isEmpty)) {
      return 'Por favor ingresa tu año de estudio';
    }
    return null;
  }

  Future<void> guardarDatos() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final nombre = nombreController.text.trim();
    final telefono = telefonoController.text.trim();
    final sede = sedeController.text.trim();
    final carrera = carreraController.text.trim();
    final anio = anioController.text.trim();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Usuario no autenticado"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final nombreCompleto = nombre.split(' ');
      final nombreSolo = nombreCompleto.isNotEmpty ? nombreCompleto.first : '';
      final apellidoSolo =
          nombreCompleto.length > 1 ? nombreCompleto.sublist(1).join(' ') : '';

      await FirebaseFirestore.instance
          .collection('estudiantes')
          .doc(user.uid)
          .set({
        'uid_firebase': user.uid,
        'nombre': nombreSolo,
        'apellido': apellidoSolo,
        'correo': user.email,
        'telefono': telefono,
        'sede': esItca ? sede : null,
        'carrera': esItca ? carrera : null,
        'año': esItca ? anio : null,
        'fecha_sincronizacion': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Datos guardados exitosamente"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar datos: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void verificarCorreoItca() async {
    FirebaseAuth.instance.authStateChanges().listen((User? currentUser) {
      if (currentUser != null && currentUser.email != null) {
        final correoUsuario = currentUser.email!.trim().toLowerCase();
        LogService.log("Verificando correo ITCA para: $correoUsuario");
        final esItcaResult = correoUsuario.endsWith('@itca.edu.sv');

        if (mounted) {
          setState(() {
            user = currentUser;
            correo = correoUsuario;
            esItca = esItcaResult;
          });

          LogService.log("Resultado verificación ITCA: $esItcaResult");
        }
      } else {
        LogService.log("Usuario no autenticado al verificar correo ITCA");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: size.width > 400 ? 380 : size.width * 0.9,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/cerebron.png',
                      height: 80,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Completa tu perfil',
                      style: GoogleFonts.itim(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      esItca
                          ? 'Datos para estudiante ITCA'
                          : 'Completa tu información personal',
                      style: GoogleFonts.itim(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (correo != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: esItca ? Colors.orange[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: esItca
                                ? Colors.orange[200]!
                                : Colors.green[200]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  esItca ? Icons.school : Icons.person,
                                  color: esItca ? Colors.orange : Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    correo!,
                                    style: GoogleFonts.itim(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              esItca ? 'Estudiante ITCA' : 'Usuario externo',
                              style: GoogleFonts.itim(
                                fontSize: 12,
                                color: esItca ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    CustomInputField(
                      label: 'Primer Nombre y Primer Apellido',
                      controller: nombreController,
                      validator: _validateNombre,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: 'Teléfono',
                      controller: telefonoController,
                      validator: _validateTelefono,
                      keyboardType: TextInputType.phone,
                    ),
                    if (esItca) ...[
                      const SizedBox(height: 20),
                      CustomInputField(
                        label: 'Sede',
                        controller: sedeController,
                        validator: _validateSede,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 20),
                      CustomInputField(
                        label: 'Carrera',
                        controller: carreraController,
                        validator: _validateCarrera,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 20),
                      CustomInputField(
                        label: 'Año Ingresado',
                        controller: anioController,
                        validator: _validateAnio,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : guardarDatos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF66B7D),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: const Color.fromARGB(100, 246, 107, 125),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Guardar y Continuar',
                                style: GoogleFonts.itim(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
