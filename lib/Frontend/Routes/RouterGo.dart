import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:horas2/MainShell.dart';
import 'package:horas2/Frontend/Modules/WelcomeScreen.dart';
import 'package:horas2/Frontend/Modules/Auth/Screens/AuthLoginScreen.dart';
import 'package:horas2/Frontend/Modules/Auth/Screens/AuthRegisterScreen.dart';
import 'package:horas2/Frontend/Modules/Auth/Screens/UserDataScreen.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/HomeScreen.dart';
import 'package:horas2/Frontend/Routes/ProtectedRoute.dart';
import 'package:horas2/Backend/Data/Services/Local/LocalStorageService.dart';

/// Nombres de rutas
class RouteNames {
  static const String login = '/login';
  static const String register = '/register';
  static const String registerdata = '/user-data';
  static const String welcome = '/welcome';
  static const String home = '/home';
}

/// Enrutador global
class AppRouter {
  static bool _loginAnimationPlayed = false;

  // ================= LÓGICA COMPLETA DE REDIRECCIÓN =================
  static final LocalStorageService _storageService = LocalStorageService();

  // ================= LÓGICA SIMPLIFICADA DE REDIRECCIÓN =================
// ================= LÓGICA SIMPLIFICADA DE REDIRECCIÓN =================
  static Future<String?> _redirectLogic(
      BuildContext context, GoRouterState state) async {
    print('🔍 GoRouter - Verificando ruta: ${state.uri.toString()}');

    // ============ VERIFICAR SI EL USUARIO YA ESTÁ AUTENTICADO Y VERIFICADO ============
    final user = FirebaseAuth.instance.currentUser;
    final bool isUserVerified = user != null && user.emailVerified;

    // ============ VERIFICAR CACHE DE WELCOME ============
    final hasSeenWelcome = await _storageService.getHasSeenWelcome();
    final isRootRoute = state.uri.toString() == '/';
    final goingToWelcome = state.uri.toString() == RouteNames.welcome;
    final goingToLogin = state.uri.toString() == RouteNames.login;
    final goingToRegister = state.uri.toString() == RouteNames.register;
    final goingToUserData = state.uri.toString() == RouteNames.registerdata;
    final goingToHome = state.uri.toString() == RouteNames.home;

    print(hasSeenWelcome
        ? '✅ Cache: Usuario ya vio el welcome'
        : '❌ Cache: Usuario NO ha visto el welcome');

    print(isUserVerified
        ? '✅ Usuario autenticado y verificado'
        : '❌ Usuario no autenticado o no verificado');

    // ============ MANEJO DE RUTA RAÍZ ============
    if (isRootRoute) {
      if (isUserVerified) {
        // Si está verificado, verificar si tiene datos para ir a home
        try {
          final studentDoc = await FirebaseFirestore.instance
              .collection('estudiantes')
              .doc(user!.uid)
              .get();

          if (studentDoc.exists) {
            print('🏠 Usuario verificado con datos (raíz) → Ir a home');
            return RouteNames.home;
          } else {
            // Si no tiene datos, ir a login para que complete su registro
            print('📝 Usuario verificado sin datos (raíz) → Ir a login');
            return RouteNames.login;
          }
        } catch (e) {
          print('❌ Error en ruta raíz: $e → Ir a login');
          return RouteNames.login;
        }
      } else if (hasSeenWelcome) {
        print('📱 Usuario YA vio el welcome → Ir a login');
        return RouteNames.login;
      } else {
        print('📱 Usuario NO ha visto el welcome → Ir a welcome');
        return RouteNames.welcome;
      }
    }

    // ============ MANEJO DE WELCOME ============
    if (goingToWelcome) {
      if (isUserVerified) {
        // Usuario verificado quiere ver welcome → redirigir a login
        print(
            '🚫 Usuario verificado intentando acceder a welcome → Redirigir a login');
        return RouteNames.login;
      } else if (hasSeenWelcome) {
        print('📱 Ya vio welcome antes → Redirigiendo a login');
        return RouteNames.login;
      }
    }

    // ============ MANEJO DE LOGIN ============
    if (goingToLogin) {
      // Login siempre accesible, sin redirección automática
      print('🔓 Login siempre accesible');
      return null;
    }

    // ============ MANEJO DE REGISTER ============
    if (goingToRegister) {
      // Register siempre accesible, sin redirección automática
      print('🔓 Register siempre accesible');
      return null;
    }

    // ============ MANEJO DE USER-DATA ============
    if (goingToUserData) {
      // User-data siempre accesible, sin redirección automática
      print('🔓 User-data siempre accesible');
      return null;
    }

    // ============ CASO ESPECIAL: HOME (ÚNICA RUTA PROTEGIDA) ============
    if (goingToHome) {
      print('🏠 Verificando acceso a HOME...');

      try {
        // 1. Verificar si hay usuario logueado
        if (user == null) {
          print('🔒 No hay usuario → Redirigiendo a login');
          return RouteNames.login;
        }

        // 2. Verificar si el email está verificado
        if (!user.emailVerified) {
          print('📧 Email no verificado → Redirigiendo a login');
          return RouteNames.login;
        }

        // 3. Verificar si tiene datos en estudiantes
        final studentDoc = await FirebaseFirestore.instance
            .collection('estudiantes')
            .doc(user.uid)
            .get();

        if (!studentDoc.exists) {
          print('📄 Sin datos en estudiantes → Redirigiendo a user-data');
          return RouteNames.registerdata;
        }

        print('✅ Usuario puede acceder a HOME');
        return null; // Permitir acceso
      } catch (e) {
        print('❌ Error verificando acceso a home: $e');
        return RouteNames.login;
      }
    }

    // ============ TODAS LAS DEMÁS RUTAS SON ACCESIBLES SIEMPRE ============
    print('✅ Ruta accesible: ${state.uri.toString()}');
    return null;
  }

  // ================= ROUTER ESTÁTICO =================
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: _redirectLogic,
    routes: [
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        pageBuilder: (context, state) {
          // Agregar un timestamp o valor aleatorio para forzar reconstrucción
          final uniqueKey = ValueKey(DateTime.now().millisecondsSinceEpoch);

          return CustomTransitionPage<void>(
            key: uniqueKey, // Clave única para cada navegación
            child: const AuthLoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: RouteNames.welcome,
        name: 'welcome',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // LOGIN: Solo fade, sin slide
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const AuthRegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // REGISTER: Entra desde la derecha
            // Cuando se hace pop, sale hacia la derecha (animación secundaria)
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0), // Desde derecha
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(1.0, 0.0), // Sale hacia derecha
                ).animate(CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: RouteNames.registerdata,
        name: 'registerdata',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const UserDataScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // REGISTER: Entra desde la derecha
            // Cuando se hace pop, sale hacia la derecha (animación secundaria)
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0), // Desde derecha
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(1.0, 0.0), // Sale hacia derecha
                ).animate(CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        pageBuilder: (context, state) {
          // Agregar un timestamp o valor aleatorio para forzar reconstrucción
          final uniqueKey = ValueKey(DateTime.now().millisecondsSinceEpoch);

          return CustomTransitionPage<void>(
            key: uniqueKey, // Clave única para cada navegación
            child: const Dashboard(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text('Página no encontrada',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('La ruta ${state.uri.toString()} no existe',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () => context.go(RouteNames.login),
                child: const Text('Ir al login')),
          ],
        ),
      ),
    ),
    observers: [_RouteObserver()],
    debugLogDiagnostics: true,
  );

  // ================= TRANSICIONES =================
  static Widget _slideRightTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    final enterTween = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeInOut));

    final exitTween = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).chain(CurveTween(curve: Curves.easeInOut));

    return SlideTransition(
      position: animation.drive(enterTween),
      child: SlideTransition(
        position: secondaryAnimation.drive(exitTween),
        child: child,
      ),
    );
  }

  static Widget _fadeScaleTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }
}

class _RouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    String? routeName;

    if (route.settings.name != null) {
      routeName = route.settings.name;
    } else if (route is PageRoute && route.settings.arguments is Map) {
      final args = route.settings.arguments as Map;
      routeName = args['name']?.toString();
    }

    print('🚀 GoRouter - Ruta push: ${routeName ?? 'unknown'}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final routeName = route.settings.name ?? 'unknown';
    print('🔙 GoRouter - Ruta pop: $routeName');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final oldName = oldRoute?.settings.name ?? 'unknown';
    final newName = newRoute?.settings.name ?? 'unknown';
    print('🔄 GoRouter - Ruta reemplazada: $oldName -> $newName');
  }
}
