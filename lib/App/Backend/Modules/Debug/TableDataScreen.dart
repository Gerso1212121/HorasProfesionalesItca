// lib/screens/table_data_screen.dart

import 'package:flutter/material.dart';
import '../../../Data/DataBase/DatabaseHelper.dart';

class TableDataScreen extends StatefulWidget {
  final String tableName;

  const TableDataScreen({Key? key, required this.tableName}) : super(key: key);

  @override
  State<TableDataScreen> createState() => _TableDataScreenState();
}

class _TableDataScreenState extends State<TableDataScreen> {
  final _databaseHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _tableData = [];
  List<String> _columns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTableData();
  }

  Future<void> _fetchTableData() async {
    try {
      final data = await _databaseHelper.getTableData(widget.tableName);
      if (data.isNotEmpty) {
        _columns = data.first.keys.toList();
      } else {
        _columns = (await _databaseHelper.getTableSchema(widget.tableName))
            .map((e) => e['name'] as String)
            .toList();
      }
      setState(() {
        _tableData = data;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Error al cargar datos de la tabla: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRecord(int id) async {
    // Definir la columna de clave primaria según la tabla
    String primaryKeyColumn;
    switch (widget.tableName) {
      case 'estudiantes':
        primaryKeyColumn = 'id';
        break;
      case 'analisis_sesiones':
        primaryKeyColumn = 'id';
        break;
      case 'diario_entries':
        primaryKeyColumn = 'id_diario';
        break;
      case 'ejercicios':
        primaryKeyColumn = 'id_ejercicio';
        break;
      case 'progreso_ejercicios':
        primaryKeyColumn = 'id';
        break;
      default:
        primaryKeyColumn = 'id'; // Valor por defecto
    }

    try {
      await _databaseHelper.deleteRecord(
          widget.tableName, id, primaryKeyColumn);
      _showSuccessSnackBar('Registro $id eliminado de ${widget.tableName}');
      _fetchTableData(); // Recargar datos
    } catch (e) {
      _showErrorSnackBar('Error al eliminar el registro: $e');
    }
  }

  Future<void> _clearTable() async {
    try {
      await _databaseHelper.clearTable(widget.tableName);
      _showSuccessSnackBar('Tabla ${widget.tableName} vaciada con éxito.');
      _fetchTableData(); // Recargar datos
    } catch (e) {
      _showErrorSnackBar('Error al vaciar la tabla: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Datos de la tabla: ${widget.tableName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTableData,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: _clearTable,
            tooltip: 'Vaciar Tabla',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tableData.isEmpty
              ? const Center(child: Text('La tabla está vacía.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: _columns
                        .map((column) => DataColumn(
                              label: Text(
                                column,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ))
                        .toList(),
                    rows: _tableData.map((row) {
                      return DataRow(
                        cells: _columns.map((column) {
                          final value = row[column]?.toString() ?? 'null';
                          return DataCell(
                            Text(value),
                            // Botón de eliminar por fila (solo si la tabla tiene ID)
                            onLongPress: () {
                              if (row.containsKey('id') ||
                                  row.containsKey('id_diario') ||
                                  row.containsKey('id_ejercicio')) {
                                _showDeleteConfirmationDialog(row);
                              }
                            },
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> row) {
    String primaryKeyColumn;
    int id;

    if (row.containsKey('id_diario')) {
      primaryKeyColumn = 'id_diario';
      id = row['id_diario'] as int;
    } else if (row.containsKey('id_ejercicio')) {
      primaryKeyColumn = 'id_ejercicio';
      id = row['id_ejercicio'] as int;
    } else {
      primaryKeyColumn = 'id';
      id = row['id'] as int;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
              '¿Estás seguro de que quieres eliminar el registro con $primaryKeyColumn = $id?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _deleteRecord(id);
                Navigator.of(context).pop();
              },
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
