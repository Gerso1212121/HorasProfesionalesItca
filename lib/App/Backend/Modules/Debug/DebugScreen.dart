// lib/screens/debug_screen.dart

import 'package:flutter/material.dart';
import '../../../Data/DataBase/DatabaseHelper.dart';
import 'TableDataScreen.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _databaseHelper = DatabaseHelper.instance;
  List<String> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTables();
  }

  Future<void> _fetchTables() async {
    try {
      final tables = await _databaseHelper.getTables();
      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Error al cargar las tablas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportDatabase() async {
    try {
      final dbPath = await _databaseHelper.exportDatabase();
      _showSuccessSnackBar('Base de datos exportada a: $dbPath');
    } catch (e) {
      _showErrorSnackBar('Error al exportar la base de datos: $e');
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
        title: const Text('Control de Base de Datos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTables,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportDatabase,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tables.isEmpty
              ? const Center(child: Text('No se encontraron tablas.'))
              : ListView.builder(
                  itemCount: _tables.length,
                  itemBuilder: (context, index) {
                    final tableName = _tables[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.table_chart),
                        title: Text(tableName),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TableDataScreen(tableName: tableName),
                            ),
                          ).then((_) => _fetchTables()); // Recargar al volver
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
