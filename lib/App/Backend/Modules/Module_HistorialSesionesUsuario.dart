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

      // Ordenar por fecha (más reciente primero)
      sesiones.sort((a, b) => b.fecha.compareTo(a.fecha));

      setState(() {
        _sesiones = sesiones;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('❌ ERROR CARGANDO SESIONES: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar sesiones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarSesion(int index) async {
    final sesion = _sesiones[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Eliminar sesión'),
        content: RichText(
          text: const TextSpan(
            style: TextStyle(color: Colors.black87, fontSize: 14),
            children: [
              TextSpan(text: '¿Estás seguro de que quieres eliminar '),
              TextSpan(
                text: 'esta sesión',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '? Esta acción no se puede deshacer.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        developer.log('🗑️ Eliminando sesión: ${sesion.fecha}');
        await FirebaseChatStorage.deleteSesionChat(sesion.fecha);
        await _cargarSesionesUsuario();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Sesión eliminada correctamente'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Opciones de Borrado',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona qué deseas eliminar:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.warning_amber, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta acción eliminará todos tus chats y no se puede deshacer.',
                    style: TextStyle(fontSize: 13, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botón cancelar
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          // Botón borrar todo
          Expanded(
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _eliminarTodosLosChats();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Borrar todos',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarTodosLosChats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: const [
            Icon(Icons.warning_amber, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'Confirmar Eliminación',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '¿Estás seguro de que quieres eliminar TODOS tus chats?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'Se eliminarán todas tus conversaciones y esta acción no se puede deshacer.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          // Botón cancelar
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          // Botón eliminar todo
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                '🗑️ ELIMINAR TODO',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseChatStorage.deleteAllSesionesChat();
        await _cargarSesionesUsuario();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Todos los chats han sido eliminados'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
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
      backgroundColor: const Color(0xFFF8FDFF),
      appBar: AppBar(
        title: const Text(
          "Historial de Chats",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3748),
          ),
        ),
        backgroundColor: const Color(0xFFF2FFFF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF2FFFF), Color(0xFFF2FFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
        ),
        actions: [
          // Botón de actualizar
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF86A8E7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF86A8E7),
                size: 20,
              ),
            ),
            onPressed: _cargarSesionesUsuario,
            tooltip: "Actualizar",
          ),

          // Botón de borrado
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF66B7D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Color(0xFFF66B7D),
                size: 20,
              ),
            ),
            onPressed: _mostrarOpcionesBorrado,
            tooltip: "Opciones de borrado",
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _sesiones.isEmpty
              ? _buildEmptyState()
              : _buildSesionesList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF86A8E7)),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando tus conversaciones...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono central
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF86A8E7), Color(0xFFB2F5DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Título
              Text(
                '¡Aún no tienes chats!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),

              // Subtítulo
              Text(
                'Comienza una nueva conversación con tu asistente AI y guarda tus progresos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Botón de acción
              FilledButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ChatAi()),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Iniciar Nuevo Chat'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF86A8E7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSesionesList() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF2FFFF),
            Color(0xFFE8F5E8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Header informativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_sesiones.length} conversación${_sesiones.length != 1 ? 'es' : ''} guardada${_sesiones.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista de sesiones
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargarSesionesUsuario,
              color: const Color(0xFF86A8E7),
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _sesiones.length,
                itemBuilder: (context, index) {
                  final sesion = _sesiones[index];
                  return GestureDetector(
                    onTap: () => _abrirSesion(sesion),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F5E8), Color(0xFFF2FFFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.shade200.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.green,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sesion.resumen.isNotEmpty
                                      ? sesion.resumen
                                      : 'Sin resumen',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3748),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Última actualización: ${sesion.fecha}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _eliminarSesion(index),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFF66B7D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirSesion(SesionChat sesion) async {
    await _descifrarYRetomarConversacion(sesion);
  }

  Future<void> _descifrarYRetomarConversacion(SesionChat sesion) async {
    developer.log('🔄 RETOMANDO CONVERSACIÓN: ${sesion.resumen}');

    try {
      final mensajesParaDescifrar =
          sesion.mensajes.map((m) => m.toJson()).toList();

      final mensajesDescifrados =
          await CifradoService.descifrarMensajes(mensajesParaDescifrar);

      final sesionDescifrada = SesionChat(
        fecha: sesion.fecha,
        usuario: sesion.usuario,
        resumen: sesion.resumen,
        mensajes: mensajesDescifrados.map((m) => Mensaje.fromJson(m)).toList(),
        etiquetas: sesion.etiquetas,
        tituloDinamico: sesion.tituloDinamico,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatAi(sesionAnterior: sesionDescifrada),
        ),
      );
    } catch (e) {
      developer.log('❌ Error en descifrado: $e');
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

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange),
                SizedBox(width: 8),
                Text('Debug Info'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total sesiones: ${todasSesiones.length}'),
                  Text('Usuario: ${user?.email ?? "Sin usuario"}'),
                  const SizedBox(height: 16),
                  const Text('Sesiones:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...todasSesiones.take(5).map((s) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('• ${s.resumen}',
                            style: const TextStyle(fontSize: 12)),
                      )),
                  if (todasSesiones.length > 5)
                    Text('... y ${todasSesiones.length - 5} más',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
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
