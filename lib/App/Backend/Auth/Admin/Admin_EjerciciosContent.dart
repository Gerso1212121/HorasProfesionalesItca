import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Data/DataBase/DatabaseHelper.dart';
import '../../../Data/Models/ejercicio_model.dart';
import '../../../Services/Services_Ejercicios.dart';
import 'Logic/Admin_AuditService.dart';
import '../../../Utils/Utils_ServiceLog.dart';

class EjerciciosContent extends StatefulWidget {
  const EjerciciosContent({super.key});

  @override
  State<EjerciciosContent> createState() => _EjerciciosContentState();
}

class _EjerciciosContentState extends State<EjerciciosContent> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _ejercicios = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEjercicios();
  }

  Future<void> _loadEjercicios() async {
    setState(() => _isLoading = true);
    try {
      // Usar el método de DatabaseHelper que sincroniza con Supabase
      final ejercicios = await _databaseHelper.readEjercicios();
      setState(() {
        _ejercicios = ejercicios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar ejercicios: $e');
      LogService.log('Error al cargar ejercicios: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredEjercicios {
    if (_searchQuery.isEmpty) return _ejercicios;
    return _ejercicios.where((ejercicio) {
      final titulo = ejercicio['titulo']?.toString().toLowerCase() ?? '';
      final descripcion =
          ejercicio['descripcion']?.toString().toLowerCase() ?? '';
      final categoria = ejercicio['categoria']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return titulo.contains(query) ||
          descripcion.contains(query) ||
          categoria.contains(query);
    }).toList();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteEjercicio(int id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar eliminación',
          style: GoogleFonts.itim(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar este ejercicio?',
          style: GoogleFonts.itim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: GoogleFonts.itim()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                Text('Eliminar', style: GoogleFonts.itim(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        // Usar el método de DatabaseHelper para eliminar de Supabase
        final success = await _databaseHelper.deleteEjercicio(id);
        if (success) {
          _showSuccess('Ejercicio eliminado exitosamente');
          AuditService.logAction(
            tableName: 'ejercicios',
            action: 'DELETE',
            recordId: id.toString(),
            oldValues: _ejercicios.firstWhere(
                (ejercicio) => ejercicio['id_ejercicio'] == id,
                orElse: () => {}),
            details: 'Eliminación de ejercicio',
          );
          await _loadEjercicios(); // Recargar datos desde Supabase

          // Limpiar caché del servicio
          EjerciciosService().clearCache();
        } else {
          LogService.log('Error al eliminar ejercicio');
          throw Exception('No se pudo eliminar el ejercicio');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Error al eliminar ejercicio: $e');
        LogService.log('Error al eliminar ejercicio: $e');
      }
    }
  }

  void _showEjercicioDialog({Map<String, dynamic>? ejercicio}) {
    // Listas para objetivos e instrucciones
    List<String> objetivos = [];
    List<String> instrucciones = [];

    final isEditing = ejercicio != null;
    final titleController =
        TextEditingController(text: ejercicio?['titulo'] ?? '');
    final descripcionController =
        TextEditingController(text: ejercicio?['descripcion'] ?? '');
    final duracionController = TextEditingController(
        text: ejercicio?['duracion_minutos']?.toString() ?? '');
    final objetivosController =
        TextEditingController(text: ejercicio?['objetivos'] ?? '');
    final instruccionesController =
        TextEditingController(text: ejercicio?['instrucciones'] ?? '');

    // Variables para dropdowns
    CategoriaEjercicio? selectedCategoria;
    TipoEjercicio? selectedTipo;
    NivelDificultad? selectedDificultad;
    // Inicializar listas desde los datos existentes
    if (ejercicio != null) {
      if (ejercicio['objetivos'] != null) {
        objetivos = ejercicio['objetivos']
            .split('|')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (ejercicio['instrucciones'] != null) {
        instrucciones = ejercicio['instrucciones']
            .split('|')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    // Inicializar valores seleccionados para edición
    if (ejercicio != null) {
      // Encontrar categoría
      try {
        selectedCategoria = CategoriaEjercicio.values.firstWhere(
          (cat) => cat.nombre == ejercicio['categoria'],
        );
      } catch (e) {
        LogService.log('Categoría no encontrada: ${ejercicio['categoria']}');
        selectedCategoria = null;
      }

      // Encontrar tipo
      try {
        selectedTipo = TipoEjercicio.values.firstWhere(
          (tipo) => tipo.name == ejercicio['tipo'],
        );
      } catch (e) {
        LogService.log('Tipo no encontrado: ${ejercicio['tipo']}');
        selectedTipo = null;
      }

      // Encontrar dificultad
      try {
        selectedDificultad = NivelDificultad.values.firstWhere(
          (dif) => dif.name == ejercicio['dificultad'],
        );
      } catch (e) {
        LogService.log('Dificultad no encontrada: ${ejercicio['dificultad']}');
        selectedDificultad = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEditing ? 'Editar Ejercicio' : 'Nuevo Ejercicio',
            style: GoogleFonts.itim(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 600, // Aumentar ancho para mejor visualización
            height: 600, // Altura fija para scroll
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título (obligatorio)
                  _buildTextField(titleController, 'Título *', Icons.title),
                  const SizedBox(height: 16),

                  // Descripción
                  _buildTextField(
                      descripcionController, 'Descripción', Icons.description,
                      maxLines: 3),
                  const SizedBox(height: 16),

                  // Categoría (Dropdown)
                  _buildDropdown<CategoriaEjercicio>(
                    value: selectedCategoria,
                    label: 'Categoría',
                    icon: Icons.category,
                    items: CategoriaEjercicio.values,
                    itemBuilder: (categoria) => categoria.nombre,
                    onChanged: (value) =>
                        setDialogState(() => selectedCategoria = value),
                  ),
                  const SizedBox(height: 16),

                  // Tipo (Dropdown obligatorio)
                  _buildDropdown<TipoEjercicio>(
                    value: selectedTipo,
                    label: 'Tipo *',
                    icon: Icons.fitness_center,
                    items: TipoEjercicio.values,
                    itemBuilder: (tipo) => tipo.nombre,
                    onChanged: (value) =>
                        setDialogState(() => selectedTipo = value),
                  ),
                  const SizedBox(height: 16),

                  // Duración
                  _buildTextField(
                      duracionController, 'Duración (minutos)', Icons.timer,
                      isNumber: true),
                  const SizedBox(height: 16),

                  // Dificultad (Dropdown)
                  _buildDropdown<NivelDificultad>(
                    value: selectedDificultad,
                    label: 'Dificultad',
                    icon: Icons.bar_chart,
                    items: NivelDificultad.values,
                    itemBuilder: (dificultad) => dificultad.nombre,
                    onChanged: (value) =>
                        setDialogState(() => selectedDificultad = value),
                  ),
                  const SizedBox(height: 16),

                  DynamicListField(
                    label: 'Objetivos',
                    icon: Icons.flag,
                    initialItems: objetivos,
                    hintText: 'Ej: Mejorar autoestima y reducir ansiedad',
                    onChanged: (items) => objetivos = items,
                  ),

                  const SizedBox(height: 16),

                  // Instrucciones con lista dinámica
                  DynamicListField(
                    label: 'Instrucciones',
                    icon: Icons.list_alt,
                    initialItems: instrucciones,
                    hintText:
                        'Ej: 1. Encuentra un lugar tranquilo\n2. Siéntate cómodamente',
                    onChanged: (items) => instrucciones = items,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: GoogleFonts.itim()),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validaciones
                if (titleController.text.trim().isEmpty) {
                  _showError('El título es obligatorio');
                  return;
                }
                if (selectedTipo == null) {
                  _showError('El tipo es obligatorio');
                  return;
                }

                // Validar duración si se proporciona
                int? duracion;
                if (duracionController.text.trim().isNotEmpty) {
                  duracion = int.tryParse(duracionController.text.trim());
                  if (duracion == null || duracion <= 0) {
                    _showError('La duración debe ser un número positivo');
                    return;
                  }
                }

                Navigator.of(context).pop(); // Cerrar diálogo primero
                setState(() => _isLoading = true);

                try {
                  if (isEditing) {
                    // Actualizar ejercicio existente
                    final updateData = {
                      'titulo': titleController.text.trim(),
                      'descripcion': descripcionController.text.trim().isEmpty
                          ? null
                          : descripcionController.text.trim(),
                      'categoria': selectedCategoria?.nombre,
                      'tipo': selectedTipo!.name,
                      'duracion_minutos': duracion,
                      'dificultad': selectedDificultad?.name,
                      'objetivos':
                          objetivos.isEmpty ? null : objetivos.join('|'),
                      'instrucciones': instrucciones.isEmpty
                          ? null
                          : instrucciones.join('|'),
                    };

                    final success = await _databaseHelper.updateEjercicio(
                        ejercicio['id_ejercicio'], updateData);

                    if (success) {
                      _showSuccess('Ejercicio actualizado exitosamente');
                      AuditService.logAction(
                        tableName: 'ejercicios',
                        action: 'UPDATE',
                        recordId: ejercicio['id_ejercicio'].toString(),
                        oldValues: ejercicio,
                        newValues: {
                          'titulo': titleController.text.trim(),
                          'descripcion':
                              descripcionController.text.trim().isEmpty
                                  ? null
                                  : descripcionController.text.trim(),
                          'categoria': selectedCategoria?.nombre,
                          'tipo': selectedTipo!.name,
                          'duracion_minutos': duracion,
                          'dificultad': selectedDificultad?.name,
                          'objetivos':
                              objetivos.isEmpty ? null : objetivos.join('|'),
                          'instrucciones': instrucciones.isEmpty
                              ? null
                              : instrucciones.join('|'),
                        },
                        details: 'Actualización de ejercicio existente',
                      );
                    } else {
                      LogService.log('Error al actualizar ejercicio');
                      throw Exception('No se pudo actualizar el ejercicio');
                    }
                  } else {
                    // Crear nuevo ejercicio
                    final result = await _databaseHelper.createEjercicio(
                      titulo: titleController.text.trim(),
                      descripcion: descripcionController.text.trim().isEmpty
                          ? null
                          : descripcionController.text.trim(),
                      categoria: selectedCategoria?.nombre,
                      tipo: selectedTipo!.name,
                      duracionMinutos: duracion,
                      dificultad: selectedDificultad?.name,
                      objetivos: objetivos.isEmpty ? null : objetivos.join('|'),
                      instrucciones: instrucciones.isEmpty
                          ? null
                          : instrucciones.join('|'),
                    );

                    if (result != null) {
                      _showSuccess('Ejercicio creado exitosamente');
                      AuditService.logAction(
                        tableName: 'ejercicios',
                        action: 'CREATE',
                        recordId: 'new', // Temporal, ya que es nuevo
                        newValues: {
                          'titulo': titleController.text.trim(),
                          'descripcion':
                              descripcionController.text.trim().isEmpty
                                  ? null
                                  : descripcionController.text.trim(),
                          'categoria': selectedCategoria?.nombre,
                          'tipo': selectedTipo!.name,
                          'duracion_minutos': duracion,
                          'dificultad': selectedDificultad?.name,
                          'objetivos':
                              objetivos.isEmpty ? null : objetivos.join('|'),
                          'instrucciones': instrucciones.isEmpty
                              ? null
                              : instrucciones.join('|'),
                        },
                        details: 'Creación de nuevo ejercicio',
                      );
                    } else {
                      LogService.log('Error al crear ejercicio');
                      throw Exception('No se pudo crear el ejercicio');
                    }
                  }

                  // Recargar datos y limpiar caché
                  await _loadEjercicios();
                  EjerciciosService().clearCache();
                } catch (e) {
                  setState(() => _isLoading = false);

                  _showError(
                      'Error al ${isEditing ? 'actualizar' : 'crear'} ejercicio: $e');
                }
              },
              child: Text(
                isEditing ? 'Actualizar' : 'Crear',
                style: GoogleFonts.itim(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<T> items,
    required String Function(T) itemBuilder,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemBuilder(item)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Color _getColorFromTipo(String? tipo) {
    if (tipo == null) return Colors.blue;
    try {
      return TipoEjercicio.values.firstWhere((t) => t.name == tipo).color;
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconFromTipo(String? tipo) {
    if (tipo == null) return Icons.fitness_center;
    try {
      return TipoEjercicio.values.firstWhere((t) => t.name == tipo).icono;
    } catch (e) {
      return Icons.fitness_center;
    }
  }

  Color _getColorFromDificultad(String? dificultad) {
    if (dificultad == null) return Colors.grey;
    try {
      return NivelDificultad.values
          .firstWhere((d) => d.name == dificultad)
          .color;
    } catch (e) {
      return Colors.grey;
    }
  }

  String _getNombreFromTipo(String? tipo) {
    if (tipo == null) return 'Sin tipo';
    try {
      return TipoEjercicio.values.firstWhere((t) => t.name == tipo).nombre;
    } catch (e) {
      return tipo;
    }
  }

  String _getNombreFromDificultad(String? dificultad) {
    if (dificultad == null) return 'Sin dificultad';
    try {
      return NivelDificultad.values
          .firstWhere((d) => d.name == dificultad)
          .nombre;
    } catch (e) {
      LogService.log('Dificultad no encontrada: $dificultad');
      return dificultad;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header con búsqueda y botón crear
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar ejercicios...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showEjercicioDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('Nuevo Ejercicio',
                    style: GoogleFonts.itim(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lista de ejercicios
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEjercicios.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay ejercicios disponibles'
                                  : 'No se encontraron ejercicios',
                              style: GoogleFonts.itim(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredEjercicios.length,
                        itemBuilder: (context, index) {
                          final ejercicio = _filteredEjercicios[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getColorFromTipo(ejercicio['tipo']),
                                child: Icon(
                                  _getIconFromTipo(ejercicio['tipo']),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                ejercicio['titulo'] ?? 'Sin título',
                                style: GoogleFonts.itim(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (ejercicio['descripcion'] != null)
                                    Text(
                                      ejercicio['descripcion'],
                                      style: GoogleFonts.itim(fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (ejercicio['tipo'] != null)
                                        Chip(
                                          label: Text(
                                            _getNombreFromTipo(
                                                ejercicio['tipo']),
                                            style:
                                                GoogleFonts.itim(fontSize: 10),
                                          ),
                                          backgroundColor: _getColorFromTipo(
                                                  ejercicio['tipo'])
                                              .withOpacity(0.1),
                                        ),
                                      if (ejercicio['duracion_minutos'] != null)
                                        Chip(
                                          label: Text(
                                            '${ejercicio['duracion_minutos']} min',
                                            style:
                                                GoogleFonts.itim(fontSize: 10),
                                          ),
                                          backgroundColor: Colors.green[100],
                                        ),
                                      if (ejercicio['dificultad'] != null)
                                        Chip(
                                          label: Text(
                                            _getNombreFromDificultad(
                                                ejercicio['dificultad']),
                                            style:
                                                GoogleFonts.itim(fontSize: 10),
                                          ),
                                          backgroundColor:
                                              _getColorFromDificultad(
                                                      ejercicio['dificultad'])
                                                  .withOpacity(0.1),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit, size: 16),
                                        const SizedBox(width: 8),
                                        Text('Editar',
                                            style: GoogleFonts.itim()),
                                      ],
                                    ),
                                    onTap: () => Future.delayed(
                                      Duration.zero,
                                      () => _showEjercicioDialog(
                                          ejercicio: ejercicio),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete,
                                            size: 16, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Text('Eliminar',
                                            style: GoogleFonts.itim(
                                                color: Colors.red)),
                                      ],
                                    ),
                                    onTap: () => Future.delayed(
                                      Duration.zero,
                                      () => _deleteEjercicio(
                                          ejercicio['id_ejercicio']),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class DynamicListField extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<String> initialItems;
  final Function(List<String>) onChanged;
  final String hintText;

  const DynamicListField({
    Key? key,
    required this.label,
    required this.icon,
    required this.initialItems,
    required this.onChanged,
    required this.hintText,
  }) : super(key: key);

  @override
  State<DynamicListField> createState() => _DynamicListFieldState();
}

class _DynamicListFieldState extends State<DynamicListField> {
  late List<TextEditingController> _controllers;
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
    if (_items.isEmpty) _items.add(''); // Al menos un campo vacío

    _controllers =
        _items.map((item) => TextEditingController(text: item)).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() {
      _items.add('');
      _controllers.add(TextEditingController());
    });
  }

  void _removeField(int index) {
    if (_controllers.length > 1) {
      setState(() {
        _controllers[index].dispose();
        _controllers.removeAt(index);
        _items.removeAt(index);
        _updateParent();
      });
    }
  }

  void _updateParent() {
    final validItems = _controllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    widget.onChanged(validItems);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.itim(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controllers[index],
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) => _updateParent(),
                  ),
                ),
                const SizedBox(width: 8),
                if (_controllers.length > 1)
                  IconButton(
                    onPressed: () => _removeField(index),
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addField,
          icon: const Icon(Icons.add, size: 16),
          label: Text(
            'Agregar ${widget.label.toLowerCase()}',
            style: GoogleFonts.itim(fontSize: 12),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }
}
