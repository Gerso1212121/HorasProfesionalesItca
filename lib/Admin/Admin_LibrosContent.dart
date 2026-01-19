import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:horas2/Backend/Data/librosservice.dart';
import 'package:horas2/Backend/Data/pdf.dart';

class LibrosContent extends StatefulWidget {
  const LibrosContent({super.key});

  @override
  State<LibrosContent> createState() => _LibrosContentState();
}

class _LibrosContentState extends State<LibrosContent> {
  final PDFProcessingService _pdfService = PDFProcessingService();
  // final LogService _logService = LogService();
  final LibrosService _librosService = LibrosService();
  List<Map<String, dynamic>> _libros = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String _searchQuery = '';
  String _filtroFuente = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadLibros();
  }

  Future<void> _loadLibros() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('🔄 Iniciando carga de libros...');
      final libros = await _librosService.obtenerTodosLosLibros();
      debugPrint('✅ Libros cargados: ${libros.length}');

      final locales = libros.where((l) => l['fuente'] == 'local').length;
      final firebase = libros.where((l) => l['fuente'] == 'firebase').length;
      debugPrint('📊 Desglose: Locales: $locales, Firebase: $firebase');

      setState(() {
        _libros = libros;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error al cargar libros: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      _showError('Error al cargar libros: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredLibros {
    List<Map<String, dynamic>> librosFiltrados = _libros;

    // Filtrar por fuente
    if (_filtroFuente != 'Todos') {
      librosFiltrados = librosFiltrados.where((libro) {
        final fuente = libro['fuente'] ?? 'firebase';
        return (_filtroFuente == 'Firebase' && fuente == 'firebase') ||
            (_filtroFuente == 'Locales' && fuente == 'local');
      }).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      librosFiltrados = librosFiltrados.where((libro) {
        return (libro['titulo']
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (libro['autor']
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (libro['categoria']
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);
      }).toList();
    }

    return librosFiltrados;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

void _mostrarDetallesLibro(Map<String, dynamic> libro) {
  final fuente = libro['fuente'] ?? 'firebase';
  final activo = libro['activo'] ?? false;
  final colorPrimario = fuente == 'local' ? Colors.blue : (activo ? Colors.green : Colors.blue);

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // --- HEADER ESTILIZADO ---
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorPrimario.withOpacity(0.8), colorPrimario],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderBadge(
                        fuente == 'local' ? Icons.folder : Icons.cloud,
                        fuente.toUpperCase(),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    libro['titulo'] ?? 'Sin título',
                    style: GoogleFonts.itim(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "por ${libro['autor'] ?? 'Autor Desconocido'}",
                    style: GoogleFonts.itim(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),

            // --- CUERPO SCROLLEABLE ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Grid de Stats rápidas
                    Row(
                      children: [
                        _buildStatCard(Icons.article_outlined, "Fragmentos", "${libro['fragmentos_originales'] ?? 0}"),
                        const SizedBox(width: 12),
                        _buildStatCard(Icons.category_outlined, "Categoría", libro['categoria'] ?? 'General'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sección: Descripción
                    _buildModernSection(
                      title: "Descripción del Libro",
                      icon: Icons.description_outlined,
                      child: Text(
                        libro['descripcion'] ?? 'Sin descripción disponible.',
                        style: GoogleFonts.itim(fontSize: 15, color: Colors.blueGrey[700], height: 1.5),
                      ),
                    ),

                    // Sección: Detalles Técnicos
                    _buildModernSection(
                      title: "Información Técnica",
                      icon: Icons.settings_outlined,
                      child: Column(
                        children: [
                          _buildDetailRow("ID Documento", libro['id'] ?? 'N/A'),
                          _buildDetailRow("Nombre Archivo", libro['archivo'] ?? 'N/A'),
                          _buildDetailRow("Creado el", _formatDate(libro['fechaCreacion'])),
                          _buildDetailRow("Modificado", _formatDate(libro['fechaModificacion'])),
                          _buildDetailRow("Estado", activo ? "Activo" : "Inactivo", 
                             isLast: true, color: activo ? Colors.green : Colors.red),
                        ],
                      ),
                    ),

                    // Sección: Fragmentos
                    if (libro['resumenes_por_fragmento'] != null)
                      _buildModernSection(
                        title: "Muestra de Fragmentos",
                        icon: Icons.auto_stories_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < (libro['resumenes_por_fragmento'] as List).length && i < 2; i++)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Text(
                                  "\"${_truncateText(libro['resumenes_por_fragmento'][i], 150)}\"",
                                  style: GoogleFonts.itim(fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                              ),
                             Text(
                               "Existen ${(libro['resumenes_por_fragmento'] as List).length} fragmentos procesados.",
                               style: GoogleFonts.itim(fontSize: 12, color: Colors.grey),
                             )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // --- ACTIONS ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Row(
                children: [
                  if (libro['puedeEliminar'] == true)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteLibro(libro['id'], libro['titulo'], fuente);
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: Text("ELIMINAR", style: GoogleFonts.itim(color: Colors.red, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  if (libro['puedeEliminar'] == true) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimario,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("CERRAR", style: GoogleFonts.itim(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// --- HELPERS DE DISEÑO ---

Widget _buildHeaderBadge(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.itim(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _buildStatCard(IconData icon, String label, String value) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.itim(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.itim(fontSize: 12, color: Colors.grey)),
        ],
      ),
    ),
  );
}

Widget _buildModernSection({required String title, required IconData icon, required Widget child}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.itim(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(height: 1),
        ),
        child,
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value, {bool isLast = false, Color? color}) {
  return Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.itim(color: Colors.grey[600], fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.itim(fontWeight: FontWeight.bold, fontSize: 13, color: color ?? Colors.blueGrey[900]),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.itim(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: GoogleFonts.itim(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.itim(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _subirPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile archivo = result.files.first;

        if (archivo.size > 500 * 1024 * 1024) {
          // 500MB límite
          _showError('El archivo es demasiado grande. Máximo 500MB.');
          return;
        }

        // Procesar automáticamente sin formulario
        await _procesarPDFAutomatico(archivo);
      }
    } catch (e) {
      _showError('Error seleccionando archivo: $e');
    }
  }

  // ignore: unused_element
  void _showPDFUploadDialog(PlatformFile archivo) {
    final nombreController =
        TextEditingController(text: archivo.name.replaceAll('.pdf', ''));
    final autorController = TextEditingController();
    final categoriaController = TextEditingController(text: 'General');
    final descripcionController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Subir Libro PDF',
          style: GoogleFonts.itim(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              archivo.name,
                              style:
                                  GoogleFonts.itim(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatFileSize(archivo.size),
                              style: GoogleFonts.itim(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Título del libro *',
                    prefixIcon: const Icon(Icons.book),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: autorController,
                  decoration: InputDecoration(
                    labelText: 'Autor *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoriaController,
                  decoration: InputDecoration(
                    labelText: 'Categoría *',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText:
                        'Ej: Psicología, Educación, Desarrollo Personal',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción *',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'Breve descripción del contenido del libro',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El procesamiento con IA puede tomar varios minutos dependiendo del tamaño del archivo.',
                          style: GoogleFonts.itim(
                              fontSize: 12, color: Colors.orange[800]),
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
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: GoogleFonts.itim()),
          ),
          ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () => _procesarPDF(
                      archivo,
                      nombreController.text.trim(),
                      autorController.text.trim(),
                      categoriaController.text.trim(),
                      descripcionController.text.trim(),
                    ),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6)),
            child: _isProcessing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Procesando...',
                          style: GoogleFonts.itim(color: Colors.white)),
                    ],
                  )
                : Text('Procesar PDF',
                    style: GoogleFonts.itim(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _procesarPDFAutomatico(PlatformFile archivo) async {
    setState(() => _isProcessing = true);

    try {
      // Extraer información automáticamente del nombre del archivo
      String autor = 'Autor Desconocido';
      String categoria = 'General';
      String descripcion =
          'Libro de psicología procesado automáticamente desde PDF.';

      final resultado = await _pdfService.procesarPDF(
        archivo: archivo,
        autor: autor,
        categoria: categoria,
        descripcion: descripcion,
      );

      if (resultado['success']) {
        _showSuccess(
            'Libro procesado exitosamente: ${resultado['fragmentos']} fragmentos creados');
        _loadLibros();
      } else {
        _showError(resultado['mensaje']);
      }
    } catch (e) {
      _showError('Error procesando PDF: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  String _extraerTituloDelArchivo(String nombreArchivo) {
    // Reemplazar guiones y guiones bajos con espacios
    String titulo = nombreArchivo.replaceAll('-', ' ').replaceAll('_', ' ');

    // Capitalizar cada palabra
    List<String> palabras = titulo.split(' ');
    palabras = palabras.map((palabra) {
      if (palabra.isEmpty) return palabra;
      return palabra[0].toUpperCase() + palabra.substring(1).toLowerCase();
    }).toList();

    return palabras.join(' ');
  }

  Future<void> _procesarPDF(
    PlatformFile archivo,
    String titulo,
    String autor,
    String categoria,
    String descripcion,
  ) async {
    if (titulo.isEmpty ||
        autor.isEmpty ||
        categoria.isEmpty ||
        descripcion.isEmpty) {
      _showError('Todos los campos son obligatorios');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final resultado = await _pdfService.procesarPDF(
        archivo: archivo,
        autor: autor,
        categoria: categoria,
        descripcion: descripcion,
      );

      if (resultado['success']) {
        _showSuccess(
            'Libro procesado exitosamente: ${resultado['fragmentos']} fragmentos creados');
        Navigator.of(context).pop();
        _loadLibros();
      } else {
        _showError(resultado['mensaje']);
      }
    } catch (e) {
      _showError('Error procesando PDF: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteLibro(String docId, String titulo, String fuente) async {
    if (fuente == 'local') {
      _showError(
          'No se pueden eliminar libros locales. Solo se pueden eliminar libros subidos a Firebase.');
      return;
    }

final result = await showDialog<bool>(
  context: context,
  builder: (context) => Dialog(
    // El insetPadding controla el ancho efectivo del diálogo
    insetPadding: EdgeInsets.symmetric(
      horizontal: MediaQuery.of(context).size.width * 0.40, // 25% a cada lado = 50% de ancho
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    backgroundColor: Colors.white,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          // Icono más pequeño para ajustarse al 50%
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_sweep_rounded, color: Colors.red[400], size: 24),
          ),
          const SizedBox(height: 12),
          
          Text(
            '¿Eliminar?',
            style: GoogleFonts.itim(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Confirmar borrado de "$titulo".',
            textAlign: TextAlign.center,
            style: GoogleFonts.itim(
              fontSize: 12,
              color: Colors.red[600],
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          
          // Botones en columna para que no se amontonen en un ancho del 50%
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Eliminar',
                    style: GoogleFonts.itim(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.itim(color: Colors.green[400], fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);

    if (result == true) {
      try {
        await _pdfService.eliminarLibro(docId);
        _showSuccess('Libro eliminado exitosamente de Firebase');
        _loadLibros();
      } catch (e) {
        _showError('Error al eliminar libro: $e');
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header con búsqueda, filtro y botón subir
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar libros por título, autor o categoría...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _filtroFuente,
                  onChanged: (value) => setState(() => _filtroFuente = value!),
                  decoration: InputDecoration(
                    labelText: 'Fuente',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(
                        value: 'Firebase', child: Text('Firebase')),
                    DropdownMenuItem(value: 'Locales', child: Text('Locales')),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _subirPDF,
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: Text('Subir PDF',
                    style: GoogleFonts.itim(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contador de libros
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Locales: ${_libros.where((l) => l['fuente'] == 'local').length}',
                      style: GoogleFonts.itim(
                          fontSize: 12, color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Firebase: ${_libros.where((l) => l['fuente'] == 'firebase').length}',
                      style: GoogleFonts.itim(
                          fontSize: 12, color: Colors.green[800]),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${_filteredLibros.length} libros',
                style: GoogleFonts.itim(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Indicador de procesamiento
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Procesando PDF con IA...',
                          style: GoogleFonts.itim(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    backgroundColor: Colors.blue[100],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Extrayendo texto, dividiendo en fragmentos y generando resúmenes...',
                    style: GoogleFonts.itim(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),

          // Lista de libros
          Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredLibros.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No hay libros disponibles'
                                    : 'No se encontraron libros',
                                style: GoogleFonts.itim(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Sube un PDF para comenzar',
                                  style: GoogleFonts.itim(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 Columnas
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent:
                                250, // Altura base aproximada de la tarjeta cerrada
                          ),
                          itemCount: _filteredLibros.length,
                          itemBuilder: (context, index) {
                            final libro = _filteredLibros[index];
                            final fechaCreacion =
                                _formatDate(libro['fechaCreacion']);
                            final fragmentos =
                                libro['fragmentos_originales'] ?? 0;
                            final activo = libro['activo'] ?? false;
                            final fuente = libro['fuente'] ?? 'firebase';
                            final puedeEliminar =
                                libro['puedeEliminar'] ?? false;

                            final Color statusColor = fuente == 'local'
                                ? Colors.blue[600]!
                                : (activo
                                    ? const Color(0xFF10B981)
                                    : Colors.green[400]!);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: SingleChildScrollView(
                                  // Para evitar overflow si el contenido crece
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Encabezado Superior (Icono y Menú)
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                fuente == 'local'
                                                    ? Icons.storage_rounded
                                                    : Icons.menu_book_rounded,
                                                color: statusColor,
                                                size: 20,
                                              ),
                                            ),
                                            _buildCardMenu(libro, puedeEliminar,
                                                fuente), // Menú desplegable
                                          ],
                                        ),
                                      ),

                                      // Título y Autor
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              libro['titulo'] ?? 'Sin título',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.itim(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            _buildMiniInfo(Icons.person_outline,
                                                libro['autor'] ?? 'N/A'),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // Badges de Estado y Fuente
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _buildStatusBadge(
                                              fuente == 'local'
                                                  ? 'LOCAL'
                                                  : (activo
                                                      ? 'ACTIVO'
                                                      : 'INACTIVO'),
                                              statusColor,
                                            ),
                                            if (fuente == 'firebase')
                                              _buildStatusBadge(
                                                  'CLOUD', Colors.indigo[400]!,
                                                  icon: Icons.cloud_queue),
                                          ],
                                        ),
                                      ),

                                      const Divider(height: 24, thickness: 0.5),

                                      // Info Inferior (Fragmentos y Fecha)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 0, 12, 12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildCompactData('Fragmentos',
                                                fragmentos.toString()),
                                            _buildCompactData(
                                                'Fecha',
                                                fechaCreacion.split(' ')[
                                                    0]), // Solo la fecha corta
                                          ],
                                        ),
                                      ),

                                      // Botón "Ver detalles" rápido al final
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          onPressed: () =>
                                              _mostrarDetallesLibro(libro),
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFF8FAFC),
                                            shape: const RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.zero),
                                          ),
                                          child: Text(
                                            'VER DETALLES',
                                            style: GoogleFonts.itim(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
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

// --- WIDGETS DE APOYO PARA EL DISEÑO ---

  Widget _buildIconLabel(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.itim(fontSize: 13, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }
// --- MÉTODOS AUXILIARES ---

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.green[400]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.itim(fontSize: 12, color: Colors.green[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 10, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.itim(
                fontSize: 9, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactData(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.itim(fontSize: 10, color: Colors.green[400])),
        Text(value,
            style: GoogleFonts.itim(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF334155))),
      ],
    );
  }

  Widget _buildCardMenu(
      Map<String, dynamic> libro, bool puedeEliminar, String fuente) {
    return PopupMenuButton(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () =>
              Future.delayed(Duration.zero, () => _mostrarDetallesLibro(libro)),
          child: Text('Detalles', style: GoogleFonts.itim(fontSize: 13)),
        ),
        if (puedeEliminar)
          PopupMenuItem(
            onTap: () => Future.delayed(Duration.zero,
                () => _deleteLibro(libro['id'], libro['titulo'], fuente)),
            child: Text('Eliminar',
                style: GoogleFonts.itim(fontSize: 13, color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildTechnicalInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.itim(fontSize: 10, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.itim(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
