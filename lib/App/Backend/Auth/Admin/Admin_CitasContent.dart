import 'package:ai_app_tests/App/Data/DataBase/DatabaseHelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as SupabaseAuth;
import '../../../Utils/Utils_ServiceLog.dart';

class CitasContent extends StatefulWidget {
  const CitasContent({Key? key}) : super(key: key);

  @override
  _CitasContentState createState() => _CitasContentState();
}

class _CitasContentState extends State<CitasContent> {
  String _searchQuery = '';
  String _filtroEstado = 'todos';
  List<Map<String, dynamic>> _citas = [];
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Variables para el administrador actual
  String? _adminId;
  String? _adminEmail;
  String? _adminName;

  @override
  void initState() {
    super.initState();
    _cargarDatosAdmin();
    _cargarCitas();
  }

  Future<void> _cargarDatosAdmin() async {
    try {
      final user = SupabaseAuth.Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _adminId = user.id;
          _adminEmail = user.email;
          // Extraer nombre del email (parte antes del @) como nombre por defecto
          _adminName = user.email?.split('@').first ?? 'Admin';
        });
      }
    } catch (e) {
      await LogService.log('Error cargando datos de admin: $e');
    }
  }

  Future<void> _cargarCitas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final citas = await _dbHelper.readAgendaCitas();
      setState(() {
        _citas = citas;
        _isLoading = false;
      });
    } catch (e) {
      await LogService.log('Error cargando citas: $e');
      setState(() {
        _isLoading = false;
      });
      _mostrarError('Error al cargar las citas');
    }
  }

  List<Map<String, dynamic>> get _citasFiltradas {
    return _citas.where((cita) {
      final nombreEstudiante = (cita['nombre_estudiante'] ?? '').toLowerCase();
      final motivo = (cita['motivo_cita'] ?? '').toLowerCase();
      final estado = cita['estado_cita'] ?? '';

      final coincideBusqueda =
          nombreEstudiante.contains(_searchQuery.toLowerCase()) ||
              motivo.contains(_searchQuery.toLowerCase());

      final coincideEstado =
          _filtroEstado == 'todos' || estado == _filtroEstado;

      return coincideBusqueda && coincideEstado;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Citas',
                style: GoogleFonts.itim(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _mostrarDialogoNuevaCita,
                    icon: const Icon(Icons.add),
                    label: Text(
                      'Nueva Cita',
                      style: GoogleFonts.itim(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _cargarCitas,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'Actualizar',
                      style: GoogleFonts.itim(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Estadísticas rápidas
          Row(
            children: [
              _buildStatCard(
                'Total Citas',
                '${_citas.length}',
                Icons.calendar_today,
                const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Programadas',
                '${_citas.where((c) => c['estado_cita'] == 'programada').length}',
                Icons.schedule,
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Completadas',
                '${_citas.where((c) => c['estado_cita'] == 'completada').length}',
                Icons.check_circle,
                const Color(0xFF059669),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Canceladas',
                '${_citas.where((c) => c['estado_cita'] == 'cancelada').length}',
                Icons.cancel,
                const Color(0xFFEF4444),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Filtros y búsqueda
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o motivo...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filtroEstado,
                          decoration: InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'todos',
                                child:
                                    Text('Todos', style: GoogleFonts.itim())),
                            DropdownMenuItem(
                                value: 'programada',
                                child: Text('Programada',
                                    style: GoogleFonts.itim())),
                            DropdownMenuItem(
                                value: 'confirmada',
                                child: Text('Confirmada',
                                    style: GoogleFonts.itim())),
                            DropdownMenuItem(
                                value: 'completada',
                                child: Text('Completada',
                                    style: GoogleFonts.itim())),
                            DropdownMenuItem(
                                value: 'cancelada',
                                child: Text('Cancelada',
                                    style: GoogleFonts.itim())),
                            DropdownMenuItem(
                                value: 'reprogramada',
                                child: Text('Reprogramada',
                                    style: GoogleFonts.itim())),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filtroEstado = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Lista de citas
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildListaCitas(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.itim(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.itim(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaCitas() {
    final citasFiltradas = _citasFiltradas;

    if (citasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && _filtroEstado == 'todos'
                  ? 'No hay citas registradas'
                  : 'No se encontraron citas con los filtros aplicados',
              style: GoogleFonts.itim(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: citasFiltradas.length,
      itemBuilder: (context, index) {
        final cita = citasFiltradas[index];
        return _buildCitaCard(cita);
      },
    );
  }

  Widget _buildCitaCard(Map<String, dynamic> cita) {
    final fechaCita = DateTime.tryParse(cita['fecha_cita'] ?? '');
    final estado = cita['estado_cita'] ?? 'programada';

    Color estadoColor;
    IconData estadoIcon;

    switch (estado.toLowerCase()) {
      case 'programada':
        estadoColor = const Color(0xFF3B82F6);
        estadoIcon = Icons.schedule;
        break;
      case 'confirmada':
        estadoColor = const Color(0xFF10B981);
        estadoIcon = Icons.check_circle_outline;
        break;
      case 'completada':
        estadoColor = const Color(0xFF059669);
        estadoIcon = Icons.check_circle;
        break;
      case 'cancelada':
        estadoColor = const Color(0xFFEF4444);
        estadoIcon = Icons.cancel;
        break;
      case 'reprogramada':
        estadoColor = const Color(0xFFF59E0B);
        estadoIcon = Icons.update;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: estadoColor.withOpacity(0.1),
          child: Icon(estadoIcon, color: estadoColor),
        ),
        title: Text(
          cita['nombre_estudiante'] ?? 'Sin nombre',
          style: GoogleFonts.itim(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  fechaCita != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(fechaCita)
                      : 'Fecha no disponible',
                  style:
                      GoogleFonts.itim(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                estado.toUpperCase(),
                style: GoogleFonts.itim(
                  fontSize: 10,
                  color: estadoColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () => _mostrarDetallesCita(cita),
              child: Row(
                children: [
                  const Icon(Icons.visibility),
                  const SizedBox(width: 8),
                  Text('Ver detalles', style: GoogleFonts.itim()),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => _mostrarDialogoEditarCita(cita),
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  Text('Editar', style: GoogleFonts.itim()),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => _cambiarEstadoCita(cita),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz),
                  const SizedBox(width: 8),
                  Text('Cambiar estado', style: GoogleFonts.itim()),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => _confirmarEliminarCita(cita),
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Eliminar', style: GoogleFonts.itim(color: Colors.red)),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => _confirmarCita(cita),
              child: Row(
                children: [
                  const Icon(Icons.check_circle),
                  const SizedBox(width: 8),
                  Text('Confirmar cita', style: GoogleFonts.itim()),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cita['motivo_cita'] != null) ...[
                  Text(
                    'Motivo:',
                    style: GoogleFonts.itim(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    cita['motivo_cita'],
                    style: GoogleFonts.itim(),
                  ),
                  const SizedBox(height: 8),
                ],
                if (cita['notas_adicionales'] != null) ...[
                  Text(
                    'Notas:',
                    style: GoogleFonts.itim(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    cita['notas_adicionales'],
                    style: GoogleFonts.itim(),
                  ),
                  const SizedBox(height: 8),
                ],
                if (cita['diagnostico'] != null) ...[
                  Text(
                    'Diagnóstico:',
                    style: GoogleFonts.itim(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    cita['diagnostico'],
                    style: GoogleFonts.itim(),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Text(
                      'UID Estudiante: ',
                      style: GoogleFonts.itim(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Expanded(
                      child: Text(
                        cita['estudiante_uid'] ?? 'N/A',
                        style: GoogleFonts.itim(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoNuevaCita() {
    showDialog(
      context: context,
      builder: (context) => _DialogoNuevaCita(
        onCitaCreada: _cargarCitas,
        adminId: _adminId,
        adminName: _adminName,
      ),
    );
  }

  void _mostrarDialogoEditarCita(Map<String, dynamic> cita) {
    showDialog(
      context: context,
      builder: (context) => _DialogoEditarCita(
        cita: cita,
        onCitaEditada: _cargarCitas,
      ),
    );
  }

  void _mostrarDetallesCita(Map<String, dynamic> cita) {
    final fechaCita = DateTime.tryParse(cita['fecha_cita'] ?? '');
    final fechaCreacion = DateTime.tryParse(cita['fecha_creacion'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detalles de la Cita',
          style: GoogleFonts.itim(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem(
                  'Estudiante', cita['nombre_estudiante'] ?? 'N/A'),
              _buildDetalleItem(
                  'UID Estudiante', cita['estudiante_uid'] ?? 'N/A'),
              _buildDetalleItem(
                'Fecha de la Cita',
                fechaCita != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(fechaCita)
                    : 'N/A',
              ),
              _buildDetalleItem('Estado', cita['estado_cita'] ?? 'N/A'),
              _buildDetalleItem('Motivo', cita['motivo_cita'] ?? 'N/A'),
              _buildDetalleItem('Confirmación',
                  (cita['confirmacion_cita'] == 1) ? 'Sí' : 'No'),
              _buildDetalleItem(
                  'Notas Adicionales', cita['notas_adicionales'] ?? 'N/A'),
              _buildDetalleItem('Diagnóstico', cita['diagnostico'] ?? 'N/A'),
              _buildDetalleItem('Admin ID', _formatearAdminInfo(cita)),
              _buildDetalleItem(
                'Fecha de Creación',
                fechaCreacion != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(fechaCreacion)
                    : 'N/A',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar', style: GoogleFonts.itim()),
          ),
        ],
      ),
    );
  }

  String _formatearAdminInfo(Map<String, dynamic> cita) {
    final adminId = cita['admin_id'];
    final adminConfirmador = cita['admin_confirmador'];

    if (adminId == null && adminConfirmador == null) {
      return 'N/A';
    }

    String info = '';

    if (adminId != null) {
      info += 'Creador: $adminId';
      if (adminId == _adminId) {
        info += ' ($_adminName)';
      }
    }

    if (adminConfirmador != null) {
      if (info.isNotEmpty) info += '\n';
      info += 'Confirmó: $adminConfirmador';
      if (adminConfirmador == _adminId) {
        info += ' ($_adminName)';
      }
    }

    return info.isNotEmpty ? info : 'N/A';
  }

  void _confirmarCita(Map<String, dynamic> cita) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text(
              'Confirmar Cita',
              style: GoogleFonts.itim(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Está seguro de que desea confirmar la cita de ${cita['nombre_estudiante']}?',
              style: GoogleFonts.itim(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Información importante:',
                        style: GoogleFonts.itim(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Se registrará que usted ($_adminName) confirmó esta cita',
                    style: GoogleFonts.itim(fontSize: 14),
                  ),
                  Text(
                    '• El estado cambiará a "confirmada"',
                    style: GoogleFonts.itim(fontSize: 14),
                  ),
                  Text(
                    '• Esta acción quedará registrada en el sistema',
                    style: GoogleFonts.itim(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: GoogleFonts.itim()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _procesarConfirmacionCita(cita);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 18),
                const SizedBox(width: 4),
                Text('Confirmar', style: GoogleFonts.itim()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _procesarConfirmacionCita(Map<String, dynamic> cita) async {
    try {
      final datosActualizados = {
        'estado_cita': 'confirmada',
        'confirmacion_cita': true,
        'admin_confirmador': _adminId,
        'fecha_confirmacion': DateTime.now().toIso8601String(),
      };

      final success = await _dbHelper.updateAgendaCita(
        cita['id_agendacita'],
        datosActualizados,
      );

      if (success) {
        _mostrarMensaje('Cita confirmada correctamente por $_adminName');
        await _cargarCitas();

        // Log de la acción
        await LogService.log(
            'Cita ID ${cita['id_agendacita']} confirmada por admin $_adminId ($_adminName) '
            'para estudiante ${cita['nombre_estudiante']}');
      } else {
        _mostrarError('Error al confirmar la cita');
      }
    } catch (e) {
      await LogService.log('Error confirmando cita: $e');
      _mostrarError('Error al confirmar la cita');
    }
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.itim(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.itim(),
            ),
          ),
        ],
      ),
    );
  }

  void _cambiarEstadoCita(Map<String, dynamic> cita) {
    final estadoActual = cita['estado_cita'] ?? 'programada';
    final estados = [
      'programada',
      'confirmada',
      'completada',
      'cancelada',
      'reprogramada'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cambiar Estado de Cita',
          style: GoogleFonts.itim(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: estados.map((estado) {
            return RadioListTile<String>(
              title: Text(estado.toUpperCase(), style: GoogleFonts.itim()),
              value: estado,
              groupValue: estadoActual,
              onChanged: (value) async {
                if (value != null) {
                  Navigator.of(context).pop();
                  await _actualizarEstadoCita(cita, value);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: GoogleFonts.itim()),
          ),
        ],
      ),
    );
  }

  Future<void> _actualizarEstadoCita(
      Map<String, dynamic> cita, String nuevoEstado) async {
    try {
      final success = await _dbHelper.updateAgendaCita(
        cita['id_agendacita'],
        {'estado_cita': nuevoEstado},
      );

      if (success) {
        _mostrarMensaje('Estado actualizado correctamente');
        await _cargarCitas();
      } else {
        _mostrarError('Error al actualizar el estado');
      }
    } catch (e) {
      await LogService.log('Error actualizando estado de cita: $e');
      _mostrarError('Error al actualizar el estado');
    }
  }

  void _confirmarEliminarCita(Map<String, dynamic> cita) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar Eliminación',
          style: GoogleFonts.itim(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Está seguro de que desea eliminar la cita de ${cita['nombre_estudiante']}?',
          style: GoogleFonts.itim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: GoogleFonts.itim()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _eliminarCita(cita);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                Text('Eliminar', style: GoogleFonts.itim(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCita(Map<String, dynamic> cita) async {
    try {
      final success = await _dbHelper.deleteAgendaCita(cita['id_agendacita']);

      if (success) {
        _mostrarMensaje('Cita eliminada correctamente');
        await _cargarCitas();
      } else {
        _mostrarError('Error al eliminar la cita');
      }
    } catch (e) {
      await LogService.log('Error eliminando cita: $e');
      _mostrarError('Error al eliminar la cita');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Diálogo para crear nueva cita
class _DialogoNuevaCita extends StatefulWidget {
  final VoidCallback onCitaCreada;
  final String? adminId;
  final String? adminName;

  const _DialogoNuevaCita({
    required this.onCitaCreada,
    this.adminId,
    this.adminName,
  });

  @override
  _DialogoNuevaCitaState createState() => _DialogoNuevaCitaState();
}

class _DialogoNuevaCitaState extends State<_DialogoNuevaCita> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _uidController = TextEditingController();
  final _motivoController = TextEditingController();
  final _notasController = TextEditingController();
  final _diagnosticoController = TextEditingController();

  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaSeleccionada = const TimeOfDay(hour: 9, minute: 0);
  String _estadoSeleccionado = 'programada';
  bool _confirmacionCita = false;
  bool _isLoading = false;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Nueva Cita',
        style: GoogleFonts.itim(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Estudiante',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _uidController,
                  decoration: const InputDecoration(
                    labelText: 'UID del Estudiante',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El UID es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Selector de fecha
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}',
                    style: GoogleFonts.itim(),
                  ),
                  onTap: () => _seleccionarFecha(),
                ),

                // Selector de hora
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    'Hora: ${_horaSeleccionada.format(context)}',
                    style: GoogleFonts.itim(),
                  ),
                  onTap: () => _seleccionarHora(),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _estadoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'programada',
                        child: Text('Programada', style: GoogleFonts.itim())),
                    DropdownMenuItem(
                        value: 'confirmada',
                        child: Text('Confirmada', style: GoogleFonts.itim())),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _estadoSeleccionado = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                CheckboxListTile(
                  title: Text('Cita Confirmada', style: GoogleFonts.itim()),
                  value: _confirmacionCita,
                  onChanged: (value) {
                    setState(() {
                      _confirmacionCita = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de la Cita',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _notasController,
                  decoration: const InputDecoration(
                    labelText: 'Notas Adicionales',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _diagnosticoController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnóstico',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: GoogleFonts.itim()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardarCita,
          child: _isLoading
              ? const CircularProgressIndicator()
              : Text('Guardar', style: GoogleFonts.itim()),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );

    if (hora != null) {
      setState(() {
        _horaSeleccionada = hora;
      });
    }
  }

  Future<void> _guardarCita() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fechaCita = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month,
        _fechaSeleccionada.day,
        _horaSeleccionada.hour,
        _horaSeleccionada.minute,
      );

      final cita = await _dbHelper.createAgendaCita(
        fechaCita: fechaCita,
        motivoCita:
            _motivoController.text.isNotEmpty ? _motivoController.text : null,
        confirmacionCita: _confirmacionCita,
        estadoCita: _estadoSeleccionado,
        notasAdicionales:
            _notasController.text.isNotEmpty ? _notasController.text : null,
        diagnostico: _diagnosticoController.text.isNotEmpty
            ? _diagnosticoController.text
            : null,
        nombreEstudiante: _nombreController.text,
        estudianteUid: _uidController.text,
        adminId: widget.adminId,
      );

      if (cita != null) {
        Navigator.of(context).pop();
        widget.onCitaCreada();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        LogService.log('Error al crear la cita: cita es null');
        throw Exception('Error al crear la cita');
      }
    } catch (e) {
      await LogService.log('Error creando cita: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear la cita'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _uidController.dispose();
    _motivoController.dispose();
    _notasController.dispose();
    _diagnosticoController.dispose();
    super.dispose();
  }
}

// Diálogo para editar cita
class _DialogoEditarCita extends StatefulWidget {
  final Map<String, dynamic> cita;
  final VoidCallback onCitaEditada;

  const _DialogoEditarCita({
    required this.cita,
    required this.onCitaEditada,
  });

  @override
  _DialogoEditarCitaState createState() => _DialogoEditarCitaState();
}

class _DialogoEditarCitaState extends State<_DialogoEditarCita> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _uidController;
  late TextEditingController _motivoController;
  late TextEditingController _notasController;
  late TextEditingController _diagnosticoController;

  late DateTime _fechaSeleccionada;
  late TimeOfDay _horaSeleccionada;
  late String _estadoSeleccionado;
  late bool _confirmacionCita;
  bool _isLoading = false;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();

    _nombreController =
        TextEditingController(text: widget.cita['nombre_estudiante'] ?? '');
    _uidController =
        TextEditingController(text: widget.cita['estudiante_uid'] ?? '');
    _motivoController =
        TextEditingController(text: widget.cita['motivo_cita'] ?? '');
    _notasController =
        TextEditingController(text: widget.cita['notas_adicionales'] ?? '');
    _diagnosticoController =
        TextEditingController(text: widget.cita['diagnostico'] ?? '');

    final fechaCita =
        DateTime.tryParse(widget.cita['fecha_cita'] ?? '') ?? DateTime.now();
    _fechaSeleccionada = fechaCita;
    _horaSeleccionada = TimeOfDay.fromDateTime(fechaCita);

    _estadoSeleccionado = widget.cita['estado_cita'] ?? 'programada';
    _confirmacionCita = (widget.cita['confirmacion_cita'] == 1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Editar Cita',
        style: GoogleFonts.itim(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Estudiante',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _uidController,
                  decoration: const InputDecoration(
                    labelText: 'UID del Estudiante',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El UID es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Selector de fecha
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}',
                    style: GoogleFonts.itim(),
                  ),
                  onTap: () => _seleccionarFecha(),
                ),

                // Selector de hora
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    'Hora: ${_horaSeleccionada.format(context)}',
                    style: GoogleFonts.itim(),
                  ),
                  onTap: () => _seleccionarHora(),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _estadoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'programada',
                        child: Text('Programada', style: GoogleFonts.itim())),
                    DropdownMenuItem(
                        value: 'confirmada',
                        child: Text('Confirmada', style: GoogleFonts.itim())),
                    DropdownMenuItem(
                        value: 'completada',
                        child: Text('Completada', style: GoogleFonts.itim())),
                    DropdownMenuItem(
                        value: 'cancelada',
                        child: Text('Cancelada', style: GoogleFonts.itim())),
                    DropdownMenuItem(
                        value: 'reprogramada',
                        child: Text('Reprogramada', style: GoogleFonts.itim())),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _estadoSeleccionado = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                CheckboxListTile(
                  title: Text('Cita Confirmada', style: GoogleFonts.itim()),
                  value: _confirmacionCita,
                  onChanged: (value) {
                    setState(() {
                      _confirmacionCita = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de la Cita',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _notasController,
                  decoration: const InputDecoration(
                    labelText: 'Notas Adicionales',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _diagnosticoController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnóstico',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: GoogleFonts.itim()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _actualizarCita,
          child: _isLoading
              ? const CircularProgressIndicator()
              : Text('Actualizar', style: GoogleFonts.itim()),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );

    if (hora != null) {
      setState(() {
        _horaSeleccionada = hora;
      });
    }
  }

  Future<void> _actualizarCita() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fechaCita = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month,
        _fechaSeleccionada.day,
        _horaSeleccionada.hour,
        _horaSeleccionada.minute,
      );

      final datosActualizados = {
        'fecha_cita': fechaCita.toIso8601String(),
        'motivo_cita':
            _motivoController.text.isNotEmpty ? _motivoController.text : null,
        'confirmacion_cita': _confirmacionCita,
        'estado_cita': _estadoSeleccionado,
        'notas_adicionales':
            _notasController.text.isNotEmpty ? _notasController.text : null,
        'diagnostico': _diagnosticoController.text.isNotEmpty
            ? _diagnosticoController.text
            : null,
        'nombre_estudiante': _nombreController.text,
        'estudiante_uid': _uidController.text,
      };

      final success = await _dbHelper.updateAgendaCita(
        widget.cita['id_agendacita'],
        datosActualizados,
      );

      if (success) {
        Navigator.of(context).pop();
        widget.onCitaEditada();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        LogService.log(
            'Error al actualizar la cita ID ${widget.cita['id_agendacita']}');
        throw Exception('Error al actualizar la cita');
      }
    } catch (e) {
      await LogService.log('Error actualizando cita: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar la cita'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _uidController.dispose();
    _motivoController.dispose();
    _notasController.dispose();
    _diagnosticoController.dispose();
    super.dispose();
  }
}
