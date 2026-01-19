import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Logic/Admin_AuditService.dart';
import 'dart:convert';

/// Widget reutilizable para mostrar logs de auditoría
/// Puede ser usado en diferentes pantallas del admin dashboard
class AuditLogsWidget extends StatefulWidget {
  final String? tableName; // Filtrar por tabla específica
  final String? adminId; // Filtrar por admin específico
  final bool showFilters; // Mostrar controles de filtro
  final int maxHeight; // Altura máxima del widget

  const AuditLogsWidget({
    Key? key,
    this.tableName,
    this.adminId,
    this.showFilters = true,
    this.maxHeight = 400,
  }) : super(key: key);

  @override
  State<AuditLogsWidget> createState() => _AuditLogsWidgetState();
}

class _AuditLogsWidgetState extends State<AuditLogsWidget> {
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;

  // Filtros
  String? _selectedTable;
  String? _selectedAction;
  DateTime? _fromDate;
  DateTime? _toDate;

  final List<String> _availableActions = [
    'CREATE',
    'UPDATE',
    'DELETE',
    'STATUS_CHANGE',
    'LOGIN',
    'LOGOUT',
    'BULK_CREATE',
    'BULK_UPDATE',
    'BULK_DELETE'
  ];

  final List<String> _availableTables = ['admins', 'sedes', 'auth', 'system'];

  @override
  void initState() {
    super.initState();
    _selectedTable = widget.tableName;
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);

    try {
      final logs = await AuditService.getAuditLogs(
        tableName: _selectedTable,
        action: _selectedAction,
        adminId: widget.adminId,
        fromDate: _fromDate,
        toDate: _toDate,
        limit: 50,
      );

      setState(() {
        _auditLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadAuditLogs();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadAuditLogs();
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
      case 'BULK_CREATE':
        return Colors.green;
      case 'UPDATE':
      case 'STATUS_CHANGE':
      case 'BULK_UPDATE':
        return Colors.blue;
      case 'DELETE':
      case 'BULK_DELETE':
        return Colors.red;
      case 'LOGIN':
        return Colors.teal;
      case 'LOGOUT':
        return Colors.orange;
      case 'ERROR':
        return Colors.red[700]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
      case 'BULK_CREATE':
        return Icons.add_circle;
      case 'UPDATE':
      case 'STATUS_CHANGE':
      case 'BULK_UPDATE':
        return Icons.edit;
      case 'DELETE':
      case 'BULK_DELETE':
        return Icons.delete;
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      case 'ERROR':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Widget _buildFilters() {
    if (!widget.showFilters) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: GoogleFonts.itim(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Filtro por tabla
                if (widget.tableName == null)
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      value: _selectedTable,
                      decoration: const InputDecoration(
                        labelText: 'Tabla',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Todas')),
                        ..._availableTables.map(
                          (table) => DropdownMenuItem(
                              value: table, child: Text(table)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedTable = value);
                        _loadAuditLogs();
                      },
                    ),
                  ),

                // Filtro por acción
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: _selectedAction,
                    decoration: const InputDecoration(
                      labelText: 'Acción',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ..._availableActions.map(
                        (action) => DropdownMenuItem(
                            value: action, child: Text(action)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedAction = value);
                      _loadAuditLogs();
                    },
                  ),
                ),

                // Filtro por fecha
                SizedBox(
                  width: 200,
                  child: TextButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _fromDate != null && _toDate != null
                          ? '${_fromDate!.day}/${_fromDate!.month} - ${_toDate!.day}/${_toDate!.month}'
                          : 'Seleccionar fechas',
                      style: GoogleFonts.itim(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Limpiar filtro de fecha
                if (_fromDate != null || _toDate != null)
                  TextButton.icon(
                    onPressed: _clearDateFilter,
                    icon: const Icon(Icons.clear, size: 16),
                    label: Text('Limpiar fechas',
                        style: GoogleFonts.itim(fontSize: 12)),
                  ),

                // Actualizar
                ElevatedButton.icon(
                  onPressed: _loadAuditLogs,
                  icon: const Icon(Icons.refresh, size: 16),
                  label:
                      Text('Actualizar', style: GoogleFonts.itim(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final action = log['action'] as String;
    final actionColor = _getActionColor(action);
    final actionIcon = _getActionIcon(action);
    final timestamp = DateTime.parse(log['timestamp']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: actionColor.withOpacity(0.1),
          child: Icon(actionIcon, color: actionColor, size: 20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: actionColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                action,
                style: GoogleFonts.itim(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${log['table_name']} - ${log['admin_username']}',
                style:
                    GoogleFonts.itim(fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              log['admin_name'] ?? 'N/A',
              style: GoogleFonts.itim(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.itim(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Detalles
                if (log['details'] != null)
                  _buildDetailRow('Detalles', log['details']),

                // Cambios
                if (log['changes'] != null)
                  _buildDetailRow('Cambios', log['changes']),

                // Record ID
                _buildDetailRow('ID del Registro', log['record_id']),

                // IP Address
                if (log['ip_address'] != null)
                  _buildDetailRow('Dirección IP', log['ip_address']),

                // Valores anteriores
                if (log['old_values'] != null)
                  _buildJsonRow('Valores Anteriores', log['old_values']),

                // Valores nuevos
                if (log['new_values'] != null)
                  _buildJsonRow('Valores Nuevos', log['new_values']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.itim(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.itim(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonRow(String label, String jsonString) {
    Map<String, dynamic>? jsonData;
    try {
      jsonData = jsonDecode(jsonString);
    } catch (e) {
      jsonData = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.itim(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              jsonData != null
                  ? const JsonEncoder.withIndent('  ').convert(jsonData)
                  : jsonString,
              style: GoogleFonts.robotoMono(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _auditLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay logs de auditoría',
                            style: GoogleFonts.itim(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _auditLogs.length,
                      itemBuilder: (context, index) {
                        return _buildLogItem(_auditLogs[index]);
                      },
                    ),
        ),
      ],
    );
  }
}

/// Pantalla completa para mostrar logs de auditoría
class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Logs de Auditoría',
          style: GoogleFonts.itim(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: AuditLogsWidget(),
      ),
    );
  }
}

/// Dialog para mostrar logs de un registro específico
class RecordAuditDialog extends StatelessWidget {
  final String tableName;
  final String recordId;
  final String recordName;

  const RecordAuditDialog({
    Key? key,
    required this.tableName,
    required this.recordId,
    required this.recordName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Historial de "$recordName"',
                    style: GoogleFonts.itim(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: AuditLogsWidget(
                tableName: tableName,
                showFilters: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
