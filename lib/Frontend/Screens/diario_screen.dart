import 'package:ai_app_tests/App/Data/Models/diario_entry.dart';
import 'package:ai_app_tests/App/Services/Service_Diario.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  List<DiarioEntry>? _entradasCache; // Cache para manejo inmediato

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Paso 1: Selector de emociones
                    _buildSelectorEmociones(),

                    const SizedBox(height: 24),

                    // Paso 2: Campo de título
                    _buildCampoTitulo(),

                    const SizedBox(height: 24),

                    // Paso 3: Área de contenido
                    _buildAreaContenido(),

                    const SizedBox(
                        height: 100), // Espacio para el botón flotante
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Botón flotante para guardar
      floatingActionButton: _buildBotonGuardar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono del diario
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '📖',
                style: TextStyle(fontSize: 22),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Título y fecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mi Diario',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _formatDate(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Botón de historial
          GestureDetector(
            onTap: _mostrarHistorial,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                color: Colors.grey,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('1',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      )),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '¿Cómo te has sentido hoy?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Grid de emociones
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2,
              crossAxisSpacing: 9,
              mainAxisSpacing: 12,
            ),
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
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1).withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        estado.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        estado.nombre,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('2',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      )),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Título de tu día',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Campo de título
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _tituloController,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: 'Ej: Un día increíble, Reflexiones matutinas...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: (text) {
                setState(() {}); // Para actualizar el estado del botón
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('3',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      )),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cuéntanos tu día',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Campo de contenido
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _contenidoController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Escribe aquí todo lo que quieras recordar de este día...\n\n• ¿Qué hiciste?\n• ¿Cómo te sentiste?\n• ¿Qué aprendiste?\n• ¿Qué te hizo feliz?',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  height: 1.4,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: (text) {
                setState(() {}); // Para actualizar el estado del botón
              },
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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: FloatingActionButton.extended(
        onPressed: _isLoading || !puedeGuardar ? null : _guardarEntrada,
        backgroundColor:
            puedeGuardar ? const Color(0xFF6366F1) : Colors.grey[300],
        foregroundColor: puedeGuardar ? Colors.white : Colors.grey,
        elevation: puedeGuardar ? 8 : 2,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(
          _isLoading ? 'Guardando...' : 'Guardar en mi diario',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
                  const Text(
                    '📚 Mi Historial',
                    style: TextStyle(
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
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de entradas
            Expanded(
              child: _entradasCache == null
                  ? FutureBuilder<List<DiarioEntry>>(
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

                        // Guardar en cache la primera vez
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

  Widget _buildEntradaHistorial(DiarioEntry entrada,
      [StateSetter? setModalState]) {
    return GestureDetector(
      onTap: () => _mostrarEntradaCompleta(entrada),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con fecha y botón eliminar
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateShort(DateTime.parse(entrada.fecha)),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmarEliminar(entrada, setModalState),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Estado de ánimo
            if (entrada.estadoAnimo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entrada.estadoAnimo!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Título
            if (entrada.categoria != null && entrada.categoria!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Text(
                  entrada.categoria!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Contenido preview
            Text(
              entrada.contenido,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Indicador de "tap para ver más"
            Row(
              children: [
                const Spacer(),
                Text(
                  'Toca para ver completo',
                  style: TextStyle(
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

  void _mostrarEntradaCompleta(DiarioEntry entrada) {
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(DateTime.parse(entrada.fecha)),
                            style: const TextStyle(
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18),
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
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getEmojiForEstado(entrada.estadoAnimo!),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entrada.estadoAnimo!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w500,
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
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botón eliminar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmarEliminar(entrada);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.red[200]!),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text(
                            'Eliminar entrada',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
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

  void _confirmarEliminar(DiarioEntry entrada, [StateSetter? setModalState]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Eliminar entrada'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar esta entrada del diario? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarEntrada(entrada, setModalState);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarEntrada(DiarioEntry entrada,
      [StateSetter? setModalState]) async {
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

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Eliminando entrada...'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 1),
      ),
    );

    try {
      if (entrada.idDiario != null) {
        await _diarioService.eliminarEntrada(entrada.idDiario!);

        if (mounted) {
          // Ocultar el snackbar de carga
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Entrada eliminada exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
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

        // Ocultar el snackbar de carga
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

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

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tu día ha sido guardado en el diario! 📖✨'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
