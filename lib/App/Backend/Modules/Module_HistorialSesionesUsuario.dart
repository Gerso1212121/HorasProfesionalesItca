import 'package:flutter/material.dart';
import 'package:ai_app_tests/App/Data/Models/sesion_chat.dart';
import 'package:ai_app_tests/App/Data/Models/mensaje.dart';
import 'package:ai_app_tests/App/Data/Model_ChatFirebaseRemote.dart';
import 'package:ai_app_tests/App/Services/Services_Cifrado.dart';
import 'package:ai_app_tests/Frontend/Widgets/sesion_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_app_tests/App/Backend/Modules/Module_ChatIA.dart';
import 'dart:developer' as developer;

class HistorialSesionesUsuario extends StatefulWidget {
  final String? uidUsuario;

  const HistorialSesionesUsuario({super.key, this.uidUsuario});

  @override
  State<HistorialSesionesUsuario> createState() =>
      _HistorialSesionesUsuarioState();
}

class _HistorialSesionesUsuarioState extends State<HistorialSesionesUsuario> {
  List<SesionChat> _sesiones = [];
  bool _isLoading = true;
  //String _nombreUsuario = "";

  @override
  void initState() {
    super.initState();
    _cargarSesionesUsuario();
  }

  Future<void> _cargarSesionesUsuario() async {
    setState(() => _isLoading = true);

    try {
      developer.log('🔄 Iniciando carga de sesiones...');
      final sesiones = await FirebaseChatStorage.getSesionesChat();
      developer.log('📊 SESIONES CARGADAS DESDE FIREBASE: ${sesiones.length}');

      // Debug: mostrar detalles de cada sesión
      for (int i = 0; i < sesiones.length; i++) {
        final sesion = sesiones[i];
        developer.log(
            '📝 Sesión $i: Usuario="${sesion.usuario}", Resumen="${sesion.resumen}", Fecha="${sesion.fecha}", Mensajes=${sesion.mensajes.length}');
      }

      setState(() {
        _sesiones = sesiones;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('❌ ERROR CARGANDO SESIONES: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar sesiones: $e')),
        );
      }
    }
  }

  Future<void> _eliminarSesion(int index) async {
    final sesion = _sesiones[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar sesión'),
        content:
            const Text('¿Estás seguro de que quieres eliminar esta sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        developer.log('🗑️ Eliminando sesión: ${sesion.fecha}');

        // Eliminar de Firebase y local
        await FirebaseChatStorage.deleteSesionChat(sesion.fecha);

        // Recargar todas las sesiones para asegurar consistencia
        await _cargarSesionesUsuario();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sesión eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        developer.log('❌ Error eliminando sesión: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al eliminar sesión: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _mostrarOpcionesBorrado() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Opciones de Borrado'),
        content: const Text('¿Qué deseas eliminar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarTodosLosChats();
            },
            child: const Text('🗑️ Borrar todos mis chats'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarTodosLosChats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar eliminación'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar TODOS tus chats? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SÍ, ELIMINAR TODO'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseChatStorage.deleteAllSesionesChat();

        // Recargar todas las sesiones para asegurar consistencia
        await _cargarSesionesUsuario();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Todos los chats han sido eliminados'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        developer.log('❌ Error eliminando todos los chats: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al eliminar chats: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("💬 Mis Chats Anteriores"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _mostrarOpcionesBorrado,
            tooltip: "Opciones de borrado",
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugSesiones,
            tooltip: "Debug",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSesionesUsuario,
            tooltip: "Actualizar",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _sesiones.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text('No tienes chats anteriores'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarSesionesUsuario,
                  child: ListView.builder(
                    itemCount: _sesiones.length,
                    itemBuilder: (context, index) {
                      return SesionCard(
                        sesion: _sesiones[index],
                        onTap: () => _abrirSesion(_sesiones[index]),
                        onDelete: () => _eliminarSesion(index),
                      );
                    },
                  ),
                ),
    );
  }

  void _abrirSesion(SesionChat sesion) async {
    // Asegurar que los mensajes estén descifrados antes de abrir
    await _descifrarYRetomarConversacion(sesion);
  }

  Future<void> _descifrarYRetomarConversacion(SesionChat sesion) async {
    developer.log('🔄 RETOMANDO CONVERSACIÓN: ${sesion.resumen}');
    developer.log('🔐 FORZANDO DESCIFRADO DE MENSAJES...');

    try {
      // DESCIFRADO SIMPLE: Usar el método simple y directo
      final mensajesParaDescifrar =
          sesion.mensajes.map((m) => m.toJson()).toList();

      developer.log(
          '🔐 DESCIFRADO SIMPLE: Intentando descifrar ${mensajesParaDescifrar.length} mensajes...');

      final mensajesDescifrados =
          await CifradoService.descifrarMensajes(mensajesParaDescifrar);

      // Crear nueva sesión con mensajes descifrados
      final sesionDescifrada = SesionChat(
        fecha: sesion.fecha,
        usuario: sesion.usuario,
        resumen: sesion.resumen,
        mensajes: mensajesDescifrados.map((m) => Mensaje.fromJson(m)).toList(),
        etiquetas: sesion.etiquetas,
        tituloDinamico: sesion.tituloDinamico,
      );

      developer.log(
          '✅ SIMPLE: Mensajes descifrados correctamente: ${sesionDescifrada.mensajes.length} mensajes');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatAi(sesionAnterior: sesionDescifrada),
        ),
      );
    } catch (e) {
      developer.log('❌ Error en descifrado simple: $e');
      // Si falla el descifrado, intentar abrir con la sesión original
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatAi(sesionAnterior: sesion),
        ),
      );
    }
  }

  Future<void> _debugSesiones() async {
    try {
      final todasSesiones = await FirebaseChatStorage.getSesionesChat();
      final user = FirebaseAuth.instance.currentUser;

      developer.log('🐛 === DEBUG SESIONES ===');
      developer.log('📊 Total sesiones en storage: ${todasSesiones.length}');
      developer.log(
          '👤 Usuario actual: ${user?.displayName ?? user?.email ?? "Sin usuario"}');

      for (int i = 0; i < todasSesiones.length; i++) {
        final sesion = todasSesiones[i];
        developer.log(
            '📝 Sesión $i: Usuario="${sesion.usuario}", Resumen="${sesion.resumen}", Fecha="${sesion.fecha}"');
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total sesiones: ${todasSesiones.length}'),
                  Text(
                      'Usuario actual: ${user?.displayName ?? user?.email ?? "Sin usuario"}'),
                  Text('Email: ${user?.email ?? "Sin email"}'),
                  const SizedBox(height: 10),
                  const Text('Sesiones encontradas:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...todasSesiones.map((s) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('• Usuario: "${s.usuario}"',
                            style: const TextStyle(fontSize: 12)),
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      developer.log('❌ Error en debug: $e');
    }
  }
}

class DetalleSesionUsuario extends StatelessWidget {
  final SesionChat sesion;

  const DetalleSesionUsuario({super.key, required this.sesion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de la sesión',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(sesion.resumen),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(_formatFecha(sesion.fecha)),
                        const SizedBox(width: 16),
                        Icon(Icons.message, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${sesion.mensajes.length} mensajes'),
                      ],
                    ),
                    if (sesion.etiquetas.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: sesion.etiquetas
                            .map((etiqueta) => Chip(
                                  label: Text(etiqueta),
                                  backgroundColor: Colors.blue[100],
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Conversación:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: sesion.mensajes
                    .where((m) =>
                        m.emisor != "Sistema" || m.contenido.startsWith("⚠️"))
                    .length,
                itemBuilder: (context, index) {
                  final mensajesVisibles = sesion.mensajes
                      .where((m) =>
                          m.emisor != "Sistema" || m.contenido.startsWith("⚠️"))
                      .toList();
                  final mensaje = mensajesVisibles[index];
                  final isUser = mensaje.emisor == "Usuario";

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isUser ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mensaje.emisor,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(mensaje.contenido),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return fecha;
    }
  }
}
