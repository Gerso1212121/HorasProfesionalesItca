// HomeScreen/widget/screenWidgets/HomeHeaderSection.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/Diary/Screens/DiarioScreen.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Utils/HomeScreenUtils.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/ViewModels/HomeViewModel.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Skeleton/Movicacionalskeleton.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Header/CalendarWidget.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(00),
          bottomRight: Radius.circular(00),
        ),
      ),
      padding: const EdgeInsets.only(top: 100, bottom: 24),
      child: Column(
        children: [
          _buildDateSelector(viewModel),
          const SizedBox(height: 24),
          viewModel.showCalendar
              ? _buildCalendar(viewModel)
              : _buildWelcomeSection(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildDateSelector(HomeViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.toggleCalendar,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF66B7D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                viewModel.showCalendar
                    ? 'Frase diaria'
                    : '${viewModel.selectedDay.day.toString().padLeft(2, '0')} de ${HomeScreenUtils.getMonthName(viewModel.selectedDay.month)} de ${viewModel.selectedDay.year}',
                style: GoogleFonts.itim(
                  color: Colors.white,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(HomeViewModel viewModel) {
    return CalendarWidget(
      selectedDay: viewModel.selectedDay,
      onDaySelected: (selectedDay, focusedDay) {
        viewModel.selectDay(selectedDay);
      },
      onClose: () => viewModel.toggleCalendar(),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, HomeViewModel viewModel) {
    return Column(
      children: [
        // Nombre - si está cargando mostrar skeleton, sino el nombre
        if (viewModel.isLoadingName)
          Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.45),
            highlightColor: Colors.white.withOpacity(0.8),
            child: Container(
              width: 150,
              height: 30,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
          Text(
            '¡Bienvenido, ${viewModel.studentName ?? 'Usuario'}!',
            textAlign: TextAlign.center,
            style: GoogleFonts.itim(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

        const SizedBox(height: 24),
        _buildMascota(),
        _buildMotivationalSection(context, viewModel),
      ],
    );
  }

  Widget _buildMascota() {
    return Center(
      child: Image.asset(
        'assets/images/brainhi.png',
        width: 190,
        height: 190,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildMotivationalSection(
      BuildContext context, HomeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Frase motivacional del día',
            style: GoogleFonts.itim(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // LÓGICA MEJORADA PARA MOSTRAR FRASE
          _buildFraseContent(viewModel),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DiarioScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF66B7D),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              shadowColor: const Color.fromARGB(100, 246, 107, 125),
            ),
            child: Text(
              'Iniciar diario',
              style: GoogleFonts.itim(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFraseContent(HomeViewModel viewModel) {
    // Si está cargando y debe mostrar skeleton
    if (viewModel.shouldShowFraseSkeleton || viewModel.isLoadingFrase) {
      return const FraseMotivacionalSkeleton();
    }

    // Si la frase está vacía pero NO está cargando (caso inicial)
    // Mostrar una frase por defecto temporal
    if (viewModel.fraseMotivacional.isEmpty) {
      return Text(
        "Preparando tu motivación diaria...",
        style: GoogleFonts.itim(
          fontSize: 16,
          color: Colors.black54,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      );
    }

    // Frase cargada (desde cache o nueva)
    return Text(
      viewModel.fraseMotivacional,
      style: GoogleFonts.itim(
        fontSize: 16,
        color: Colors.black,
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    );
  }
}
