import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:horas2/Backend/Data/Services/Conecction/ConnectivityService.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:horas2/Frontend/Modules/Auth/ViewModels/AuthUserDataVM.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/ViewModels/AllModulesViewModel.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/ViewModels/VMcards/HomeCardsVM.dart';
import 'package:horas2/Frontend/Modules/NotWifi/NoConnectionScreen.dart';
import 'package:horas2/Frontend/Modules/Profile/ViewModels/AnimationStateVM.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:horas2/Backend/Data/API/FireBaseService.dart';
import 'package:horas2/Backend/Data/API/SupabaseService.dart';
import 'package:horas2/Frontend/Routes/RouterGo.dart';
import 'package:horas2/Frontend/Modules/Auth/ViewModels/AuthLoginVM.dart';
import 'package:horas2/Frontend/Modules/Auth/ViewModels/AuthRegisterVM.dart';
import 'package:intl/date_symbol_data_local.dart'; // <- Agrega esta importación

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  // ✅ INICIALIZAR EL FORMATO DE FECHAS PARA ESPAÑOL
  await initializeDateFormatting('es_ES', null); // <- Agrega esta línea

  // Inicializar servicios de conectividad
  await ConnectivityService.initialize();

  // Inicializar Firebase y Supabase (deja que falle silenciosamente si no hay conexión)
  try {
    await FirebaseService.initialize();
    await SupabaseService.initialize();
    await DatabaseHelper.instance.database;
    print('✅ Servicios inicializados correctamente');
  } catch (e) {
    print('⚠️ Servicios no inicializados (posible falta de conexión): $e');
  }
       
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthLoginVM()),
        ChangeNotifierProvider(create: (_) => AuthRegisterVM()),
        ChangeNotifierProvider(create: (_) => UserDataVM()),
        ChangeNotifierProvider(create: (_) => AnimationStateVM()),
        ChangeNotifierProvider(create: (_) => PsychologyViewModel()),
        ChangeNotifierProvider(create: (_) => AllModulesViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

// ... resto del código permanece igual
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasConnection = true;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _connectionSubscription = ConnectivityService.connectionStream.listen(
      (isConnected) {
        print('📡 Cambio en conexión REAL: $isConnected');
        if (mounted) {
          setState(() {
            _hasConnection = isConnected;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    ConnectivityService.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    print('🔄 Reintentando conexión...');
    final hasRealConnection = await ConnectivityService.checkConnection();
    
    if (hasRealConnection && mounted) {
      try {
        print('⚙️ Reinicializando servicios Firebase y Supabase...');
        await FirebaseService.initialize();
        await SupabaseService.initialize();
        
        setState(() {
          _hasConnection = true;
        });
        print('✅ Conexión restablecida');
      } catch (e) {
        print('❌ Error al inicializar servicios: $e');
      }
    }
  }

  void _handleExit() {
    print('🚪 Saliendo de la aplicación...');
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ❌ No hay internet - Mostrar pantalla de error
    if (!_hasConnection) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: NoConnectionScreen(
          onRetry: _handleRetry,
          onExit: _handleExit,
        ),
      );
    }

    // ✅ Hay internet - Usar GoRouter con manejo de redirecciones
    return MaterialApp.router(
      title: 'Horas App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}