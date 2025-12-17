// lib/Frontend/Modules/Diary/Screens/NoteScreen.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/Diary/Screens/DrawingBoard.dart';
import 'package:horas2/Frontend/Modules/Diary/ViewModels/DiaryViewModel.dart';
import 'package:horas2/Frontend/Modules/Diary/Widget/dateselectorwidget.dart';
import 'package:horas2/Frontend/Modules/Diary/Widget/img.dart';
import 'package:horas2/Frontend/Modules/Diary/Widget/mode.dart';
import 'package:horas2/Frontend/Modules/Diary/Widget/toolbar.dart';
import 'package:horas2/Frontend/Modules/Diary/model/diario_entry.dart';
import 'package:provider/provider.dart';
 
class NoteScreen extends StatefulWidget {
  static const routeName = '/note';
  final DiaryEntry? existingEntry;

  const NoteScreen({super.key, this.existingEntry});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  late NoteViewModel _viewModel;
  final List<String> _availableMoods = [
    '😊', '😂', '🥰', '😎', '🤔', '😴', '👍', '❤️', '🔥', '⭐'
  ];
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = NoteViewModel();
    _initializeViewModel();
  }

  Future<void> _initializeViewModel() async {
    // Configurar los callbacks para mensajes
    _viewModel.setMessageCallbacks(
      onSuccess: _showSuccessMessage,
      onError: _showErrorMessage,
    );
    
    await _viewModel.initialize(existingEntry: widget.existingEntry);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getMonthAbbreviation(int month) {
    switch (month) {
      case 1: return 'ENE';
      case 2: return 'FEB';
      case 3: return 'MAR';
      case 4: return 'ABR';
      case 5: return 'MAY';
      case 6: return 'JUN';
      case 7: return 'JUL';
      case 8: return 'AGO';
      case 9: return 'SEP';
      case 10: return 'OCT';
      case 11: return 'NOV';
      case 12: return 'DIC';
      default: return '';
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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
  }

  void _showErrorMessage(String message) {
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
      _viewModel.updateDate(selectedDate);
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
                itemCount: _availableMoods.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _viewModel.updateMood(_availableMoods[index]);
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
                          _availableMoods[index],
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
              leading: const Icon(Icons.photo_library_rounded,
                  color: Color(0xFF4285F4)),
              title: Text('Desde galería', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _viewModel.insertImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: Color(0xFF34A853)),
              title: Text('Tomar foto', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _viewModel.insertImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.brush_rounded,
                  color: Color(0xFFEA4335)),
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

  Future<void> _openDrawingBoard() async {
    final result = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingBoard(
          onDrawingComplete: (drawingBytes) {
            // Esta función se llama cuando el dibujo está completo
          },
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _viewModel.insertDrawing(result);
    }
  }

  void _insertEmoji() {
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
                '😊', '😂', '🥰', '😎', '🤔', '😴',
                '👍', '❤️', '🔥', '⭐', '🎉', '📚'
              ];
              return GestureDetector(
                onTap: () {
                  _viewModel.insertEmoji(emojis[index % emojis.length]);
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

  Future<void> _onSave() async {
    await _viewModel.saveEntry();
    if (mounted) {
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<NoteViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFF),
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1A237E),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.existingEntry == null ? 'Nueva entrada' : 'Editar entrada',
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
                controller: viewModel.quillController,
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('es'),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          children: [
                            // Selector de fecha y estado de ánimo
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  StreamBuilder<DateTime>(
                                    stream: viewModel.selectedDateStream,
                                    builder: (context, snapshot) {
                                      final date = snapshot.data ?? DateTime.now();
                                      return DateSelectorWidget(
                                        selectedDate: date,
                                        monthAbbreviation: _getMonthAbbreviation(date.month),
                                        onTap: _showDatePicker,
                                      );
                                    },
                                  ),
                                  StreamBuilder<String>(
                                    stream: viewModel.selectedMoodStream,
                                    builder: (context, snapshot) {
                                      return MoodSelectorWidget(
                                        selectedMood: snapshot.data ?? '😊',
                                        onTap: _showMoodSelector,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Campo de título
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 0),
                              child: TextField(
                                controller: viewModel.titleController,
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
                            Container(
                              color: Colors.white,
                              constraints: const BoxConstraints(
                                minHeight: 300,
                                maxHeight: double.infinity,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: QuillEditor(
                                  configurations: QuillEditorConfigurations(
                                    scrollable: false,
                                    autoFocus: false,
                                    readOnly: false,
                                    expands: false,
                                    padding: const EdgeInsets.only(bottom: 100),
                                    placeholder:
                                        'Escribe aquí tus pensamientos, reflexiones o momentos especiales del día...',
                                    embedBuilders: [
                                      ImageEmbedWidget(),
                                    ],
                                    scrollBottomInset: 100,
                                    customStyleBuilder: (attribute) {
                                      final baseStyle = TextStyle(
                                        fontSize: 16,
                                        fontFamily: GoogleFonts.poppins().fontFamily,
                                        height: 1.6,
                                        color: const Color(0xFF1A237E),
                                      );

                                      if (attribute.key == Attribute.size.key) {
                                        return baseStyle;
                                      }

                                      if (attribute.key == Attribute.bold.key) {
                                        return baseStyle.copyWith(
                                            fontWeight: FontWeight.bold);
                                      }

                                      if (attribute.key == Attribute.italic.key) {
                                        return baseStyle.copyWith(
                                            fontStyle: FontStyle.italic);
                                      }

                                      return baseStyle;
                                    },
                                  ),
                                  focusNode: _focusNode,
                                  scrollController: _scrollController,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Barra de herramientas FIJA en la parte inferior usando Widget reutilizable
                    ToolbarWidget(
                      onImagePressed: _showImageOptions,
                      onEmojiPressed: _insertEmoji,
                      controller: viewModel.quillController,
                      toolbarHeight: 48,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}