import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:horas2/Admin/login.dart';
import 'package:horas2/Admin_Dashboard.dart';
import 'package:horas2/Backend/Data/API/FireBaseService.dart';
import 'package:horas2/Backend/Data/API/SupabaseService.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la fábrica de bases de datos FFI para desktop
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await dotenv.load();

  // Formato de fechas
  await initializeDateFormatting('es_ES', null);

  try {
    // ✅ INICIALIZA FIREBASE PRIMERO
    await FirebaseService.initialize();
    print('✅ Firebase inicializado correctamente');

    // ✅ INICIALIZA SUPABASE
    await SupabaseService.initialize();
    print('✅ Supabase inicializado');

    // ✅ BASE DE DATOS LOCAL
    await DatabaseHelper.instance.database;
    print('✅ Servicios inicializados correctamente');

    // Intentar autenticación automática con el nuevo usuario
    await _autoLogin();
  } catch (e) {
    print('⚠️ Error inicializando servicios: $e');
  }

  runApp(const MyApp());
}

// Función para autenticación automática con el nuevo usuario
Future<void> _autoLogin() async {
  try {
    final firebaseAuth = FirebaseAuth.instance;

    // Verificar si ya hay un usuario autenticado en Firebase
    final currentUser = firebaseAuth.currentUser;

    if (currentUser != null) {
      print('✅ Usuario Firebase ya autenticado: ${currentUser.email}');
      return;
    }

    // Intentar autenticación automática con el nuevo usuario
    print('🔄 Intentando autenticación automática en Firebase...');
    try {
      await firebaseAuth.signInWithEmailAndPassword(
        email: 'gerson.franco24@itca.edu.sv',
        password: '123123',
      );
      print('✅ Autenticación automática exitosa con itcaadmin@gmail.com');
    } catch (firebaseError) {
      print('⚠️ Error en autenticación automática Firebase: $firebaseError');
      print(
          '💡 Verifica que el usuario itcaadmin@gmail.com exista en Firebase Authentication');
    }
  } catch (e) {
    print('⚠️ Error en proceso de auto-login: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    // Agregar un pequeño delay para permitir que la autenticación automática funcione
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // Verificar si hay usuario autenticado
        final user = _auth.currentUser;

        if (user != null) {
          print('✅ Usuario autenticado en la app: ${user.email}');
          setState(() {
            _isAuthenticated = true;
            _userEmail = user.email;
          });
        } else {
          print('ℹ️ No hay usuario autenticado después de intentar auto-login');
          setState(() {
            _isAuthenticated = false;
          });
        }

        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Método para intentar login automático nuevamente
  Future<void> _tryAutoLoginAgain() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: 'gerson.franco24@itca.edu.sv',
        password: '123123',
      );
      print("SUPABASE SESION INICIADA CORRECTAMENTE");
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _userEmail = 'gerson.franco24@itca.edu.sv';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error en autenticación automática: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }

  // Método para ir al login manual
  void _goToManualLogin() {
    runApp(MaterialApp(
      title: 'Horas App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AdminLoginScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga inicial
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  'Iniciando sesión automáticamente...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Usuario: itcaadmin@gmail.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Si no está autenticado, mostrar opciones
    if (!_isAuthenticated) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Acceso Administrativo ITCA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'itcaadmin@gmail.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _tryAutoLoginAgain,
                    icon: const Icon(Icons.login),
                    label: const Text('Iniciar Sesión Automática'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _goToManualLogin,
                    icon: const Icon(Icons.person),
                    label: const Text('Ir a Login Manual'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
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

    // Usuario autenticado - ir al Dashboard
    return MaterialApp(
      title: 'Horas App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AdminDashboard(),
    );
  }
}
