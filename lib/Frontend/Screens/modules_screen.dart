import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Widgets/modules_cart.dart';
import '../Widgets/emergency_button.dart';
import '../Widgets/personal_growth_section.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //Parte de arriba
            _buildTopSection(),
            const SizedBox(height: 20),

            //Mucho texto
            _buildMainTitle(),
            const SizedBox(height: 20),

            //Introduccion
            _buildPersonalGrowthSection(),
            const SizedBox(height: 20),

            //Mucho texto mas texto que nunca parte 2
            _buildModulesTitle(),
            const SizedBox(height: 20),

            //Los modulos
            _buildModulesGrid(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 300, //Sancho digo ancho de imagen
            height: 100, //Alto, no soy :(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12), //¿Puya o no puya?
              image: const DecorationImage(
                image: AssetImage('assets/images/descarga.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(
              height: 50), //Espacio para las cosas esta (el boton y logo ITCA)

          const SizedBox(
            width: 300,
            child: EmergencyButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Trabaja en ti mismo, [Usuario]',
        textAlign: TextAlign.center,
        style: GoogleFonts.itim(
          color: Colors.black,
          fontSize: 36, //Font size 900rem
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildPersonalGrowthSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin:
              const EdgeInsets.symmetric(horizontal: 20), //Margen horizontal
          decoration: BoxDecoration(
            color: const Color(0xFFD5F5EA).withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24), //Radio de arriba
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20,
            ), //Puddin interno
            decoration: const BoxDecoration(
              color: Color(0xFFD5F5EA),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(12), //Radio de borde inferior
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crecimiento personal',
                  style: GoogleFonts.itim(
                    color: Colors.black,
                    fontSize: 32, //Tamaño del título
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12), // Radio de borde de la imagen
                  child: Image.asset(
                    'assets/images/fondo2.png',
                    width: double.infinity,
                    fit: BoxFit.cover, // Ajuste de la imagen
                    height: 200, // Altura de la imagen - ajusta aquí
                  ),
                ),

                const SizedBox(height: 10), //Espacio entre título y texto
                Text(
                  'Emplea técnicas recomendadas por profesionales para mejorar tu estabilidad y salud mental',
                  style: GoogleFonts.itim(
                    color: Colors.black,
                    fontSize: 20, //Tamaño del texto descriptivo
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20), //Espacio antes de la imagen
        // Imagen que ocupa el 100% del ancho del contenedor
      ],
    );
  }

  Widget _buildModulesTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Inicia una nueva actividad',
        textAlign: TextAlign.center,
        style: GoogleFonts.itim(
          color: Colors.black,
          fontSize: 28, // Tamaño del título
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildModulesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, //Número de columnas
        crossAxisSpacing: 20, //Espacio horizontal entre elementos
        mainAxisSpacing: 20, //Espacio vertical entre elementos
        childAspectRatio: 0.8, //Relación alto/ancho de las tarjetas
        children: const [
          ModuleCard(
            title: 'Meditación Guiada',
            color: Color(0xFFDBFFDD),
            imagePath: 'assets/images/meditacion1.png',
          ),
          ModuleCard(
            title: 'Ejercicios de Respiración',
            color: Color(0xFFD0E5F8),
            imagePath: 'assets/images/respiracion.jpg',
          ),
          ModuleCard(
            title: 'Diario Emocional',
            color: Color(0xFFFFEBD6),
            imagePath: 'assets/images/meditacion2.jpg',
          ),
          ModuleCard(
            title: 'Terapia Cognitiva',
            color: Color(0xFFE6D6FF),
            imagePath: 'assets/images/respiracion.jpg',
          ),
        ],
      ),
    );
  }
}
