import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/Diary/Screens/NoteScreen.dart';
import 'package:horas2/Frontend/Modules/Diary/ViewModels/DiaryScreenViewModel.dart';
import 'package:horas2/Frontend/Modules/Diary/Widget/DIARYAPPBAR.dart';
import 'package:horas2/Frontend/Modules/Diary/Widget/DIARYCARD.dart';
import 'package:horas2/Frontend/Modules/Diary/Widget/EmptyDiaryState.dart';
import 'package:horas2/Frontend/Modules/Diary/model/diario_entry.dart';
import 'package:horas2/Frontend/Modules/Profile/Screens/ProfileScreen.dart';
import 'package:provider/provider.dart';

class DiarioScreen extends StatefulWidget {
  const DiarioScreen({super.key});

  @override
  State<DiarioScreen> createState() => _DiarioScreenState();
}

class _DiarioScreenState extends State<DiarioScreen> {
  late DiaryScreenViewModel _viewModel;
  
  @override
  void initState() {
    super.initState();
    _viewModel = DiaryScreenViewModel();
    
    // Cargar las entradas después de que el widget se haya inicializado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<DiaryScreenViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFF),
            body: _buildBody(viewModel),
            floatingActionButton: _buildFloatingActionButton(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }

  // Método para eliminar una entrada
  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    try {
      // Mostrar snackbar de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Eliminando "${entry['titulo'] ?? 'entrada'}"...',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      // Esperar a que se complete la eliminación
      final success = await _viewModel.deleteEntry(entry['id'], title: entry['titulo']);
      
      if (success) {
        // Esperar un momento antes de mostrar el mensaje de éxito
        await Future.delayed(const Duration(milliseconds: 500));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${entry['titulo'] ?? 'Entrada'}" eliminada exitosamente',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Error al eliminar la entrada',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Navegar a la pantalla de notas
  void _navigateToNoteScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoteScreen(),
      ),
    );
    
    // Recargar las entradas cuando regresemos
    if (mounted && result == true) {
      await Future.delayed(const Duration(milliseconds: 300));
      _viewModel.loadEntries();
    }
  }

  // Método para manejar el tap en una tarjeta
  void _onDiaryCardTap(Map<String, dynamic> entry) async {
    final diaryEntry = entry['entry'] as DiaryEntry;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteScreen(
          existingEntry: diaryEntry,
        ),
      ),
    );
    
    // Recargar las entradas cuando regresemos
    if (mounted && result == true) {
      await Future.delayed(const Duration(milliseconds: 300));
      _viewModel.loadEntries();
    }
  }

  Widget _buildBody(DiaryScreenViewModel viewModel) {
    if (viewModel.isLoading && viewModel.entries.isEmpty) {
      return _buildLoadingState();
    }

    if (viewModel.hasError) {
      return _buildErrorState(viewModel);
    }

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        // AppBar personalizada
        DiaryAppBar(
          onCalendarTap: () => _showCalendar(context, viewModel),
          onProfileTap: () => _navigateToProfile(),
          userName: 'Usuario',
          userAvatar: null,
        ),

        // Lista de entradas o estado vacío
        if (viewModel.entries.isEmpty)
          SliverFillRemaining(
            child: EmptyDiaryState(
              onCreateEntry: () => _navigateToNoteScreen(),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = viewModel.entries[index];
                  return _buildDiaryCard(entry, index);
                },
                childCount: viewModel.entries.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDiaryCard(Map<String, dynamic> entry, int index) {
    final List<Map<String, dynamic>> colorSets = [
      {
        'primary': const Color(0xFF4285F4),
        'light': const Color(0xFFE8F0FE),
        'accent': const Color(0xFFD2E3FC),
        'text': const Color(0xFF1A73E8),
        'badge': const Color(0xFF4285F4),
      },
      // Agrega más sets de colores aquí
    ];

    final colors = colorSets[entry['colorSet'] % colorSets.length];

    return Dismissible(
      key: Key('diary-entry-${entry['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context, entry);
      },
      onDismissed: (direction) async {
        await _deleteEntry(entry);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: DiaryCardWidget(
          entry: entry,
          colors: colors,
          onTap: () => _onDiaryCardTap(entry),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, Map<String, dynamic> entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar entrada',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A237E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres eliminar esta entrada?',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 8),
            if (entry['titulo'] != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${entry['titulo']}"',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Esta acción no se puede deshacer.',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToNoteScreen(),
      backgroundColor: const Color(0xFF4285F4),
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: const Icon(Icons.edit_note_rounded, size: 22),
      label: Text(
        'Nueva entrada',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
      ),
    );
  }

  Widget _buildErrorState(DiaryScreenViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.withOpacity(0.8),
              ),
              const SizedBox(height: 20),
              Text(
                'Error al cargar las entradas',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                viewModel.errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => viewModel.refresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Reintentar',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  Future<void> _showCalendar(
      BuildContext context, DiaryScreenViewModel viewModel) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      viewModel.setSelectedDate(selectedDate);
      viewModel.filterEntries();
    }
  }

  // Método para mostrar filtros de estado de ánimo
  Future<void> _showMoodFilter(
      BuildContext context, DiaryScreenViewModel viewModel) async {
    final moods = ['😊', '😢', '🤔', '😠', '😴', '🥳'];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filtrar por estado de ánimo',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final mood in moods)
                    GestureDetector(
                      onTap: () {
                        viewModel.setSelectedMood(mood);
                        viewModel.filterEntries();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            mood,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (viewModel.selectedMood != null)
                ElevatedButton(
                  onPressed: () {
                    viewModel.setSelectedMood(null);
                    viewModel.filterEntries();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[800],
                  ),
                  child: Text(
                    'Limpiar filtro',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}