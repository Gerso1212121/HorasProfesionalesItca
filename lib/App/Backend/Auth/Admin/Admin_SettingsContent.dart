import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../Utils/Utils_ServiceLog.dart';
import 'Logic/Admin_AuditService.dart';

class SecurityContent extends StatefulWidget {
  const SecurityContent({Key? key}) : super(key: key);

  @override
  State<SecurityContent> createState() => _SecurityContentState();
}

class _SecurityContentState extends State<SecurityContent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Estados de carga
  bool _sedesLoading = true;
  bool _adminsLoading = true;

  // Listas de datos
  List<Map<String, dynamic>> _sedes = [];
  List<Map<String, dynamic>> _admins = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSedes(),
      _loadAdmins(),
    ]);
  }

  // CRUD SEDES
  Future<void> _loadSedes() async {
    try {
      setState(() => _sedesLoading = true);

      final response = await _supabase
          .from('sedes')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _sedes = List<Map<String, dynamic>>.from(response);
        _sedesLoading = false;
      });
    } catch (e) {
      await LogService.log('Error cargando sedes: $e');
      setState(() => _sedesLoading = false);
      _showErrorSnackBar('Error al cargar las sedes');
    }
  }

  Future<void> _createOrUpdateSede({Map<String, dynamic>? sede}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SedeDialog(sede: sede),
    );

    if (result != null) {
      try {
        if (sede == null) {
          // Crear nueva sede
          final response =
              await _supabase.from('sedes').insert(result).select().single();

          // Registrar en audit trail
          await AuditService.logAction(
            tableName: 'sedes',
            action: 'CREATE',
            recordId: response['id'].toString(),
            newValues: result,
            adminId: _supabase.auth.currentUser?.id,
          );

          await LogService.log('Sede creada: ${result['nombre']}');
          _showSuccessSnackBar('Sede creada exitosamente');
        } else {
          // Actualizar sede existente
          final oldData = Map<String, dynamic>.from(sede);
          await _supabase.from('sedes').update(result).eq('id', sede['id']);

          // Registrar cambios en audit trail
          await AuditService.logAction(
            tableName: 'sedes',
            action: 'UPDATE',
            recordId: sede['id'].toString(),
            oldValues: oldData,
            newValues: result,
            adminId: _supabase.auth.currentUser?.id,
          );

          await LogService.log('Sede actualizada: ${result['nombre']}');
          _showSuccessSnackBar('Sede actualizada exitosamente');
        }
        _loadSedes();
      } catch (e) {
        await LogService.log('Error guardando sede: $e');
        _showErrorSnackBar('Error al guardar la sede');
      }
    }
  }

  Future<void> _deleteSede(Map<String, dynamic> sede) async {
    final confirmed = await _showDeleteConfirmDialog(
      'Eliminar Sede',
      '¿Está seguro de eliminar la sede "${sede['nombre']}"?\n\nEsto puede afectar a los administradores asignados.',
    );

    if (confirmed) {
      try {
        // Registrar en audit trail antes de eliminar
        await AuditService.logAction(
          tableName: 'sedes',
          action: 'DELETE',
          recordId: sede['id'].toString(),
          oldValues: sede,
          adminId: _supabase.auth.currentUser?.id,
        );

        await _supabase.from('sedes').delete().eq('id', sede['id']);
        await LogService.log('Sede eliminada: ${sede['nombre']}');
        _showSuccessSnackBar('Sede eliminada exitosamente');
        _loadSedes();
      } catch (e) {
        await LogService.log('Error eliminando sede: $e');
        _showErrorSnackBar('Error al eliminar la sede');
      }
    }
  }

  // CRUD ADMINS
  Future<void> _loadAdmins() async {
    try {
      setState(() => _adminsLoading = true);

      final response = await _supabase.from('admins').select('''
            id, username, email, name, role, status, last_login, created_at,
            sede:sede_id (id, nombre)
          ''').order('created_at', ascending: false);

      setState(() {
        _admins = List<Map<String, dynamic>>.from(response);
        _adminsLoading = false;
      });
    } catch (e) {
      await LogService.log('Error cargando admins: $e');
      setState(() => _adminsLoading = false);
      _showErrorSnackBar('Error al cargar los administradores');
    }
  }

  Future<void> _createOrUpdateAdmin(
      {Map<String, dynamic>? admin, String? finalPassword}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AdminDialog(admin: admin, sedes: _sedes),
    );

    if (result != null) {
      try {
        if (admin == null) {
          // Crear nuevo admin
          String adminEmail = '${result['username']}@admin.com';
          // 1. Crear usuario en Supabase Auth
          final authResponse = await _supabase.auth.signUp(
            email: adminEmail,
            password: result['password'] ??
                'ITCA-Admin2025!', // Contraseña por defecto
            data: {
              'username': result['username'],
              'name': result['name'],
              'role': result['role'],
            },
          );

          if (authResponse.user != null) {
            // 2. Crear registro en tabla admins con el ID del usuario de auth
            final adminData = {
              ...result,
              'id': authResponse.user!.id,
              'email': adminEmail,
            };

            adminData
                .remove('password'); // No guardar la contraseña en texto plano

            await _supabase.from('admins').insert(adminData);

            // 3. Registrar en audit trail
            await AuditService.logAction(
              tableName: 'admins',
              action: 'CREATE',
              recordId: authResponse.user!.id,
              newValues: adminData,
              adminId: _supabase.auth.currentUser?.id,
            );

            await LogService.log(
                'Admin creado: ${result['username']} con email: $adminEmail');
            _showSuccessSnackBar(
                'Administrador creado exitosamente\nEmail: $adminEmail\nContraseña usada: $finalPassword'); //TODO revisar
          } else {
            throw Exception('Error creando usuario en Auth');
          }
        } else {
          // Actualizar admin existente
          final oldData = Map<String, dynamic>.from(admin);
          await _supabase.from('admins').update(result).eq('id', admin['id']);

          // Registrar cambios en audit trail
          await AuditService.logAction(
            tableName: 'admins',
            action: 'UPDATE',
            recordId: admin['id'],
            oldValues: oldData,
            newValues: result,
            adminId: _supabase.auth.currentUser?.id,
          );

          await LogService.log('Admin actualizado: ${result['username']}');
          _showSuccessSnackBar('Administrador actualizado exitosamente');
        }
        _loadAdmins();
      } catch (e) {
        await LogService.log('Error guardando admin: $e');
        _showErrorSnackBar(
            'Error al guardar el administrador: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteAdmin(Map<String, dynamic> admin) async {
    final confirmed = await _showDeleteConfirmDialog(
      'Eliminar Administrador',
      '¿Está seguro de eliminar al administrador "${admin['username']}"?\n\nEsto también eliminará su acceso al sistema.',
    );

    if (confirmed) {
      try {
        // 1. Registrar en audit trail antes de eliminar
        await AuditService.logAction(
          tableName: 'admins',
          action: 'DELETE',
          recordId: admin['id'],
          oldValues: admin,
          adminId: _supabase.auth.currentUser?.id,
        );

        // 2. Eliminar de la tabla admins
        await _supabase.from('admins').delete().eq('id', admin['id']);

        // 3. Eliminar del auth de Supabase (esto requiere privilegios de admin)
        try {
          await _supabase.auth.admin.deleteUser(admin['id']);
        } catch (authError) {
          await LogService.log(
              'Advertencia: No se pudo eliminar del Auth: $authError');
        }

        await LogService.log('Admin eliminado: ${admin['username']}');
        _showSuccessSnackBar('Administrador eliminado exitosamente');
        _loadAdmins();
      } catch (e) {
        await LogService.log('Error eliminando admin: $e');
        _showErrorSnackBar('Error al eliminar el administrador');
      }
    }
  }

  Future<void> _toggleAdminStatus(Map<String, dynamic> admin) async {
    try {
      final oldStatus = admin['status'];
      final newStatus = !oldStatus;

      await _supabase
          .from('admins')
          .update({'status': newStatus}).eq('id', admin['id']);

      // Registrar cambio en audit trail
      await AuditService.logAction(
        tableName: 'admins',
        action: 'STATUS_CHANGE',
        recordId: admin['id'],
        oldValues: {'status': oldStatus},
        newValues: {'status': newStatus},
        adminId: _supabase.auth.currentUser?.id,
        details:
            'Estado cambiado de ${oldStatus ? 'Activo' : 'Inactivo'} a ${newStatus ? 'Activo' : 'Inactivo'}',
      );

      await LogService.log(
          'Estado de admin cambiado: ${admin['username']} -> ${newStatus ? 'Activo' : 'Inactivo'}');
      _showSuccessSnackBar('Estado del administrador actualizado');
      _loadAdmins();
    } catch (e) {
      await LogService.log('Error cambiando estado de admin: $e');
      _showErrorSnackBar('Error al cambiar el estado');
    }
  }

  // Métodos auxiliares
  Future<bool> _showDeleteConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title,
                style: GoogleFonts.itim(fontWeight: FontWeight.bold)),
            content: Text(content, style: GoogleFonts.itim()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar', style: GoogleFonts.itim()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Eliminar', style: GoogleFonts.itim()),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _changeAdminPassword(Map<String, dynamic> admin) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => PasswordChangeDialog(adminName: admin['name']),
    );

    if (result != null) {
      try {
        // Cambiar contraseña usando Supabase Auth Admin API
        await _supabase.auth.admin.updateUserById(
          admin['id'],
          attributes: AdminUserAttributes(
            password: result,
          ),
        );

        // Registrar en audit trail
        await AuditService.logAction(
          tableName: 'admins',
          action: 'PASSWORD_CHANGE',
          recordId: admin['id'],
          details: 'Contraseña cambiada por administrador',
          adminId: _supabase.auth.currentUser?.id,
        );

        await LogService.log(
            'Contraseña cambiada para admin: ${admin['username']}');
        _showSuccessSnackBar('Contraseña actualizada exitosamente');
      } catch (e) {
        await LogService.log('Error cambiando contraseña de admin: $e');
        _showErrorSnackBar('Error al cambiar la contraseña: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seguridad del Sistema',
            style: GoogleFonts.itim(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF3B82F6),
            tabs: [
              Tab(
                child: Text('Sedes', style: GoogleFonts.itim(fontSize: 16)),
              ),
              Tab(
                child: Text('Administradores',
                    style: GoogleFonts.itim(fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSedesTab(),
                _buildAdminsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSedesTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gestión de Sedes',
              style: GoogleFonts.itim(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _createOrUpdateSede(),
              icon: const Icon(Icons.add),
              label: Text('Nueva Sede', style: GoogleFonts.itim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _sedesLoading
              ? const Center(child: CircularProgressIndicator())
              : _sedes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay sedes registradas',
                            style: GoogleFonts.itim(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sedes.length,
                      itemBuilder: (context, index) {
                        final sede = _sedes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF3B82F6),
                              child: Icon(
                                Icons.business,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              sede['nombre'],
                              style:
                                  GoogleFonts.itim(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sede['direccion'] != null)
                                  Text(
                                    sede['direccion'],
                                    style: GoogleFonts.itim(fontSize: 12),
                                  ),
                                if (sede['telefono'] != null)
                                  Text(
                                    'Tel: ${sede['telefono']}',
                                    style: GoogleFonts.itim(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Color(0xFF3B82F6)),
                                  onPressed: () =>
                                      _createOrUpdateSede(sede: sede),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteSede(sede),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAdminsTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gestión de Administradores',
              style: GoogleFonts.itim(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _createOrUpdateAdmin(),
              icon: const Icon(Icons.add),
              label: Text('Nuevo Admin', style: GoogleFonts.itim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _adminsLoading
              ? const Center(child: CircularProgressIndicator())
              : _admins.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay administradores registrados',
                            style: GoogleFonts.itim(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _admins.length,
                      itemBuilder: (context, index) {
                        final admin = _admins[index];
                        final sede = admin['sede'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: admin['status']
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              admin['name'],
                              style:
                                  GoogleFonts.itim(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '@${admin['username']} • ${admin['role']}',
                                  style: GoogleFonts.itim(fontSize: 12),
                                ),
                                if (admin['email'] != null)
                                  Text(
                                    admin['email'],
                                    style: GoogleFonts.itim(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (sede != null)
                                  Text(
                                    'Sede: ${sede['nombre']}',
                                    style: GoogleFonts.itim(
                                      fontSize: 12,
                                      color: const Color(0xFF3B82F6),
                                    ),
                                  ),
                                Text(
                                  'Email: ${admin['username']}@admin.com',
                                  style: GoogleFonts.itim(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: admin['status'] ?? false,
                                  onChanged: (_) => _toggleAdminStatus(admin),
                                  activeColor: const Color(0xFF10B981),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.key,
                                      color: Color(0xFF10B981)),
                                  onPressed: () => _changeAdminPassword(admin),
                                  tooltip: 'Cambiar contraseña',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Color(0xFF3B82F6)),
                                  onPressed: () =>
                                      _createOrUpdateAdmin(admin: admin),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteAdmin(admin),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// Dialogo para crear/editar sedes
class SedeDialog extends StatefulWidget {
  final Map<String, dynamic>? sede;

  const SedeDialog({Key? key, this.sede}) : super(key: key);

  @override
  State<SedeDialog> createState() => _SedeDialogState();
}

class _SedeDialogState extends State<SedeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.sede != null) {
      _nombreController.text = widget.sede!['nombre'] ?? '';
      _direccionController.text = widget.sede!['direccion'] ?? '';
      _telefonoController.text = widget.sede!['telefono'] ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.sede == null ? 'Nueva Sede' : 'Editar Sede',
        style: GoogleFonts.itim(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la sede',
                  labelStyle: GoogleFonts.itim(),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  labelStyle: GoogleFonts.itim(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  labelStyle: GoogleFonts.itim(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.itim()),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'nombre': _nombreController.text.trim(),
                'direccion': _direccionController.text.trim().isNotEmpty
                    ? _direccionController.text.trim()
                    : null,
                'telefono': _telefonoController.text.trim().isNotEmpty
                    ? _telefonoController.text.trim()
                    : null,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: Text('Guardar', style: GoogleFonts.itim()),
        ),
      ],
    );
  }
}

// Dialogo para crear/editar administradores
class AdminDialog extends StatefulWidget {
  final Map<String, dynamic>? admin;
  final List<Map<String, dynamic>> sedes;

  const AdminDialog({Key? key, this.admin, required this.sedes})
      : super(key: key);

  @override
  State<AdminDialog> createState() => _AdminDialogState();
}

class _AdminDialogState extends State<AdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedRole = 'admin';
  int? _selectedSedeId;
  bool _status = true;

  final List<String> _roles = ['superadmin', 'admin', 'soporte', 'psicologo'];

  @override
  void initState() {
    super.initState();
    if (widget.admin != null) {
      _usernameController.text = widget.admin!['username'] ?? '';
      _emailController.text = widget.admin!['email'] ?? '';
      _passwordController.text = '';
      _nameController.text = widget.admin!['name'] ?? '';
      _selectedRole = widget.admin!['role'] ?? 'admin';
      _selectedSedeId = widget.admin!['sede']?['id'];
      _status = widget.admin!['status'] ?? true;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.admin == null ? 'Nuevo Administrador' : 'Editar Administrador',
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
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de usuario',
                    labelStyle: GoogleFonts.itim(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre de usuario es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText:
                        'Correo electrónico (se autocompletará con @admin.com)',
                    labelStyle: GoogleFonts.itim(),
                    border: const OutlineInputBorder(),
                    enabled:
                        false, // Deshabilitado porque se genera automáticamente
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: widget.admin == null
                        ? 'Contraseña'
                        : 'No se permite cambiar la contraseña',
                    labelStyle: GoogleFonts.itim(),
                    border: const OutlineInputBorder(),
                    enabled: widget.admin == null,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (widget.admin == null) {
                      // Solo validar si es creación
                      if (value == null || value.trim().isEmpty) {
                        return 'La contraseña es requerida';
                      }
                      if (value.trim().length < 8) {
                        return 'La contraseña debe tener al menos 8 caracteres';
                      }
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    labelStyle: GoogleFonts.itim(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre completo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    labelStyle: GoogleFonts.itim(),
                    border: const OutlineInputBorder(),
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role, style: GoogleFonts.itim()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedSedeId,
                  decoration: InputDecoration(
                    labelText: 'Sede asignada',
                    labelStyle: GoogleFonts.itim(),
                    border: const OutlineInputBorder(),
                  ),
                  items: widget.sedes.map((sede) {
                    return DropdownMenuItem<int>(
                      value: sede['id'],
                      child: Text(sede['nombre'], style: GoogleFonts.itim()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSedeId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Debe seleccionar una sede';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Estado activo', style: GoogleFonts.itim()),
                  value: _status,
                  onChanged: (value) {
                    setState(() {
                      _status = value;
                    });
                  },
                  activeColor: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.itim()),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final password = _passwordController.text.trim();
              final finalPassword = password.isNotEmpty ? password : null;

              final adminData = {
                'username': _usernameController.text.trim(),
                'name': _nameController.text.trim(),
                'role': _selectedRole,
                'sede_id': _selectedSedeId,
                'status': _status,
              };

              Navigator.pop(context, {...adminData, 'password': finalPassword});
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: Text('Guardar', style: GoogleFonts.itim()),
        ),
      ],
    );
  }
}

class PasswordChangeDialog extends StatefulWidget {
  final String adminName;

  const PasswordChangeDialog({Key? key, required this.adminName})
      : super(key: key);

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Debe contener mayúsculas, minúsculas y números';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme la contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  void _generateRandomPassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random();
    final password =
        List.generate(12, (index) => chars[random.nextInt(chars.length)])
            .join();

    setState(() {
      _passwordController.text = password;
      _confirmPasswordController.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Cambiar Contraseña',
        style: GoogleFonts.itim(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administrador: ${widget.adminName}',
                style: GoogleFonts.itim(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  labelStyle: GoogleFonts.itim(),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  labelStyle: GoogleFonts.itim(),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generateRandomPassword,
                      icon: const Icon(Icons.shuffle),
                      label:
                          Text('Generar automática', style: GoogleFonts.itim()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requisitos de contraseña:',
                      style: GoogleFonts.itim(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Mínimo 8 caracteres\n• Al menos una mayúscula\n• Al menos una minúscula\n• Al menos un número',
                      style: GoogleFonts.itim(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.itim()),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _passwordController.text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          child: Text('Cambiar Contraseña', style: GoogleFonts.itim()),
        ),
      ],
    );
  }
}
