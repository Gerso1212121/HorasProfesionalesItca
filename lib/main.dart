/*----------|IMPORTACIONES FLUTTER|----------*/
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

/*----------|IMPORTACIONES FIREBASE|----------*/
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/*----------|IMPORTACIONES MODULOS|----------*/
import 'App/Backend/Auth/Client/Auth_Login.dart';
import 'App/Backend/Dashboard->FRONTEND.dart';
import 'Frontend/Screens/auth/welcome_screen.dart';

/*----------|IMPORTACIONES OTROS|----------*/
import 'App/Data/DataBase/DatabaseHelper.dart';
import 'App/utils/Utils_ServiceLog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es', null);
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  try {
    await dotenv.load(fileName: ".env");
    LogService.log("✅ dotenv.load exitoso");
    LogService.log(
        "✅ OPENAI_API_KEY cargado: ${dotenv.env['OPENAI_API_KEY']?.substring(0, 10)}...");
  } catch (e) {
    LogService.log("❌ Error en dotenv.load: $e");
  }
  // Cargar variables de supabase desde .env
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
        "❌ Las variables SUPABASE_URL o SUPABASE_ANON_KEY no están definidas en .env");
  }
  // Inicializar Supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  LogService.log("✅ Supabase inicializado");
  //Actualizamos Contenidos
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.syncAllData();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

/*----------|ESTA CLASE FUNCIONA COMO CLASE INTERMEDIA MIENTRAS SE EVALUA UNA POSIBLE SESSION ABIERTA|----------*/
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  // Muestra una pantalla de bienvenida mientras se verifica la sesión del usuario
  // La pantalla que se usara es la WelcomeScreen, que contiene una animación de bienvenida
  Future<bool> checkSesion() async {
    // Inicializar el servicio de logs
    await LogService.log('Verificando sesión del usuario');
    // Obtener el usuario actual de Firebase
    final user = FirebaseAuth.instance.currentUser;

    // Si hay un usuario autenticado, verificar si ya existe en la base de datos
    if (user != null) {
      try {
        // Inicializar la base de datos
        final dbHelper = DatabaseHelper.instance;
        // Verificar si el usuario ya está en la base de datos SQLite
        final estudiante = await dbHelper.getEstudiantePorUID(user.uid);
        await LogService.log(
            'Finalizando Verificacion de session del usuario. Resultados: Usuario autenticado con UID ${user.uid} y datos: $estudiante, mostrando pantalla de dashboard');
        return estudiante != null;
      } catch (e) {
        // Si hay error con la base de datos (como en web), asumir que no hay sesión local
        await LogService.log(
            'Finalizando Verificacion de session del usuario. Resultados: Usuario autenticado con UID ${user.uid} pero error con BD: $e, mostrando pantalla de login');
        return false;
      }
    }

    // Si no hay usuario autenticado, verificar si hay estudiantes en la base de datos
    try {
      final dbHelper = DatabaseHelper.instance;
      // Si hay estudiantes, eliminar el actual para evitar duplicados
      final estudiantesCount = await dbHelper.countEstudiantes();
      if (estudiantesCount > 0) {
        await dbHelper.deleteEstudianteActual();
        await LogService.log(
            'Proceso Verificacion de session del usuario. Resultados: Hay estudiantes resagados en la base de datos, eliminando el actual y mostrando pantalla de login');
      }
    } catch (e) {
      // Si hay error con la base de datos, continuar sin ella
      await LogService.log(
          'Proceso Verificacion de session del usuario. Resultados: Error con BD: $e, continuando sin BD local');
    }

    // Si no hay usuario autenticado y no hay estudiantes, retornar false para mostrar el login
    await LogService.log(
        'Finalizando Verificacion de session del usuario. Resultados: No hay sesión activa, mostrando pantalla de login');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkSesion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: WelcomeScreen()),
          );
        } else {
          final sesionActiva = snapshot.data ?? false;
          if (sesionActiva) {
            return const Dashboard();
          } else {
            return const LoginScreen();
          }
        }
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistencia Psicológica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}
