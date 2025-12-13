// En tu HomeScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/Excercises/ViewModel/ExerciseViewModel.dart';
import 'package:horas2/Frontend/Modules/Excercises/Widgets/header.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/ViewModels/HomeViewModel.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Header/HomeHeaderSection.dart';
import 'package:provider/provider.dart';

class ExcersicesScreen extends StatefulWidget {
  const ExcersicesScreen({super.key});

  @override
  State<ExcersicesScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ExcersicesScreen>
    with WidgetsBindingObserver {
  // ... código existente ...

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ExerciseViewModel()),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF2FFFF),
        body: SingleChildScrollView(
          child: Column(
            children: [

              // Header de ejercicios
              Consumer<ExerciseViewModel>(
                builder: (context, exerciseVM, child) {
                  return ExerciseHeaderSection(
                    onProgressPressed: () {
                      // Navegar a pantalla de progreso
                    },
                    onExercisePressed: () {
                      // Iniciar ejercicio
                      _startExercise(context);
                    },
                  );
                },
              ),

              // Header original (opcional, puedes mantenerlo o reemplazarlo)

              // Resto de tu contenido...
            ],
          ),
        ),
      ),
    );
  }

  void _startExercise(BuildContext context) {
    // Lógica para iniciar ejercicio
    final exerciseVM = context.read<HomeViewModel>();

    // Mostrar diálogo o navegar a pantalla de ejercicio
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¡Comencemos!',
          style: GoogleFonts.itim(),
        ),
        content: Text(
          exerciseVM.studentName != null && exerciseVM.studentName!.isNotEmpty
              ? 'Perfecto, ${exerciseVM.studentName}. Vamos a realizar un ejercicio de bienestar emocional.'
              : 'Vamos a realizar un ejercicio de bienestar emocional.',
          style: GoogleFonts.itim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegar a pantalla de ejercicio
            },
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );
  }
}
