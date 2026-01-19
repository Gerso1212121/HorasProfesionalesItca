import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Backend/Data/ejercicios.dart';
import 'package:horas2/Backend/Data/modalejercicio.dart';
import 'package:horas2/DB/DatabaseHelper.dart';
import 'Logic/Admin_AuditService.dart';

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
      print('Error al cargar ejercicios: $e');
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

  // --- FUNCIÓN DE ELIMINACIÓN ---
Future<void> _deleteEjercicio(int id) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Text(
            'Confirmar eliminación',
            style: GoogleFonts.itim(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        '¿Estás seguro de que deseas eliminar este ejercicio? Esta acción no se puede deshacer.',
        style: GoogleFonts.itim(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancelar', style: GoogleFonts.itim(color: Colors.grey[700])),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Eliminar', style: GoogleFonts.itim(color: Colors.white)),
        ),
      ],
    ),
  );

  if (result == true) {
    setState(() => _isLoading = true);
    try {
      final success = await _databaseHelper.deleteEjercicio(id);
      if (success) {
        _showSuccess('Ejercicio eliminado exitosamente');
        AuditService.logAction(
          tableName: 'ejercicios',
          action: 'DELETE',
          recordId: id.toString(),
          oldValues: _ejercicios.firstWhere(
            (ejercicio) => ejercicio['id_ejercicio'] == id,
            orElse: () => {},
          ),
          details: 'Eliminación de ejercicio',
        );
        await _loadEjercicios();
        EjerciciosService().clearCache();
      } else {
        throw Exception('No se pudo eliminar el ejercicio');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al eliminar: $e');
    }
  }
}

// --- FORMULARIO COMPLETO (CREAR / EDITAR) ---
void _showEjercicioDialog({Map<String, dynamic>? ejercicio}) {
  List<String> objetivos = [];
  List<String> instrucciones = [];
  final isEditing = ejercicio != null;

  // Controllers
  final titleController = TextEditingController(text: ejercicio?['titulo'] ?? '');
  final descripcionController = TextEditingController(text: ejercicio?['descripcion'] ?? '');
  final duracionController = TextEditingController(text: ejercicio?['duracion_minutos']?.toString() ?? '');

  // Dropdowns
  CategoriaEjercicio? selectedCategoria;
  TipoEjercicio? selectedTipo;
  NivelDificultad? selectedDificultad;

  // Inicialización de datos
  if (isEditing) {
    if (ejercicio['objetivos'] != null) {
      objetivos = ejercicio['objetivos'].toString().split('|').where((s) => s.isNotEmpty).toList();
    }
    if (ejercicio['instrucciones'] != null) {
      instrucciones = ejercicio['instrucciones'].toString().split('|').where((s) => s.isNotEmpty).toList();
    }
    try {
      selectedCategoria = CategoriaEjercicio.values.firstWhere((c) => c.nombre == ejercicio['categoria']);
    } catch (_) {}
    try {
      selectedTipo = TipoEjercicio.values.firstWhere((t) => t.name == ejercicio['tipo']);
    } catch (_) {}
    try {
      selectedDificultad = NivelDificultad.values.firstWhere((d) => d.name == ejercicio['dificultad']);
    } catch (_) {}
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Row(
            children: [
              Icon(isEditing ? Icons.edit_note : Icons.add_circle_outline, 
                   color: Theme.of(context).primaryColor, size: 28),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Editar Ejercicio' : 'Nuevo Ejercicio',
                style: GoogleFonts.itim(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 600,
          height: 600,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('INFORMACIÓN BÁSICA'),
                _buildTextField(titleController, 'Título *', Icons.title),
                const SizedBox(height: 16),
                _buildTextField(descripcionController, 'Descripción', Icons.description_outlined, maxLines: 3),
                
                const SizedBox(height: 24),
                _buildSectionHeader('DETALLES TÉCNICOS'),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<CategoriaEjercicio>(
                        value: selectedCategoria,
                        label: 'Categoría',
                        icon: Icons.category_outlined,
                        items: CategoriaEjercicio.values,
                        itemBuilder: (c) => c.nombre,
                        onChanged: (v) => setDialogState(() => selectedCategoria = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown<TipoEjercicio>(
                        value: selectedTipo,
                        label: 'Tipo *',
                        icon: Icons.fitness_center,
                        items: TipoEjercicio.values,
                        itemBuilder: (t) => t.nombre,
                        onChanged: (v) => setDialogState(() => selectedTipo = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(duracionController, 'Duración (min)', Icons.timer_outlined, isNumber: true),
                const SizedBox(height: 16),
                _buildDropdown<NivelDificultad>(
                  value: selectedDificultad,
                  label: 'Dificultad',
                  icon: Icons.bar_chart_rounded,
                  items: NivelDificultad.values,
                  itemBuilder: (d) => d.nombre,
                  onChanged: (v) => setDialogState(() => selectedDificultad = v),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('CONTENIDO'),
                DynamicListField(
                  label: 'Objetivos',
                  icon: Icons.flag_outlined,
                  initialItems: objetivos,
                  hintText: 'Ej: Reducir estrés',
                  onChanged: (items) => objetivos = items,
                ),
                const SizedBox(height: 16),
                DynamicListField(
                  label: 'Instrucciones',
                  icon: Icons.list_alt_rounded,
                  initialItems: instrucciones,
                  hintText: 'Ej: 1. Respira profundo...',
                  onChanged: (items) => instrucciones = items,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: GoogleFonts.itim(fontSize: 16, color: Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                _showError('El título es obligatorio'); return;
              }
              if (selectedTipo == null) {
                _showError('El tipo es obligatorio'); return;
              }

              int? duracion;
              if (duracionController.text.trim().isNotEmpty) {
                duracion = int.tryParse(duracionController.text.trim());
                if (duracion == null || duracion <= 0) {
                  _showError('Duración inválida'); return;
                }
              }

              final Map<String, dynamic> data = {
                'titulo': titleController.text.trim(),
                'descripcion': descripcionController.text.trim().isEmpty ? null : descripcionController.text.trim(),
                'categoria': selectedCategoria?.nombre,
                'tipo': selectedTipo!.name,
                'duracion_minutos': duracion,
                'dificultad': selectedDificultad?.name,
                'objetivos': objetivos.isEmpty ? null : objetivos.join('|'),
                'instrucciones': instrucciones.isEmpty ? null : instrucciones.join('|'),
              };

              Navigator.of(context).pop();
              setState(() => _isLoading = true);

              try {
                if (isEditing) {
                  final success = await _databaseHelper.updateEjercicio(ejercicio['id_ejercicio'], data);
                  if (success) {
                    _showSuccess('Ejercicio actualizado');
                    AuditService.logAction(
                      tableName: 'ejercicios', action: 'UPDATE',
                      recordId: ejercicio['id_ejercicio'].toString(),
                      oldValues: ejercicio, newValues: data,
                      details: 'Actualización de ejercicio',
                    );
                  }
                } else {
                  final result = await _databaseHelper.createEjercicio(
                    titulo: data['titulo'], descripcion: data['descripcion'],
                    categoria: data['categoria'], tipo: data['tipo'],
                    duracionMinutos: data['duracion_minutos'],
                    dificultad: data['dificultad'],
                    objetivos: data['objetivos'], instrucciones: data['instrucciones'],
                  );
                  if (result != null) {
                    _showSuccess('Ejercicio creado');
                    AuditService.logAction(
                      tableName: 'ejercicios', action: 'CREATE',
                      recordId: 'new', newValues: data,
                      details: 'Creación de ejercicio',
                    );
                  }
                }
                await _loadEjercicios();
                EjerciciosService().clearCache();
              } catch (e) {
                setState(() => _isLoading = false);
                _showError('Error: $e');
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear', 
                        style: GoogleFonts.itim(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

// Helper para títulos de sección
Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: GoogleFonts.itim(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey[400],
        letterSpacing: 1.1,
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
      print('Dificultad no encontrada: $dificultad');
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
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          // Definimos las 3 columnas
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent:
                                170, // Altura fija para que todas las tarjetas sean iguales
                          ),
                          itemCount: _filteredEjercicios.length,
                          itemBuilder: (context, index) {
                            final ejercicio = _filteredEjercicios[index];
                            final colorTipo =
                                _getColorFromTipo(ejercicio['tipo']);

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Colors.grey.withOpacity(0.2)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    _showEjercicioDialog(ejercicio: ejercicio),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Fila superior: Icono y Menú
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: colorTipo.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getIconFromTipo(
                                                  ejercicio['tipo']),
                                              color: colorTipo,
                                              size: 20,
                                            ),
                                          ),
                                          _buildPopupMenu(context, ejercicio),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Título
                                      Text(
                                        ejercicio['titulo'] ?? 'Sin título',
                                        style: GoogleFonts.itim(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),

                                      // Descripción
                                      Expanded(
                                        child: Text(
                                          ejercicio['descripcion'] ?? '',
                                          style: GoogleFonts.itim(
                                            fontSize: 12,
                                            color: Colors.black54,
                                            height: 1.1,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Badges (solo los esenciales para no saturar)
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: [
                                          _buildBadge(
                                            _getNombreFromTipo(
                                                ejercicio['tipo']),
                                            colorTipo,
                                          ),
                                          if (ejercicio['duracion_minutos'] !=
                                              null)
                                            _buildBadge(
                                              '${ejercicio['duracion_minutos']}m',
                                              Colors.green,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )),
        ],
      ),
    );
  }

// --- Métodos de soporte para limpiar el código ---

  Widget _buildBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.itim(
              fontSize: 11,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, dynamic ejercicio) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (value) {
        if (value == 'edit') {
          _showEjercicioDialog(ejercicio: ejercicio);
        } else if (value == 'delete') {
          _deleteEjercicio(ejercicio['id_ejercicio']);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 10),
              Text('Editar', style: GoogleFonts.itim()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              const SizedBox(width: 10),
              Text('Eliminar', style: GoogleFonts.itim(color: Colors.red)),
            ],
          ),
        ),
      ],
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
