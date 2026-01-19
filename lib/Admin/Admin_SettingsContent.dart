import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Logic/Admin_AuditService.dart';

class SecurityContent extends StatefulWidget {
  const SecurityContent({Key? key}) : super(key: key);

  @override
  State<SecurityContent> createState() => _SecurityContentState();
}

class _SecurityContentState extends State<SecurityContent> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Color _primaryColor = Color(0xFF3B82F6);
  final Color _secondaryColor = Color(0xFF10B981);
  final Color _dangerColor = Color(0xFFEF4444);
  final Color _surfaceColor = Color(0xFFF8FAFC);

  bool _sedesLoading = true, _adminsLoading = true;
  List<Map<String, dynamic>> _sedes = [], _admins = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadSedes(), _loadAdmins()]);
  }

  Future<void> _loadSedes() async {
    try {
      final response = await _supabase
          .from('sedes')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _sedes = List<Map<String, dynamic>>.from(response);
        _sedesLoading = false;
      });
    } catch (e) {
      setState(() => _sedesLoading = false);
      _showSnackBar('Error al cargar sedes', isError: true);
    }
  }

  Future<void> _loadAdmins() async {
    try {
      final response = await _supabase
          .from('admins')
          .select(
              'id, username, email, name, role, status, last_login, created_at, sede:sede_id (id, nombre)')
          .order('created_at', ascending: false);
      setState(() {
        _admins = List<Map<String, dynamic>>.from(response);
        _adminsLoading = false;
      });
    } catch (e) {
      setState(() => _adminsLoading = false);
      _showSnackBar('Error al cargar administradores', isError: true);
    }
  }

  // CRUD SEDES
  Future<void> _createOrUpdateSede({Map<String, dynamic>? sede}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SedeDialog(sede: sede),
    );

    if (result != null) {
      try {
        if (sede == null) {
          await _supabase.from('sedes').insert(result);
        } else {
          await _supabase.from('sedes').update(result).eq('id', sede['id']);
        }
        _showSnackBar('Sede guardada exitosamente');
        _loadSedes();
      } catch (e) {
        _showSnackBar('Error al guardar sede', isError: true);
      }
    }
  }

  Future<void> _deleteSede(Map<String, dynamic> sede) async {
    final confirmed = await _showConfirmDialog(
      'Eliminar Sede',
      '¿Eliminar "${sede['nombre']}"?',
    );
    if (confirmed) {
      try {
        await _supabase.from('sedes').delete().eq('id', sede['id']);
        _showSnackBar('Sede eliminada exitosamente');
        _loadSedes();
      } catch (e) {
        _showSnackBar('Error al eliminar sede', isError: true);
      }
    }
  }

  // CRUD ADMINS
  Future<void> _createOrUpdateAdmin({Map<String, dynamic>? admin}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AdminDialog(admin: admin, sedes: _sedes),
    );

    if (result != null) {
      try {
        if (admin == null) {
          await _supabase.auth.signUp(
            email: '${result['username']}@admin.com',
            password: result['password'] ?? 'Admin123!',
          );
        } else {
          await _supabase.from('admins').update(result).eq('id', admin['id']);
        }
        _showSnackBar('Administrador guardado exitosamente');
        _loadAdmins();
      } catch (e) {
        _showSnackBar('Error al guardar administrador: ${e.toString()}',
            isError: true);
      }
    }
  }

  Future<void> _deleteAdmin(Map<String, dynamic> admin) async {
    final confirmed = await _showConfirmDialog(
      'Eliminar Administrador',
      '¿Eliminar "${admin['username']}"?',
    );
    if (confirmed) {
      try {
        await _supabase.from('admins').delete().eq('id', admin['id']);
        _showSnackBar('Administrador eliminado exitosamente');
        _loadAdmins();
      } catch (e) {
        _showSnackBar('Error al eliminar administrador', isError: true);
      }
    }
  }

  Future<void> _toggleAdminStatus(Map<String, dynamic> admin) async {
    try {
      final newStatus = !(admin['status'] ?? false);
      await _supabase
          .from('admins')
          .update({'status': newStatus}).eq('id', admin['id']);
      _showSnackBar('Estado actualizado');
      _loadAdmins();
    } catch (e) {
      _showSnackBar('Error al cambiar estado', isError: true);
    }
  }

  Future<void> _changeAdminPassword(Map<String, dynamic> admin) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => PasswordChangeDialog(adminName: admin['name']),
    );
    if (result != null) {
      try {
        await _supabase.auth.admin.updateUserById(
          admin['id'],
          attributes: AdminUserAttributes(password: result),
        );
        _showSnackBar('Contraseña actualizada exitosamente');
      } catch (e) {
        _showSnackBar('Error al cambiar contraseña', isError: true);
      }
    }
  }

  // Métodos auxiliares
  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: Text(content, style: GoogleFonts.inter()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar', style: GoogleFonts.inter()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: _dangerColor),
                child: Text('Confirmar', style: GoogleFonts.inter()),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _dangerColor : _secondaryColor,
      ),
    );
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
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsCards(),
          const SizedBox(height: 24),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      labelColor: _primaryColor,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: _primaryColor,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(
                            child: Text('Sedes',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600))),
                        Tab(
                            child: Text('Administradores',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildSedesTab(),
                        _buildAdminsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalAdmins = _admins.length;
    final activeAdmins = _admins.where((a) => a['status'] == true).length;
    final totalSedes = _sedes.length;

    return Row(
      children: [
        _buildStatCard(
          icon: Icons.business,
          title: 'Sedes Activas',
          value: totalSedes.toString(),
          color: _primaryColor,
        ),
        SizedBox(width: 16),
        _buildStatCard(
          icon: Icons.admin_panel_settings,
          title: 'Administradores',
          value: totalAdmins.toString(),
          color: _secondaryColor,
        ),
        SizedBox(width: 16),
        _buildStatCard(
          icon: Icons.verified_user,
          title: 'Activos',
          value: activeAdmins.toString(),
          color: Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      {required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _createOrUpdateSede(),
              icon: Icon(Icons.add, size: 20),
              label: Text('Nueva Sede', style: GoogleFonts.inter(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: _sedesLoading
              ? Center(child: CircularProgressIndicator(color: _primaryColor))
              : _sedes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business,
                              size: 64, color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text(
                            'No hay sedes registradas',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 1200 ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: _sedes.length,
                      itemBuilder: (context, index) {
                        final sede = _sedes[index];
                        return _buildSedeCard(sede);
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
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _createOrUpdateAdmin(),
              icon: Icon(Icons.add, size: 20),
              label:
                  Text('Nuevo Admin', style: GoogleFonts.inter(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: _adminsLoading
              ? Center(child: CircularProgressIndicator(color: _primaryColor))
              : _admins.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.admin_panel_settings,
                              size: 64, color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text(
                            'No hay administradores',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 1200 ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: _admins.length,
                      itemBuilder: (context, index) {
                        final admin = _admins[index];
                        return _buildAdminCard(admin);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin) {
    final sede = admin['sede'];
    final isActive = admin['status'] ?? false;
    final role = admin['role'] ?? 'admin';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _secondaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: isActive ? _secondaryColor : Colors.grey,
                    size: 24,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.key, size: 18, color: Color(0xFFF59E0B)),
                      onPressed: () => _changeAdminPassword(admin),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: 18, color: _primaryColor),
                      onPressed: () => _createOrUpdateAdmin(admin: admin),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 18, color: _dangerColor),
                      onPressed: () => _deleteAdmin(admin),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              admin['name'],
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              '@${admin['username']}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(role),
                    ),
                  ),
                ),
                Spacer(),
                Switch(
                  value: isActive,
                  onChanged: (_) => _toggleAdminStatus(admin),
                  activeColor: _secondaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



Widget _buildSedeCard(Map<String, dynamic> sede) {
  return Container(
    padding: const EdgeInsets.all(20), // Padding más amplio
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20), // Radio más suave
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
      border: Border.all(color: Colors.grey[100]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10), // Icono más grande
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.business_rounded, color: _primaryColor, size: 28),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 22, color: _primaryColor),
                  onPressed: () => _createOrUpdateSede(sede: sede),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 22, color: _dangerColor),
                  onPressed: () => _deleteSede(sede),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          sede['nombre'],
          style: GoogleFonts.inter(
            fontSize: 18, // Texto más grande
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        if (sede['direccion'] != null)
          _buildInfoRow(Icons.location_on_outlined, sede['direccion']),
        if (sede['telefono'] != null)
          const SizedBox(height: 4),
        if (sede['telefono'] != null)
          _buildInfoRow(Icons.phone_outlined, sede['telefono']),
        const Spacer(),
        _buildBadge('Sede activa', _primaryColor),
      ],
    ),
  );
}




Widget _buildBadge(String text, Color color, {bool small = false}) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: small ? 8 : 12, 
      vertical: small ? 2 : 6
    ),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), // Fondo suave del mismo color que el texto
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withOpacity(0.2), // Un borde sutil para dar definición
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min, // Ajusta el tamaño al contenido
      children: [
        // Indicador circular pequeño
        Container(
          width: small ? 4 : 6,
          height: small ? 4 : 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(), // Estilo profesional en mayúsculas
          style: GoogleFonts.inter(
            fontSize: small ? 10 : 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}
// Helper para no repetir código de filas de info
Widget _buildInfoRow(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey[500]),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
  Color _getRoleColor(String role) {
    switch (role) {
      case 'superadmin':
        return Color(0xFF8B5CF6);
      case 'admin':
        return _primaryColor;
      case 'soporte':
        return Color(0xFFF59E0B);
      case 'psicologo':
        return Color(0xFFEC4899);
      default:
        return Colors.grey;
    }
  }
}

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
        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Requerido' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                  labelText: 'Dirección (opcional)',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(),
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
          child: Text('Cancelar', style: GoogleFonts.inter()),
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
            backgroundColor: Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: Text('Guardar', style: GoogleFonts.inter()),
        ),
      ],
    );
  }
}

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
      _nameController.text = widget.admin!['name'] ?? '';
      _selectedRole = widget.admin!['role'] ?? 'admin';
      _selectedSedeId = widget.admin!['sede']?['id'];
      _status = widget.admin!['status'] ?? true;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.admin == null ? 'Nuevo Administrador' : 'Editar Administrador',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(),
                  suffixText: '@admin.com',
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Requerido' : null,
              ),
              SizedBox(height: 16),
              if (widget.admin == null)
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: GoogleFonts.inter(),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 8)
                      return 'Mínimo 8 caracteres';
                    return null;
                  },
                ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Requerido' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Rol',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(),
                ),
                items: _roles
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role, style: GoogleFonts.inter()),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedSedeId,
                decoration: InputDecoration(
                  labelText: 'Sede asignada',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(),
                ),
                items: widget.sedes
                    .map((sede) => DropdownMenuItem<int>(
                          value: sede['id'],
                          child:
                              Text(sede['nombre'], style: GoogleFonts.inter()),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSedeId = value),
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Activo', style: GoogleFonts.inter()),
                value: _status,
                onChanged: (value) => setState(() => _status = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.inter()),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'username': _usernameController.text.trim(),
                'name': _nameController.text.trim(),
                'role': _selectedRole,
                'sede_id': _selectedSedeId,
                'status': _status,
                'password': _passwordController.text.trim().isNotEmpty
                    ? _passwordController.text.trim()
                    : null,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: Text('Guardar', style: GoogleFonts.inter()),
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

  void _generateRandomPassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#';
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
      title: Text('Cambiar Contraseña',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Para: ${widget.adminName}', style: GoogleFonts.inter()),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                    (value?.length ?? 0) < 8 ? 'Mínimo 8 caracteres' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  labelStyle: GoogleFonts.inter(),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                    value != _passwordController.text ? 'No coinciden' : null,
              ),
              SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _generateRandomPassword,
                icon: Icon(Icons.shuffle),
                label: Text('Generar aleatoria'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.inter()),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _passwordController.text);
            }
          },
          child: Text('Cambiar', style: GoogleFonts.inter()),
        ),
      ],
    );
  }
}
