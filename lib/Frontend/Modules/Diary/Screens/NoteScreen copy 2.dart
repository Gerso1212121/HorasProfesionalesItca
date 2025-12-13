import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/Diary/Screens/DrawingBoard.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// NoteScreen - Editor de notas con diseño elegante
class NoteScreen extends StatefulWidget {
  static const routeName = '/note';

  const NoteScreen({super.key});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  late final QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final _selectedDateController = StreamController<DateTime>.broadcast();
  final _selectedMoodController = StreamController<String>.broadcast();
  List<String> availableMoods = [
    '😊',
    '😂',
    '🥰',
    '😎',
    '🤔',
    '😴',
    '👍',
    '❤️',
    '🔥',
    '⭐'
  ];

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _titleController.text = 'Mi entrada del día';

    // Inicializar fecha actual
    _selectedDateController.add(DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();

    _selectedDateController.close();
    _selectedMoodController.close();
  }

  String _getMonthAbbreviation(int month) {
    switch (month) {
      case 1:
        return 'ENE';
      case 2:
        return 'FEB';
      case 3:
        return 'MAR';
      case 4:
        return 'ABR';
      case 5:
        return 'MAY';
      case 6:
        return 'JUN';
      case 7:
        return 'JUL';
      case 8:
        return 'AGO';
      case 9:
        return 'SEP';
      case 10:
        return 'OCT';
      case 11:
        return 'NOV';
      case 12:
        return 'DIC';
      default:
        return '';
    }
  }

  void _showDatePicker() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4285F4),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A237E),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      _selectedDateController.add(selectedDate);
    }
  }

  void _showMoodSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Cómo te sientes hoy?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: availableMoods.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _selectedMoodController.add(availableMoods[index]);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          availableMoods[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: const Color(0xFF1A237E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nueva entrada',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A237E),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: _buildSaveButton(),
          ),
        ],
      ),
      body: QuillProvider(
        configurations: QuillConfigurations(
          controller: _controller,
          sharedConfigurations: const QuillSharedConfigurations(
            locale: Locale('es'),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Selector de fecha y estado de ánimo
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Selector de fecha abreviada
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Botón para abrir selector de fecha
                          GestureDetector(
                            onTap: _showDatePicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4285F4),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  // Fecha abreviada
                                  StreamBuilder<DateTime>(
                                    stream: _selectedDateController.stream,
                                    initialData: DateTime.now(),
                                    builder: (context, snapshot) {
                                      final date =
                                          snapshot.data ?? DateTime.now();
                                      return Text(
                                        '${date.day} ${_getMonthAbbreviation(date.month).toUpperCase()}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Selector de estado de ánimo con emoji
                    GestureDetector(
                      onTap: _showMoodSelector,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFD2E3FC),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: StreamBuilder<String>(
                            stream: _selectedMoodController.stream,
                            initialData: '😊',
                            builder: (context, snapshot) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  snapshot.data ?? '😊',
                                  key: ValueKey<String>(snapshot.data ?? '😊'),
                                  style: const TextStyle(fontSize: 24),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Campo de título
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: TextField(
                  controller: _titleController,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A237E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Título de la entrada',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _focusNode.requestFocus(),
                ),
              ),

              // Editor de texto
              // Editor de texto - REMOVER EL Expanded
              Container(
                color: Colors.white,
                constraints: BoxConstraints(
                  minHeight: 300, // Altura mínima
                  maxHeight: MediaQuery.of(context)
                      .size
                      .height, // Altura máxima flexible
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: QuillEditor(
                    configurations: QuillEditorConfigurations(
                      scrollable: false, // CAMBIAR A FALSE
                      autoFocus: false,
                      readOnly: false,
                      expands: false, // CAMBIAR A FALSE
                      padding: const EdgeInsets.only(bottom: 100),
                      placeholder:
                          'Escribe aquí tus pensamientos, reflexiones o momentos especiales del día...',
                      embedBuilders: [
                        AppImageEmbedBuilder(),
                      ],
                      scrollBottomInset: 100,
                      customStyleBuilder: (Attribute attribute) {
                        // Estilo base
                        final baseStyle = TextStyle(
                          fontSize: 16,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          height: 1.6,
                          color: const Color(0xFF1A237E),
                        );

                        // Solo aplicar estilo específico para atributos de tamaño
                        if (attribute.key == Attribute.size.key) {
                          return baseStyle;
                        }

                        // Para otros atributos
                        if (attribute.key == Attribute.bold.key) {
                          return baseStyle.copyWith(
                              fontWeight: FontWeight.bold);
                        }

                        if (attribute.key == Attribute.italic.key) {
                          return baseStyle.copyWith(
                              fontStyle: FontStyle.italic);
                        }

                        return baseStyle; // Siempre retorna un estilo válido
                      },
                    ),
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: QuillToolbar(
                  configurations: QuillToolbarConfigurations(
                    // Configuración de visibilidad de botones
                    showBoldButton: true,
                    showItalicButton: false,
                    showUnderLineButton: false,
                    showStrikeThrough: false,
                    showColorButton: true,
                    showBackgroundColorButton: false,
                    showClearFormat: false,
                    showAlignmentButtons: true,
                    showLeftAlignment: true,
                    showCenterAlignment: true,
                    showRightAlignment: true,
                    showJustifyAlignment: false,
                    showHeaderStyle: true,
                    showListNumbers: true,
                    showListBullets: true,
                    showListCheck: false,
                    showCodeBlock: false,
                    showQuote: true,
                    showIndent: false,
                    showLink: true,
                    showUndo: true,
                    showRedo: true,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showFontFamily: false,
                    showFontSize: false,
                    showSmallButton: false,
                    showInlineCode: false,
                    showDirection: false,

                    // Botones personalizados para emoji, imagen y dibujo
                    customButtons: [
                      QuillToolbarCustomButtonOptions(
                        icon: Icon(
                          Icons.image_rounded,
                          size: 20,
                          color: const Color(0xFF5A5A5A),
                        ),
                        tooltip: 'Insertar imagen',
                        onPressed: _showImageOptions,
                      ),
                      QuillToolbarCustomButtonOptions(
                        icon: Icon(
                          Icons.emoji_emotions_rounded,
                          size: 20,
                          color: const Color(0xFF5A5A5A),
                        ),
                        tooltip: 'Insertar emoji',
                        onPressed: _insertEmoji,
                      ),
                    ],

                    // Opciones de botones
                    buttonOptions: QuillToolbarButtonOptions(
                      base: const QuillToolbarBaseButtonOptions(
                        globalIconSize: 20,
                        globalIconButtonFactor: 1.77,
                      ),
                      bold: QuillToolbarToggleStyleButtonOptions(
                        iconData: Icons.format_bold_rounded,
                        iconSize: 20,
                        fillColor: const Color(0xFFE8F0FE),
                      ),
                      italic: QuillToolbarToggleStyleButtonOptions(
                        iconData: Icons.format_italic_rounded,
                        iconSize: 20,
                        fillColor: const Color(0xFFE8F0FE),
                      ),
                      underLine: QuillToolbarToggleStyleButtonOptions(
                        iconData: Icons.format_underlined_rounded,
                        iconSize: 20,
                        fillColor: const Color(0xFFE8F0FE),
                      ),
                      strikeThrough: QuillToolbarToggleStyleButtonOptions(
                        iconData: Icons.format_strikethrough_rounded,
                        iconSize: 20,
                        fillColor: const Color(0xFFE8F0FE),
                      ),
                      listBullets: QuillToolbarToggleStyleButtonOptions(
                        iconData: Icons.format_list_bulleted_rounded,
                        iconSize: 20,
                        fillColor: const Color(0xFFE8F0FE),
                      ),
                      listNumbers: QuillToolbarToggleStyleButtonOptions(
                        iconData: Icons.format_list_numbered_rounded,
                        iconSize: 20,
                        fillColor: const Color(0xFFE8F0FE),
                      ),
                      undoHistory: QuillToolbarHistoryButtonOptions(
                        isUndo: true,
                        iconData: Icons.undo_rounded,
                        iconSize: 20,
                      ),
                      redoHistory: QuillToolbarHistoryButtonOptions(
                        isUndo: false,
                        iconData: Icons.redo_rounded,
                        iconSize: 20,
                      ),
                      linkStyle: QuillToolbarLinkStyleButtonOptions(
                        iconData: Icons.link_rounded,
                        iconSize: 20,
                        dialogTheme: QuillDialogTheme(
                          labelTextStyle: GoogleFonts.poppins(
                            color: const Color(0xFF1A237E),
                            fontWeight: FontWeight.w600,
                          ),
                          inputTextStyle: GoogleFonts.inter(),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      color: QuillToolbarColorButtonOptions(
                        iconData: Icons.format_color_text_rounded,
                        iconSize: 20,
                      ),
                      backgroundColor: QuillToolbarColorButtonOptions(
                        iconData: Icons.format_color_fill_rounded,
                        iconSize: 20,
                      ),
                      clearFormat: QuillToolbarClearFormatButtonOptions(
                        iconData: Icons.format_clear_rounded,
                        iconSize: 20,
                      ),
                    ),

                    toolbarSize: 48,
                    showDividers: true,
                    axis: Axis.horizontal,
                    color: Colors.white,
                    sectionDividerColor: Colors.grey[200],
                    sectionDividerSpace: 16,

                    dialogTheme: QuillDialogTheme(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.save_rounded, color: Colors.white, size: 20),
        onPressed: _onSave,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // MÉTODOS PARA INSERCIÓN DE IMÁGENES Y DIBUJOS

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Insertar imagen',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.photo_library_rounded,
                  color: const Color(0xFF4285F4)),
              title: Text('Desde galería', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded,
                  color: const Color(0xFF34A853)),
              title: Text('Tomar foto', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.brush_rounded, color: const Color(0xFFEA4335)),
              title: Text('Crear dibujo', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _openDrawingBoard();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        await _insertImageFile(image);
      }
    } catch (e) {
      _showErrorSnackbar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        await _insertImageFile(image);
      }
    } catch (e) {
      _showErrorSnackbar('Error al tomar foto: $e');
    }
  }

  Future<void> _openDrawingBoard() async {
    final result = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
          builder: (context) => DrawingBoard(
                onDrawingComplete: (_) {},
              )),
    );

    if (result != null && result.isNotEmpty) {
      await _insertDrawingImage(result);
    }
  }

  Future<void> _insertImageFile(XFile imageFile) async {
    try {
      // Guardar imagen temporalmente
      final bytes = await imageFile.readAsBytes();
      final tempDir = await getTemporaryDirectory();
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = path.join(tempDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Insertar en el editor
      _insertImageInEditor(filePath);
    } catch (e) {
      _showErrorSnackbar('Error al procesar imagen: $e');
    }
  }

  Future<void> _insertDrawingImage(Uint8List drawingBytes) async {
    try {
      // Guardar dibujo temporalmente
      final tempDir = await getTemporaryDirectory();
      final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = path.join(tempDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(drawingBytes);

      // Insertar en el editor
      _insertImageInEditor(filePath);
    } catch (e) {
      _showErrorSnackbar('Error al insertar dibujo: $e');
    }
  }

  Future<void> _insertImageInEditor(String imagePath) async {
    try {
      // Obtener la posición actual del cursor
      final index = _controller.selection.baseOffset;

      // Crear un bloque para la imagen
      final block = BlockEmbed.image(imagePath);

      // Insertar la imagen como bloque incrustado en una nueva línea
      _controller.document.insert(index, block);

      // Insertar un salto de línea después de la imagen para continuar escribiendo
      _controller.document.insert(index + 1, '\n');

      // Mover el cursor después de la imagen y el salto de línea
      _controller.updateSelection(
        TextSelection.collapsed(offset: index + 2),
        ChangeSource.local,
      );

      // Desplazar el scroll para que la imagen sea visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imagen insertada exitosamente',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF34A853),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Error al insertar imagen: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFFEA4335),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Métodos restantes (sin cambios)
  void _insertLink() async {
    final link = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Insertar enlace',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A237E),
          ),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'https://ejemplo.com',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Insertar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4285F4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _insertEmoji() {
    // Mantén tu lógica existente de emojis
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Insertar emoji',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A237E),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 36,
            itemBuilder: (context, index) {
              final emojis = [
                '😊',
                '😂',
                '🥰',
                '😎',
                '🤔',
                '😴',
                '👍',
                '❤️',
                '🔥',
                '⭐',
                '🎉',
                '📚'
              ];
              return GestureDetector(
                onTap: () {
                  final offset = _controller.selection.baseOffset;
                  _controller.document
                      .insert(offset, emojis[index % emojis.length]);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      emojis[index % emojis.length],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _attachFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Adjuntar archivo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A237E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  Icon(Icons.photo_rounded, color: const Color(0xFF4285F4)),
              title: Text('Imagen', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _showImageOptions();
              },
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file_rounded,
                  color: const Color(0xFF34A853)),
              title: Text('Documento', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.audiotrack_rounded,
                  color: const Color(0xFFEA4335)),
              title: Text('Audio', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Opciones adicionales',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.text_format_rounded,
                  color: const Color(0xFF4285F4)),
              title: Text('Cambiar fuente', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.format_size_rounded,
                  color: const Color(0xFF34A853)),
              title: Text('Tamaño de texto', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.line_style_rounded,
                  color: const Color(0xFFEA4335)),
              title: Text('Espaciado de línea', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    final delta = _controller.document.toDelta();
    final json = delta.toJson();
    final title = _titleController.text.trim();

    debugPrint('Nota guardada - Título: $title, Contenido: $json');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Nota guardada exitosamente',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF34A853),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }
}

class AppImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'image';

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final String imageSource = node.value.data;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 400, // Limita la altura máxima
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(imageSource),
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (_, __, ___) {
              return Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Imagen no disponible',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
