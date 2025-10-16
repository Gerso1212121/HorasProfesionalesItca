import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/Utils_ServiceLog.dart';
import 'Logic/Admin_AuditService.dart';

class LogsContent extends StatefulWidget {
  const LogsContent({Key? key}) : super(key: key);

  @override
  _LogsContentState createState() => _LogsContentState();
}

class _LogsContentState extends State<LogsContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Variables para logs del sistema
  late Future<List<String>> _logsFuture;
  final TextEditingController _searchController = TextEditingController();
  List<String> _allLogs = [];
  List<String> _filteredLogs = [];

  // Variables para logs de auditoría
  late Future<List<Map<String, dynamic>>> _auditLogsFuture;
  late Future<Map<String, dynamic>> _auditStatsFuture;
  final TextEditingController _auditSearchController = TextEditingController();
  List<Map<String, dynamic>> _allAuditLogs = [];
  List<Map<String, dynamic>> _filteredAuditLogs = [];

  // Filtros comunes
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  // Filtros específicos para logs del sistema
  String _selectedLogType = 'Todos';
  final List<String> _logTypes = [
    'Todos',
    'Error',
    'Warning',
    'Info',
    'Debug',
    'Success'
  ];

  // Filtros específicos para auditoría
  String _selectedAction = 'Todas';
  String _selectedTable = 'Todas';
  String _selectedAdmin = 'Todos';
  List<String> _availableActions = ['Todas'];
  List<String> _availableTables = ['Todas'];
  List<String> _availableAdmins = ['Todos'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _logsFuture = _loadLogs();
    _auditLogsFuture = _loadAuditLogs();
    _auditStatsFuture = _loadAuditStats();
    _searchController.addListener(_applySystemFilters);
    _auditSearchController.addListener(_applyAuditFilters);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _auditSearchController.dispose();
    super.dispose();
  }

  // MÉTODOS PARA LOGS DEL SISTEMA
  Future<List<String>> _loadLogs() async {
    try {
      final logs = await LogService.readLogs();
      setState(() {
        _allLogs = logs;
        _filteredLogs = logs;
      });
      return logs;
    } catch (e) {
      return ['Error cargando logs: $e'];
    }
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = _loadLogs();
    });
  }

  void _clearLogs() async {
    await LogService.clearLogs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs del sistema limpiados')),
    );
    _refreshLogs();
  }

  void _applySystemFilters() {
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        // Filtro por búsqueda de texto
        if (_searchController.text.isNotEmpty) {
          if (!log
              .toLowerCase()
              .contains(_searchController.text.toLowerCase())) {
            return false;
          }
        }

        // Filtro por tipo de log
        if (_selectedLogType != 'Todos') {
          if (!log.toLowerCase().contains(_selectedLogType.toLowerCase())) {
            return false;
          }
        }

        // Filtro por fecha
        if (_startDate != null || _endDate != null) {
          try {
            final dateMatch = RegExp(r'\[(\d{4}-\d{2}-\d{2})').firstMatch(log);
            if (dateMatch != null) {
              final logDate = DateTime.parse(dateMatch.group(1)!);
              if (_startDate != null && logDate.isBefore(_startDate!)) {
                return false;
              }
              if (_endDate != null &&
                  logDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
                return false;
              }
            }
          } catch (e) {
            // Si no se puede parsear la fecha, incluir el log
          }
        }

        return true;
      }).toList();
    });
  }

  // MÉTODOS PARA LOGS DE AUDITORÍA
  Future<List<Map<String, dynamic>>> _loadAuditLogs() async {
    try {
      final logs = await AuditService.getAuditLogs(
        fromDate: _startDate,
        toDate: _endDate,
        limit: 500,
      );

      setState(() {
        _allAuditLogs = logs;
        _filteredAuditLogs = logs;

        // Actualizar listas de filtros disponibles
        _availableActions = [
          'Todas',
          ...logs.map((log) => log['action'] as String).toSet()
        ];
        _availableTables = [
          'Todas',
          ...logs.map((log) => log['table_name'] as String).toSet()
        ];
        _availableAdmins = [
          'Todos',
          ...logs.map((log) => log['admin_username'] as String).toSet()
        ];
      });

      return logs;
    } catch (e) {
      print('Error cargando logs de auditoría: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _loadAuditStats() async {
    try {
      return await AuditService.getAuditStats(
        fromDate: _startDate,
        toDate: _endDate,
      );
    } catch (e) {
      print('Error cargando estadísticas de auditoría: $e');
      return {
        'total_actions': 0,
        'actions_by_type': <String, int>{},
        'actions_by_admin': <String, int>{},
      };
    }
  }

  void _refreshAuditLogs() {
    setState(() {
      _auditLogsFuture = _loadAuditLogs();
      _auditStatsFuture = _loadAuditStats();
    });
  }

  void _applyAuditFilters() {
    setState(() {
      _filteredAuditLogs = _allAuditLogs.where((log) {
        // Filtro por búsqueda de texto
        if (_auditSearchController.text.isNotEmpty) {
          final searchText = _auditSearchController.text.toLowerCase();
          final searchableText = [
            log['table_name'],
            log['action'],
            log['admin_username'],
            log['admin_name'],
            log['details'] ?? '',
            log['changes'] ?? '',
          ].join(' ').toLowerCase();

          if (!searchableText.contains(searchText)) {
            return false;
          }
        }

        // Filtro por acción
        if (_selectedAction != 'Todas' && log['action'] != _selectedAction) {
          return false;
        }

        // Filtro por tabla
        if (_selectedTable != 'Todas' && log['table_name'] != _selectedTable) {
          return false;
        }

        // Filtro por administrador
        if (_selectedAdmin != 'Todos' &&
            log['admin_username'] != _selectedAdmin) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _clearSystemFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _selectedLogType = 'Todos';
      _filteredLogs = _allLogs;
    });
  }

  void _clearAuditFilters() {
    setState(() {
      _auditSearchController.clear();
      _startDate = null;
      _endDate = null;
      _selectedAction = 'Todas';
      _selectedTable = 'Todas';
      _selectedAdmin = 'Todos';
      _filteredAuditLogs = _allAuditLogs;
    });
    _refreshAuditLogs();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      if (_tabController.index == 0) {
        _applySystemFilters();
      } else {
        _refreshAuditLogs();
      }
    }
  }

  // WIDGETS DE UI
  Widget _buildSystemFiltersSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showFilters ? null : 0,
      child: _showFilters
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros de Logs del Sistema',
                    style: GoogleFonts.itim(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Búsqueda de texto
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar en logs',
                      hintText: 'Escriba para buscar...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applySystemFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Selector de tipo de log
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedLogType,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Log',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: _logTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type, style: GoogleFonts.itim()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedLogType = newValue ?? 'Todos';
                            });
                            _applySystemFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Selector de rango de fechas
                      Expanded(
                        flex: 3,
                        child: _buildDateRangeSelector(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Botones de acción
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _clearSystemFilters,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: Text('Limpiar Filtros',
                            style: GoogleFonts.itim(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mostrando ${_filteredLogs.length} de ${_allLogs.length} logs',
                        style: GoogleFonts.itim(
                            color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildAuditFiltersSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showFilters ? null : 0,
      child: _showFilters
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros de Logs de Auditoría',
                    style: GoogleFonts.itim(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Búsqueda de texto
                  TextField(
                    controller: _auditSearchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar en logs de auditoría',
                      hintText: 'Usuario, acción, tabla, detalles...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _auditSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _auditSearchController.clear();
                                _applyAuditFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fila de selectores
                  Row(
                    children: [
                      // Selector de acción
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedAction,
                          decoration: InputDecoration(
                            labelText: 'Acción',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: _availableActions.map((String action) {
                            return DropdownMenuItem<String>(
                              value: action,
                              child: Text(action,
                                  style: GoogleFonts.itim(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedAction = newValue ?? 'Todas';
                            });
                            _applyAuditFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Selector de tabla
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTable,
                          decoration: InputDecoration(
                            labelText: 'Tabla',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: _availableTables.map((String table) {
                            return DropdownMenuItem<String>(
                              value: table,
                              child: Text(table,
                                  style: GoogleFonts.itim(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTable = newValue ?? 'Todas';
                            });
                            _applyAuditFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Selector de administrador
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedAdmin,
                          decoration: InputDecoration(
                            labelText: 'Admin',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: _availableAdmins.map((String admin) {
                            return DropdownMenuItem<String>(
                              value: admin,
                              child: Text(admin,
                                  style: GoogleFonts.itim(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedAdmin = newValue ?? 'Todos';
                            });
                            _applyAuditFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selector de rango de fechas
                  _buildDateRangeSelector(),
                  const SizedBox(height: 12),

                  // Botones de acción
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _clearAuditFilters,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: Text('Limpiar Filtros',
                            style: GoogleFonts.itim(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mostrando ${_filteredAuditLogs.length} de ${_allAuditLogs.length} logs',
                        style: GoogleFonts.itim(
                            color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDateRangeSelector() {
    return InkWell(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _startDate != null && _endDate != null
                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                    : 'Seleccionar rango de fechas',
                style: GoogleFonts.itim(
                  color: _startDate != null ? Colors.black87 : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            if (_startDate != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  if (_tabController.index == 0) {
                    _applySystemFilters();
                  } else {
                    _refreshAuditLogs();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getLogColor(String log) {
    final logLower = log.toLowerCase();
    if (logLower.contains('error')) return Colors.red[50]!;
    if (logLower.contains('warning')) return Colors.orange[50]!;
    if (logLower.contains('success')) return Colors.green[50]!;
    if (logLower.contains('info')) return Colors.blue[50]!;
    if (logLower.contains('debug')) return Colors.purple[50]!;
    return Colors.grey[100]!;
  }

  Color _getLogBorderColor(String log) {
    final logLower = log.toLowerCase();
    if (logLower.contains('error')) return Colors.red[300]!;
    if (logLower.contains('warning')) return Colors.orange[300]!;
    if (logLower.contains('success')) return Colors.green[300]!;
    if (logLower.contains('info')) return Colors.blue[300]!;
    if (logLower.contains('debug')) return Colors.purple[300]!;
    return Colors.grey[300]!;
  }

  IconData _getLogIcon(String log) {
    final logLower = log.toLowerCase();
    if (logLower.contains('error')) return Icons.error;
    if (logLower.contains('warning')) return Icons.warning;
    if (logLower.contains('success')) return Icons.check_circle;
    if (logLower.contains('info')) return Icons.info;
    if (logLower.contains('debug')) return Icons.bug_report;
    return Icons.description;
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Colors.green[100]!;
      case 'UPDATE':
        return Colors.blue[100]!;
      case 'DELETE':
        return Colors.red[100]!;
      case 'LOGIN':
        return Colors.purple[100]!;
      case 'LOGOUT':
        return Colors.orange[100]!;
      case 'FAILED_LOGIN':
        return Colors.red[200]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getActionBorderColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Colors.green[400]!;
      case 'UPDATE':
        return Colors.blue[400]!;
      case 'DELETE':
        return Colors.red[400]!;
      case 'LOGIN':
        return Colors.purple[400]!;
      case 'LOGOUT':
        return Colors.orange[400]!;
      case 'FAILED_LOGIN':
        return Colors.red[600]!;
      default:
        return Colors.grey[400]!;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Icons.add_circle;
      case 'UPDATE':
        return Icons.edit;
      case 'DELETE':
        return Icons.delete;
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      case 'FAILED_LOGIN':
        return Icons.error;
      default:
        return Icons.history;
    }
  }

  Widget _buildSystemLogsTab() {
    return Column(
      children: [
        _buildSystemFiltersSection(),
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
            child: FutureBuilder<List<String>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final logsToShow = _filteredLogs.isEmpty && _allLogs.isNotEmpty
                    ? _allLogs
                    : _filteredLogs;

                if (logsToShow.isEmpty ||
                    (logsToShow.length == 1 &&
                        logsToShow.first == 'Sin logs')) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No hay logs del sistema disponibles',
                          style: GoogleFonts.itim(
                              fontSize: 18, color: Colors.grey[600]),
                        ),
                        if (_searchController.text.isNotEmpty ||
                            _selectedLogType != 'Todos' ||
                            _startDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: _clearSystemFilters,
                              child: Text(
                                'Limpiar filtros para ver todos los logs',
                                style: GoogleFonts.itim(
                                    color: const Color(0xFF3B82F6)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: logsToShow.length,
                  itemBuilder: (context, index) {
                    final log = logsToShow[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getLogColor(log),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getLogBorderColor(log)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_getLogIcon(log),
                              size: 16, color: _getLogBorderColor(log)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log,
                              style: GoogleFonts.robotoMono(
                                  fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditLogsTab() {
    return Column(
      children: [
        _buildAuditFiltersSection(),

        // Estadísticas
        FutureBuilder<Map<String, dynamic>>(
          future: _auditStatsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!['total_actions'] > 0) {
              final stats = snapshot.data!;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estadísticas de Auditoría',
                            style: GoogleFonts.itim(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Total de acciones: ${stats['total_actions']} | Administradores activos: ${(stats['actions_by_admin'] as Map).length}',
                            style: GoogleFonts.itim(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _auditLogsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final logsToShow =
                    _filteredAuditLogs.isEmpty && _allAuditLogs.isNotEmpty
                        ? _allAuditLogs
                        : _filteredAuditLogs;

                if (logsToShow.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.security_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No hay logs de auditoría disponibles',
                          style: GoogleFonts.itim(
                              fontSize: 18, color: Colors.grey[600]),
                        ),
                        if (_auditSearchController.text.isNotEmpty ||
                            _selectedAction != 'Todas' ||
                            _selectedTable != 'Todas' ||
                            _selectedAdmin != 'Todos' ||
                            _startDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: _clearAuditFilters,
                              child: Text(
                                'Limpiar filtros para ver todos los logs',
                                style: GoogleFonts.itim(
                                    color: const Color(0xFF3B82F6)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: logsToShow.length,
                  itemBuilder: (context, index) {
                    final log = logsToShow[index];
                    final timestamp = DateTime.parse(log['timestamp']);
                    final action = log['action'] as String;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getActionColor(action),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: _getActionBorderColor(action)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con acción y timestamp
                          Row(
                            children: [
                              Icon(
                                _getActionIcon(action),
                                size: 20,
                                color: _getActionBorderColor(action),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  action,
                                  style: GoogleFonts.itim(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Información principal
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Admin y tabla
                                    Row(
                                      children: [
                                        Icon(Icons.person,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${log['admin_name'] ?? log['admin_username']}',
                                          style: GoogleFonts.itim(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.table_chart,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${log['table_name']}',
                                          style: GoogleFonts.itim(fontSize: 14),
                                        ),
                                        if (log['record_id'] != null &&
                                            log['record_id'] != 'unknown')
                                          Row(
                                            children: [
                                              const SizedBox(width: 16),
                                              Icon(Icons.key,
                                                  size: 14,
                                                  color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                'ID: ${log['record_id']}',
                                                style: GoogleFonts.robotoMono(
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),

                                    // Detalles adicionales si existen
                                    if (log['details'] != null &&
                                        log['details'].isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline,
                                                  size: 14,
                                                  color: Colors.grey[600]),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '${log['details']}',
                                                  style: GoogleFonts.robotoMono(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Cambios realizados
                                    if (log['changes'] != null &&
                                        log['changes'].isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[50],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: Colors.amber[200]!),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.change_circle,
                                                  size: 14,
                                                  color: Colors.amber[700]),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Cambios: ${log['changes']}',
                                                  style: GoogleFonts.robotoMono(
                                                    fontSize: 11,
                                                    color: Colors.amber[800],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // IP Address si está disponible
                                    if (log['ip_address'] != null &&
                                        log['ip_address'] != 'mobile_app' &&
                                        log['ip_address'].isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 12,
                                                color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'IP: ${log['ip_address']}',
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 10,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y botones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sistema de Logs',
                style: GoogleFonts.itim(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    icon: Icon(
                        _showFilters ? Icons.filter_alt_off : Icons.filter_alt),
                    label: Text(_showFilters ? 'Ocultar' : 'Filtros',
                        style: GoogleFonts.itim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showFilters
                          ? Colors.grey[600]
                          : const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _tabController.index == 0 ? _clearLogs : null,
                    icon: const Icon(Icons.clear_all),
                    label: Text('Limpiar', style: GoogleFonts.itim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tabController.index == 0
                          ? Colors.orange
                          : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _tabController.index == 0
                        ? _refreshLogs
                        : _refreshAuditLogs,
                    icon: const Icon(Icons.refresh),
                    label: Text('Actualizar', style: GoogleFonts.itim()),
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

          // TabBar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
              labelStyle: GoogleFonts.itim(fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.itim(),
              tabs: const [
                Tab(
                  icon: Icon(Icons.description),
                  text: 'Logs del Sistema',
                ),
                Tab(
                  icon: Icon(Icons.security),
                  text: 'Logs de Auditoría',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSystemLogsTab(),
                _buildAuditLogsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
