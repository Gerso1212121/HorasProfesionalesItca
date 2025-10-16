import 'package:flutter/material.dart';
import 'package:ai_app_tests/App/Data/Models/sesion_chat.dart';
import 'package:ai_app_tests/App/Data/Model_ChatStorage.dart';
import 'package:ai_app_tests/Frontend/Widgets/sesion_card.dart';

class HistorialSesiones extends StatefulWidget {
  const HistorialSesiones({super.key});

  @override
  State<HistorialSesiones> createState() => _HistorialSesionesState();
}

class _HistorialSesionesState extends State<HistorialSesiones> {
  List<SesionChat> _sesiones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarSesiones();
  }

  Future<void> _cargarSesiones() async {
    setState(() => _isLoading = true);
    try {
      final sesiones = await ChatStorage.getSesionesChat();
      setState(() {
        _sesiones = sesiones.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
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
      await ChatStorage.deleteSesionChat(sesion.fecha);
      setState(() => _sesiones.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sesiones.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay sesiones guardadas'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarSesiones,
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

  void _abrirSesion(SesionChat sesion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleSesion(sesion: sesion),
      ),
    );
  }
}

class DetalleSesion extends StatelessWidget {
  final SesionChat sesion;

  const DetalleSesion({super.key, required this.sesion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sesion.resumen,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Fecha: ${_formatFecha(sesion.fecha)}'),
            Text('Usuario: ${sesion.usuario}'),
            Text('Mensajes: ${sesion.mensajes.length}'),
            const SizedBox(height: 16),
            const Text('Mensajes:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: sesion.mensajes.length,
                itemBuilder: (context, index) {
                  final mensaje = sesion.mensajes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mensaje.emisor,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(mensaje.contenido),
                        ],
                      ),
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
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return fecha;
    }
  }
}
