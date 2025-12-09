import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Modules/Diary/ViewModels/service.dart';
import 'package:horas2/Frontend/Modules/Diary/model/DiarioModel.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class DiarioScreen extends StatefulWidget {
  const DiarioScreen({super.key});

  @override
  State<DiarioScreen> createState() => _DiarioScreenState();
}

class _DiarioScreenState extends State<DiarioScreen> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _contenidoController = TextEditingController();
  final DiarioService _diarioService = DiarioService();
  bool _isLoading = false;
  EstadoAnimo? _estadoAnimoSeleccionado;
  List<DiarioModel>? _entradasCache;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF), // Mismo color de fondo del Home
      body: SafeArea(
        child: Column(
          children: [
            // Header rediseñado
            _buildHeader(),

            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo de título rediseñado
                    _buildCampoTitulo(),

                    const SizedBox(height: 20),

                    // Área de contenido mejorada
                    _buildAreaContenido(),

                    const SizedBox(height: 20),

                    // Selector de emociones mejorado
                    _buildSelectorEmociones(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Botón flotante rediseñado
      floatingActionButton: _buildBotonGuardar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [



          // Ícono del diario
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '📖',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Título y fecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi Diario',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _formatDate(DateTime.now()),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Botón de historial
          GestureDetector(
            onTap: _mostrarHistorial,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.history_rounded,
                color: const Color(0xFFF66B7D),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorEmociones() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título mejorado
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF66B7D), Color(0xFFFF8E6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '3',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Cómo te sientes hoy?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Descripción
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              'Selecciona tu estado emocional actual',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Grid de emociones horizontal mejorado
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: EstadoAnimo.values.length,
              itemBuilder: (context, index) {
                final estado = EstadoAnimo.values[index];
                final isSelected = _estadoAnimoSeleccionado == estado;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _estadoAnimoSeleccionado = estado;
                    });
                  },
                  child: Container(
                    width: 80,
                    margin: EdgeInsets.only(
                      right: index == EstadoAnimo.values.length - 1 ? 0 : 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF86A8E7)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF86A8E7).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          estado.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          estado.nombre,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color:
                                isSelected ? Colors.black87 : Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
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

  Widget _buildCampoTitulo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF86A8E7), Color(0xFFB2F5DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '1',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Título de tu día',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Campo de título mejorado - AHORA CON MÚLTIPLES LÍNEAS
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _tituloController.text.isNotEmpty
                    ? const Color(0xFF86A8E7).withOpacity(0.5)
                    : Colors.grey[300]!,
              ),
            ),
            child: TextField(
              controller: _tituloController,
              maxLines: null, // Permite múltiples líneas
              minLines: 1, // Mínimo una línea
              textInputAction: TextInputAction.done,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Ej: Un día increíble, Reflexiones matutinas...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: _tituloController.text.isNotEmpty
                    ? Icon(
                        Icons.check_circle,
                        color: const Color(0xFF4CAF50),
                        size: 20,
                      )
                    : null,
              ),
              onChanged: (text) {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaContenido() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF66B7D), Color(0xFFFF8E6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '2',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cuéntanos tu día',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Campo de contenido mejorado
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _contenidoController.text.isNotEmpty
                    ? const Color(0xFF86A8E7).withOpacity(0.5)
                    : Colors.grey[300]!,
              ),
            ),
            child: TextField(
              controller: _contenidoController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Escribe aquí todo lo que quieras recordar de este día...\n\n• ¿Qué hiciste?\n• ¿Cómo te sentiste?\n• ¿Qué aprendiste?\n• ¿Qué te hizo feliz?',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: (text) {
                setState(() {});
              },
            ),
          ),

          // Contador de palabras
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_contenidoController.text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length} palabras',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonGuardar() {
    final puedeGuardar = _contenidoController.text.trim().isNotEmpty &&
        _tituloController.text.trim().isNotEmpty &&
        _estadoAnimoSeleccionado != null;

    // Se esconde cuando el usuario está escribiendo (teclado visible)
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (isKeyboardVisible && !puedeGuardar) {
      return const SizedBox.shrink(); // Se esconde completamente
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton(
        onPressed: _isLoading || !puedeGuardar ? null : _guardarEntrada,
        backgroundColor: puedeGuardar
            ? const Color(0xFFF66B7D) // Color del botón del Home
            : Colors.grey[400],
        foregroundColor: Colors.white,
        elevation: 8,
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save_rounded, size: 24),
      ),
    );
  }

  // === MÉTODOS ORIGINALES (SE MANTIENEN IGUAL) ===

  Future<void> _guardarEntrada() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _diarioService.crearEntrada(
        contenido: _contenidoController.text.trim(),
        categoria: _tituloController.text.trim(),
        estadoAnimo: _estadoAnimoSeleccionado?.nombre,
        valoracion: _estadoAnimoSeleccionado?.valor,
      );

      // Limpiar campos
      _contenidoController.clear();
      _tituloController.clear();
      _estadoAnimoSeleccionado = null;

      // Limpiar cache para que se recargue con la nueva entrada
      _entradasCache = null;

      // Mostrar modal de éxito
      if (mounted) {
        _mostrarModalExito();
      }
    } catch (e) {
      // Mostrar modal de error
      if (mounted) {
        _mostrarModalError('Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarModalExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de éxito animado
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45C7C1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 24),

              // Título
              Text(
                '¡Guardado exitoso!',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Mensaje
              Text(
                'Tu día ha sido guardado en el diario 📖✨',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Botón de aceptar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '¡Entendido!',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  void _mostrarModalError(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de error
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red[600],
                  size: 40,
                ),
              ),

              const SizedBox(height: 24),

              // Título
              Text(
                'Error al guardar',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Mensaje de error
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Botón de aceptar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Reintentar',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  void _mostrarHistorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildHistorialModal(),
    );
  }

  Widget _buildHistorialModal() {
    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle del modal
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header del modal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    '📚 Mi Historial',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(Icons.close, size: 18, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de entradas
            Expanded(
              child: _entradasCache == null
                  ? FutureBuilder<List<DiarioModel>>(
                      future: _diarioService.obtenerEntradas(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '📖',
                                  style: TextStyle(fontSize: 64),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Tu diario está vacío',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Comienza escribiendo tu primera entrada',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_entradasCache == null) {
                            setState(() {
                              _entradasCache = List.from(snapshot.data!);
                              _entradasCache!
                                  .sort((a, b) => b.fecha.compareTo(a.fecha));
                            });
                          }
                        });

                        final entradas = snapshot.data!;
                        entradas.sort((a, b) => b.fecha.compareTo(a.fecha));

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: entradas.length,
                          itemBuilder: (context, index) {
                            final entrada = entradas[index];
                            return _buildEntradaHistorial(
                                entrada, setModalState);
                          },
                        );
                      },
                    )
                  : _entradasCache!.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '📖',
                                style: TextStyle(fontSize: 64),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Tu diario está vacío',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Comienza escribiendo tu primera entrada',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _entradasCache!.length,
                          itemBuilder: (context, index) {
                            final entrada = _entradasCache![index];
                            return _buildEntradaHistorial(
                                entrada, setModalState);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntradaHistorial(DiarioModel entrada,
      [StateSetter? setModalState]) {
    return GestureDetector(
      onTap: () => _mostrarEntradaCompleta(entrada),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateShort(DateTime.parse(entrada.fecha)),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmarEliminar(entrada, setModalState),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (entrada.estadoAnimo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFB2F5DB).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entrada.estadoAnimo!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (entrada.categoria != null && entrada.categoria!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Text(
                  entrada.categoria!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Text(
              entrada.contenido,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                Text(
                  'Toca para ver completo',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: Colors.grey[500],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarEntradaCompleta(DiarioModel entrada) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle del modal
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header del modal
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entrada.categoria ?? 'Sin título',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(DateTime.parse(entrada.fecha)),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido de la entrada
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado de ánimo
                      if (entrada.estadoAnimo != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getEmojiForEstado(entrada.estadoAnimo!),
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                entrada.estadoAnimo!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Contenido completo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          entrada.contenido,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Botón eliminar - MEJORADO
                      Container(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmarEliminar(entrada);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.red.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                          ),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 22,
                            color: Colors.red[600],
                          ),
                          label: Text(
                            'Eliminar entrada',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEliminar(DiarioModel entrada, [StateSetter? setModalState]) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de advertencia
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  size: 32,
                  color: Colors.red[600],
                ),
              ),

              const SizedBox(height: 20),

              // Título
              Text(
                'Eliminar entrada',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Mensaje
              Text(
                '¿Estás seguro de que quieres eliminar esta entrada del diario? Esta acción no se puede deshacer.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  // Botón Cancelar
                  Expanded(
                    child: Container(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Botón Eliminar
                  Expanded(
                    child: Container(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _eliminarEntrada(entrada, setModalState);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Eliminar',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _eliminarEntrada(DiarioModel entrada,
      [StateSetter? setModalState]) async {
    // Mostrar modal de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildModalCarga(),
    );

    // Eliminar inmediatamente de la lista visual (optimistic update)
    if (_entradasCache != null) {
      setState(() {
        _entradasCache!.removeWhere((e) => e.idDiario == entrada.idDiario);
      });

      // También actualizar el modal si está abierto
      if (setModalState != null) {
        setModalState(() {});
      }
    }

    try {
      if (entrada.idDiario != null) {
        await _diarioService.eliminarEntrada(entrada.idDiario!);

        if (mounted) {
          // Cerrar modal de carga
          Navigator.pop(context);

          // Mostrar modal de éxito
          _mostrarModalEliminacionExito();
        }
      }
    } catch (e) {
      if (mounted) {
        // Cerrar modal de carga
        Navigator.pop(context);

        // Si hay error, restaurar la entrada en la lista
        if (_entradasCache != null) {
          setState(() {
            _entradasCache!.add(entrada);
            _entradasCache!.sort((a, b) => b.fecha.compareTo(a.fecha));
          });

          // También actualizar el modal si está abierto
          if (setModalState != null) {
            setModalState(() {});
          }
        }

        // Mostrar modal de error
        _mostrarModalErrorEliminacion('Error al eliminar: $e');
      }
    }
  }

  Widget _buildModalCarga() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spinner de carga
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFFA000)),
                backgroundColor: const Color(0xFFFFA000).withOpacity(0.2),
              ),
            ),

            const SizedBox(height: 20),

            // Texto de carga
            Text(
              'Eliminando entrada...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Por favor espera un momento',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalEliminacionExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de éxito
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 40,
                ),
              ),

              const SizedBox(height: 24),

              // Título
              Text(
                '¡Eliminado!',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Mensaje
              Text(
                'La entrada ha sido eliminada exitosamente',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Botón de aceptar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continuar',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  void _mostrarModalErrorEliminacion(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de error
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red[600],
                  size: 40,
                ),
              ),

              const SizedBox(height: 24),

              // Título
              Text(
                'Error al eliminar',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Mensaje de error
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Botón de aceptar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  // Helper method to safely format dates with fallback
  String _formatDate(DateTime date) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(date);
    } catch (e) {
      // Fallback to default locale if Spanish locale fails
      try {
        return DateFormat('EEEE, dd MMMM yyyy').format(date);
      } catch (e2) {
        // Ultimate fallback to simple format
        return DateFormat('dd/MM/yyyy').format(date);
      }
    }
  }

  // Helper method to safely format short dates with fallback
  String _formatDateShort(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy', 'es_ES').format(date);
    } catch (e) {
      // Fallback to default locale if Spanish locale fails
      try {
        return DateFormat('dd MMM yyyy').format(date);
      } catch (e2) {
        // Ultimate fallback to simple format
        return DateFormat('dd/MM/yyyy').format(date);
      }
    }
  }

  // Helper method to get emoji for estado de animo
  String _getEmojiForEstado(String estadoAnimo) {
    switch (estadoAnimo.toLowerCase()) {
      case 'muy feliz':
        return '😄';
      case 'feliz':
        return '😊';
      case 'neutral':
        return '😐';
      case 'triste':
        return '😢';
      case 'muy triste':
        return '😭';
      case 'ansioso':
        return '😰';
      case 'relajado':
        return '😌';
      case 'enojado':
        return '😠';
      case 'emocionado':
        return '🤩';
      case 'cansado':
        return '😴';
      default:
        return '😊';
    }
  }

  @override
  void dispose() {
    _contenidoController.dispose();
    _tituloController.dispose();
    super.dispose();
  }
}
