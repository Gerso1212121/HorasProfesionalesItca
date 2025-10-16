import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../App/Services/Service_Libros.dart';

class ConfiguracionIAScreen extends StatefulWidget {
  const ConfiguracionIAScreen({Key? key}) : super(key: key);

  @override
  State<ConfiguracionIAScreen> createState() => _ConfiguracionIAScreenState();
}

class _ConfiguracionIAScreenState extends State<ConfiguracionIAScreen> {
  final TextEditingController _comportamientoController =
      TextEditingController();
  final TextEditingController _reglasController = TextEditingController();
  final LibrosService _librosService = LibrosService();
  bool _cargando = false;
  String _baseConocimiento = '';

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
    _cargarLibros();
  }

  Future<void> _cargarLibros() async {
    setState(() => _cargando = true);

    await _librosService.cargarLibros();
    _baseConocimiento = _librosService.obtenerBaseConocimiento();

    setState(() => _cargando = false);
  }

  Future<void> _cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    _comportamientoController.text = prefs.getString('comportamiento_ia') ??
        '''Eres un asistente psicológico empático y profesional que:
- Utiliza un tono cálido y comprensivo
- Proporciona respuestas basadas en la psicología científica
- Ofrece herramientas prácticas para el desarrollo emocional
- Mantiene un enfoque ético y profesional
- Adapta su comunicación según las necesidades del usuario''';

    _reglasController.text = prefs.getString('reglas_ia') ??
        '''1. Siempre prioriza el bienestar emocional del usuario
2. No proporcionar diagnósticos médicos o psicológicos
3. Recomendar buscar ayuda profesional cuando sea necesario
4. Mantener confidencialidad y respeto
5. Usar lenguaje claro y accesible
6. Basar respuestas en evidencia científica
7. Fomentar la autoconciencia y el desarrollo personal''';
  }

  Future<void> _guardarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('comportamiento_ia', _comportamientoController.text);
    await prefs.setString('reglas_ia', _reglasController.text);

    // Generar y guardar el prompt personalizado
    String promptPersonalizado = _librosService.generarPromptPersonalizado(
        _comportamientoController.text, _reglasController.text);
    await prefs.setString('prompt_personalizado', promptPersonalizado);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada exitosamente')),
    );
  }

  void _mostrarVistaPrevia() {
    String prompt = _librosService.generarPromptPersonalizado(
        _comportamientoController.text, _reglasController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vista Previa del Prompt'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Base de Conocimiento:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${_librosService.libros.length} libros cargados'),
              const SizedBox(height: 16),
              const Text('Comportamiento:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_comportamientoController.text),
              const SizedBox(height: 16),
              const Text('Reglas:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_reglasController.text),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _mostrarVistaPrevia,
            tooltip: 'Vista previa del prompt',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Base de Conocimiento',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              '${_librosService.libros.length} libros de psicología cargados'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _librosService.libros.map((libro) {
                              return Chip(
                                label: Text(libro.archivo
                                    .split('/')
                                    .last
                                    .replaceAll('.json', '')),
                                backgroundColor: Colors.blue.shade100,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.settings, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'Comportamiento de la IA',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Define cómo debe comportarse la IA en las conversaciones:',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _comportamientoController,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText:
                                  'Describe el comportamiento deseado de la IA...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.rule, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Text(
                                'Reglas de Interacción',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Define las reglas que debe seguir la IA:',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _reglasController,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Define las reglas de interacción...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarConfiguracion,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Configuración'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _comportamientoController.dispose();
    _reglasController.dispose();
    super.dispose();
  }
}
