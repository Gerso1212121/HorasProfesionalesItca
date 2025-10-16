import 'package:flutter/material.dart';
import 'package:ai_app_tests/App/Data/DataBase/DatabaseHelper.dart';
import 'dart:convert';

class AnalisisHistorico extends StatefulWidget {
  const AnalisisHistorico({super.key});

  @override
  State<AnalisisHistorico> createState() => _AnalisisHistoricoState();
}

class _AnalisisHistoricoState extends State<AnalisisHistorico> {
  List<Map<String, dynamic>> _analisis = [];
  bool _isLoading = true;
  String _filtroRiesgo = 'todos';

  @override
  void initState() {
    super.initState();
    _cargarAnalisis();
  }

  Future<void> _cargarAnalisis() async {
    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper.instance;
      List<Map<String, dynamic>> analisis;

      if (_filtroRiesgo == 'todos') {
        analisis = await dbHelper.getTodosLosAnalisis();
      } else {
        analisis = await dbHelper.getAnalisisPorRiesgo(_filtroRiesgo);
      }

      setState(() {
        _analisis = analisis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar análisis: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Análisis Histórico'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _filtroRiesgo = value);
              _cargarAnalisis();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todos', child: Text('Todos')),
              const PopupMenuItem(value: 'crítico', child: Text('🔴 Crítico')),
              const PopupMenuItem(value: 'alto', child: Text('🟠 Alto')),
              const PopupMenuItem(value: 'medio', child: Text('🟡 Medio')),
              const PopupMenuItem(value: 'bajo', child: Text('🟢 Bajo')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analisis.isEmpty
              ? const Center(child: Text('No hay análisis disponibles'))
              : ListView.builder(
                  itemCount: _analisis.length,
                  itemBuilder: (context, index) {
                    final analisis = _analisis[index];
                    return _buildAnalisisCard(analisis);
                  },
                ),
    );
  }

  Widget _buildAnalisisCard(Map<String, dynamic> analisis) {
    final emociones = jsonDecode(analisis['emociones']) as Map<String, dynamic>;
    final palabrasClave =
        jsonDecode(analisis['palabras_clave']) as List<dynamic>;

    Color colorRiesgo = _getColorRiesgo(analisis['nivel_riesgo']);

    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text(
            '${analisis['tema_general']} - ${_formatFecha(analisis['fecha_sesion'])}'),
        subtitle: Text(
            'Riesgo: ${analisis['nivel_riesgo']} (${analisis['puntuacion_riesgo']}%)'),
        leading: CircleAvatar(
          backgroundColor: colorRiesgo,
          child: Text(
            _getRiesgoIcon(analisis['nivel_riesgo']),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(analisis['resumen_analisis']),
                const SizedBox(height: 12),
                Text(
                  'Emociones detectadas:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                ...emociones.entries.where((e) => e.value > 0).map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(child: Text('${e.key}:')),
                            Text('${e.value.toStringAsFixed(1)}%'),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                if (palabrasClave.isNotEmpty) ...[
                  Text(
                    'Palabras clave:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Wrap(
                    spacing: 4,
                    children: palabrasClave
                        .map((palabra) => Chip(
                              label: Text(palabra.toString()),
                              backgroundColor: Colors.grey[200],
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorRiesgo(String nivel) {
    switch (nivel) {
      case 'crítico':
        return Colors.red;
      case 'alto':
        return Colors.orange;
      case 'medio':
        return Colors.yellow[700]!;
      case 'bajo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRiesgoIcon(String nivel) {
    switch (nivel) {
      case 'crítico':
        return '🔴';
      case 'alto':
        return '🟠';
      case 'medio':
        return '🟡';
      case 'bajo':
        return '🟢';
      default:
        return '⚪';
    }
  }

  String _formatFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return fecha;
    }
  }
}
