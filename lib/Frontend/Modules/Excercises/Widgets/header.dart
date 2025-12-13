// HomeScreen/widget/Header/ExerciseHeaderSection.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/Excercises/ViewModel/ExerciseViewModel.dart';
import 'package:provider/provider.dart';

class ExerciseHeaderSection extends StatelessWidget {
  final VoidCallback? onProgressPressed;
  final VoidCallback? onExercisePressed;

  const ExerciseHeaderSection({
    super.key,
    this.onProgressPressed,
    this.onExercisePressed,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExerciseViewModel>();

    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 25),
      child: Row(
        children: [
          // Sección izquierda: Mensaje y botón
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 155,
                child: _buildExerciseMessageWithButton(viewModel),
              ),
            ),
          ),


          // Imagen de la mascota a la derecha
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildMascotaImage(),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseMessageWithButton(ExerciseViewModel viewModel) {
    if (viewModel.isLoadingExerciseMessage) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: _buildMessageSkeleton(),
      );
    }

    final String messageText;
    final double fontSize;

    if (viewModel.exerciseMessage.isNotEmpty) {
      messageText = viewModel.exerciseMessage;
      fontSize = 14;
    } else {
      messageText =
          viewModel.studentName != null && viewModel.studentName!.isNotEmpty
              ? "${viewModel.studentName}, ¿listo para un ejercicio?"
              : "¿Listo para un ejercicio de bienestar emocional?";
      fontSize = 16;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Burbuja con el mensaje
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(242, 255, 255, 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.9),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.9,
                  ),
                  child: Text(
                    messageText,
                    style: GoogleFonts.itim(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Botón de ver progreso debajo del mensaje
                _buildProgressButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageSkeleton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Skeleton de la burbuja
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 1.5,
            ),
          ),
          width: 220,
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 180,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 140,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        
        // Skeleton para el botón
        Container(
          width: 120,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressButton() {
    return GestureDetector(
      onTap: onProgressPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF86A8E7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timeline_rounded,
              size: 18,
              color: Color(0xFF86A8E7),
            ),
            const SizedBox(width: 8),
            Text(
              'Ver progreso',
              style: GoogleFonts.itim(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF86A8E7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotaImage() {
    return Image.asset(
      'assets/images/brainexcercises.png',
      width: 160,
      height: 160,
      fit: BoxFit.contain,
    );
  }
}