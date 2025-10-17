/*----------|IMPORTACIONES BASICAS|----------*/
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/*----------|IMPORTACIONES MODULOS|----------*/
import 'package:ai_app_tests/App/Data/Models/ejercicio_model.dart';
import 'package:ai_app_tests/App/Services/Services_Ejercicios.dart';
import 'package:ai_app_tests/App/Services/Service_AnalisisEjercicio.dart';
import 'package:ai_app_tests/Frontend/Widgets/ejercicios_widgets.dart';
import '../../App/Services/Logs/Services_Log.dart';
import '../../App/Data/DataBase/DatabaseHelper.dart';

class EjerciciosScreen extends StatefulWidget {
  const EjerciciosScreen({super.key});

  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen>
    with TickerProviderStateMixin {
  final EjerciciosService _ejerciciosService = EjerciciosService();
  final _auth = FirebaseAuth.instance;

  late TabController _tabController;
  bool _isLoading = true;

  TipoEjercicio? _tipoSeleccionado;
  List<RecomendacionEjercicio> _recomendaciones = [];
  EstadisticasEjercicios? _estadisticas;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    try {
      // Usar el nuevo método optimizado para carga paralela
      final resultado = await _ejerciciosService.cargarDatosIniciales();

      if (mounted) {
        if (resultado['success'] == true) {
          setState(() {
            _recomendaciones =
                resultado['recomendaciones'] as List<RecomendacionEjercicio>;
            _estadisticas = resultado['estadisticas'] as EstadisticasEjercicios;
            _isLoading = false;
          });
          LogService.log("✅ Datos de ejercicios cargados exitosamente");
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Error al cargar ejercicios: ${resultado['error']}'),
              backgroundColor: Colors.red,
            ),
          );
          LogService.log(
              "❌ Error al cargar datos de ejercicios: ${resultado['error']}");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ejercicios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      LogService.log("❌ Excepción al cargar datos de ejercicios: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? _buildLoadingState()
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 100,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.deepPurple,
                    title: const Text(
                      'EJERCICIOS DE BIENESTAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    centerTitle: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.deepPurple,
                              Colors.purple,
                              Colors.purpleAccent,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -50,
                              top: -50,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -30,
                              bottom: -30,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    bottom: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: 'Explorar'),
                        Tab(text: 'Recomendados'),
                        Tab(text: 'Mi Progreso'),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildExplorarTab(),
                  _buildRecomendadosTab(),
                  _buildProgresoTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cargando ejercicios...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preparando recomendaciones personalizadas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecomendadosTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _ejerciciosService.clearCache();
        await _inicializarDatos();
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.syncEjercicios();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_estadisticas != null) ...[
              EstadisticasRapidas(
                totalEjerciciosRealizados:
                    _estadisticas!.totalEjerciciosRealizados,
                minutosTotal: _estadisticas!.minutosTotal,
                rachaActual: _estadisticas!.rachaActual,
              ),
              const SizedBox(height: 24),
            ],

            // Mensaje personalizado
            if (_recomendaciones.isNotEmpty &&
                _recomendaciones.first.motivoPersonalizacion != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.indigo.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology,
                        color: Colors.blue.shade600, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _recomendaciones.first.motivoPersonalizacion!,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Ejercicios recomendados
            const Text(
              'Recomendados para ti',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            if (_recomendaciones.isEmpty)
              const EmptyEjerciciosState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recomendaciones.length,
                itemBuilder: (context, index) {
                  final recomendacion = _recomendaciones[index];
                  return EjercicioRecomendadoCard(
                    recomendacion: recomendacion, // Esto ahora es correcto
                    onTap: () => _navegarAEjercicio(recomendacion.ejercicio),
                  );
                },
              )
          ],
        ),
      ),
    );
  }

  Widget _buildExplorarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros por tipo
          const Text(
            'Explorar por categoría',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Grid de tipos de ejercicios
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: TipoEjercicio.values.length,
            itemBuilder: (context, index) {
              final tipo = TipoEjercicio.values[index];
              return TipoEjercicioCard(
                tipo: tipo,
                onTap: () => _navegarATipoEjercicios(tipo),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgresoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_estadisticas != null) ...[
            EstadisticasDetalladas(estadisticas: _estadisticas!),
            const SizedBox(height: 24),
          ],
          const Text(
            'Actividad Reciente',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_estadisticas?.ejerciciosRecientes.isEmpty ?? true)
            const EmptyProgresoState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _estadisticas!.ejerciciosRecientes.length,
              itemBuilder: (context, index) {
                final progreso = _estadisticas!.ejerciciosRecientes[index];
                return ProgresoEjercicioCard(progreso: progreso);
              },
            ),
        ],
      ),
    );
  }

  void _navegarAEjercicio(EjercicioPsicologico ejercicio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EjercicioDetalleScreen(ejercicio: ejercicio),
      ),
    ).then((_) => _inicializarDatos()); // Refrescar al volver
  }

  void _navegarATipoEjercicios(TipoEjercicio tipo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EjerciciosPorTipoScreen(tipo: tipo),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Pantalla de detalle de ejercicio
class EjercicioDetalleScreen extends StatefulWidget {
  final EjercicioPsicologico ejercicio;

  const EjercicioDetalleScreen({
    super.key,
    required this.ejercicio,
  });

  @override
  State<EjercicioDetalleScreen> createState() => _EjercicioDetalleScreenState();
}

class _EjercicioDetalleScreenState extends State<EjercicioDetalleScreen> {
  final EjerciciosService _ejerciciosService = EjerciciosService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: widget.ejercicio.tipo.color,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.ejercicio.titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.ejercicio.tipo.color,
                      widget.ejercicio.tipo.color.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.ejercicio.tipo.icono,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información básica
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.ejercicio.dificultad.color
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.ejercicio.dificultad.color
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.ejercicio.dificultad.nombre,
                          style: TextStyle(
                            color: widget.ejercicio.dificultad.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.ejercicio.duracionMinutos} min',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Descripción
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.ejercicio.descripcion,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Objetivos
                  const Text(
                    'Objetivos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.ejercicio.objetivos
                      .map((objetivo) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin:
                                      const EdgeInsets.only(top: 8, right: 12),
                                  decoration: BoxDecoration(
                                    color: widget.ejercicio.tipo.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    objetivo,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),

                  const SizedBox(height: 24),

                  // Instrucciones
                  const Text(
                    'Instrucciones',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.ejercicio.instrucciones
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final instruccion = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: widget.ejercicio.tipo.color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              instruccion,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _iniciarEjercicio,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.ejercicio.tipo.color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Comenzar Ejercicio (${widget.ejercicio.duracionMinutos} min)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  void _iniciarEjercicio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EjercicioEnProgresoScreen(ejercicio: widget.ejercicio),
      ),
    ).then((resultado) {
      if (resultado == true) {
        Navigator.pop(context); // Volver a la pantalla anterior
      }
    });
  }
}

// Pantalla de ejercicios por tipo
class EjerciciosPorTipoScreen extends StatefulWidget {
  final TipoEjercicio tipo;

  const EjerciciosPorTipoScreen({
    super.key,
    required this.tipo,
  });

  @override
  State<EjerciciosPorTipoScreen> createState() =>
      _EjerciciosPorTipoScreenState();
}

class _EjerciciosPorTipoScreenState extends State<EjerciciosPorTipoScreen> {
  final EjerciciosService _ejerciciosService = EjerciciosService();
  List<EjercicioPsicologico> _ejercicios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEjercicios();
  }

  Future<void> _cargarEjercicios() async {
    try {
      final ejercicios =
          await _ejerciciosService.obtenerEjerciciosPorTipo(widget.tipo);
      if (mounted) {
        setState(() {
          _ejercicios = ejercicios;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.tipo.nombre),
        backgroundColor: widget.tipo.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ejercicios.isEmpty
              ? const Center(
                  child: Text(
                    'No hay ejercicios disponibles para esta categoría',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ejercicios.length,
                  itemBuilder: (context, index) {
                    final ejercicio = _ejercicios[index];
                    return EjercicioCard(
                      ejercicio: ejercicio,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EjercicioDetalleScreen(ejercicio: ejercicio),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// Pantalla de ejercicio en progreso
class EjercicioEnProgresoScreen extends StatefulWidget {
  final EjercicioPsicologico ejercicio;

  const EjercicioEnProgresoScreen({
    super.key,
    required this.ejercicio,
  });

  @override
  State<EjercicioEnProgresoScreen> createState() =>
      _EjercicioEnProgresoScreenState();
}

class _EjercicioEnProgresoScreenState extends State<EjercicioEnProgresoScreen>
    with TickerProviderStateMixin {
  final EjerciciosService _ejerciciosService = EjerciciosService();
  late AnimationController _timerController;
  late AnimationController _breathingController;

  int _tiempoRestante = 0;
  int _pasoActual = 0;
  bool _ejercicioIniciado = false;
  bool _ejercicioCompletado = false;
  DateTime? _tiempoInicio;

  @override
  void initState() {
    super.initState();
    _tiempoRestante = widget.ejercicio.duracionMinutos * 60;

    _timerController = AnimationController(
      duration: Duration(seconds: widget.ejercicio.duracionMinutos * 60),
      vsync: this,
    );

    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    if (widget.ejercicio.tipo == TipoEjercicio.respiracion) {
      _breathingController.repeat(reverse: true);
    }
  }

  void _iniciarEjercicio() {
    setState(() {
      _ejercicioIniciado = true;
      _tiempoInicio = DateTime.now();
    });

    _timerController.forward();

    // Timer para actualizar el tiempo restante
    Stream.periodic(const Duration(seconds: 1)).listen((event) {
      if (_ejercicioIniciado && !_ejercicioCompletado && mounted) {
        setState(() {
          _tiempoRestante--;
          if (_tiempoRestante <= 0) {
            _completarEjercicio();
          }
        });
      }
    });
  }

  void _completarEjercicio() async {
    if (_ejercicioCompletado) return;

    setState(() {
      _ejercicioCompletado = true;
    });

    final duracionReal = _tiempoInicio != null
        ? DateTime.now().difference(_tiempoInicio!).inMinutes
        : widget.ejercicio.duracionMinutos;

    // Mostrar diálogo de finalización
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          EjercicioCompletadoDialog(ejercicio: widget.ejercicio),
    );

    if (resultado != null) {
      try {
        await _ejerciciosService.registrarProgreso(
          idEjercicio: widget.ejercicio.id!,
          duracionReal: duracionReal,
          estado: EstadoCompletado.completado,
          puntuacion: resultado['puntuacion'],
          notas: resultado['notas'],
          emocion: resultado['emocion'],
        );

        // Mostrar la emoción detectada si existe
        if (resultado['emocion'] != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ Emoción detectada: ${resultado['emocion'].toUpperCase()}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true); // Indicar que se completó
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar progreso: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.ejercicio.tipo.color.withOpacity(0.1),
      appBar: AppBar(
        title: Text(widget.ejercicio.titulo),
        backgroundColor: widget.ejercicio.tipo.color,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _mostrarDialogoSalir(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Timer circular
              Expanded(
                flex: 2,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: _ejercicioIniciado
                              ? 1 -
                                  (_tiempoRestante /
                                      (widget.ejercicio.duracionMinutos * 60))
                              : 0,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              widget.ejercicio.tipo.color),
                        ),
                      ),
                      if (widget.ejercicio.tipo == TipoEjercicio.respiracion &&
                          _ejercicioIniciado)
                        AnimatedBuilder(
                          animation: _breathingController,
                          builder: (context, child) {
                            return Container(
                              width: 120 + (_breathingController.value * 40),
                              height: 120 + (_breathingController.value * 40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.ejercicio.tipo.color
                                    .withOpacity(0.3),
                              ),
                            );
                          },
                        ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatearTiempo(_tiempoRestante),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: widget.ejercicio.tipo.color,
                            ),
                          ),
                          if (widget.ejercicio.tipo ==
                                  TipoEjercicio.respiracion &&
                              _ejercicioIniciado)
                            AnimatedBuilder(
                              animation: _breathingController,
                              builder: (context, child) {
                                final fase = _breathingController.value < 0.5
                                    ? 'Inhala'
                                    : 'Exhala';
                                return Text(
                                  fase,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: widget.ejercicio.tipo.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Instrucciones
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paso ${_pasoActual + 1} de ${widget.ejercicio.instrucciones.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          _pasoActual < widget.ejercicio.instrucciones.length
                              ? widget.ejercicio.instrucciones[_pasoActual]
                              : 'Ejercicio completado',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (_ejercicioIniciado &&
                          _pasoActual <
                              widget.ejercicio.instrucciones.length - 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _pasoActual = (_pasoActual + 1).clamp(0,
                                    widget.ejercicio.instrucciones.length - 1);
                              });
                            },
                            child: const Text('Siguiente paso'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Botón de control
              const SizedBox(height: 20),
              if (!_ejercicioIniciado)
                ElevatedButton(
                  onPressed: _iniciarEjercicio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.ejercicio.tipo.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Comenzar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              else if (!_ejercicioCompletado)
                ElevatedButton(
                  onPressed: _completarEjercicio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Completar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoSalir() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir del ejercicio?'),
        content: const Text(
            '¿Estás seguro de que quieres salir? Se perderá el progreso actual.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Salir del ejercicio
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timerController.dispose();
    _breathingController.dispose();
    super.dispose();
  }
}

// Diálogo de ejercicio completado
class EjercicioCompletadoDialog extends StatefulWidget {
  final EjercicioPsicologico ejercicio;

  const EjercicioCompletadoDialog({
    super.key,
    required this.ejercicio,
  });

  @override
  State<EjercicioCompletadoDialog> createState() =>
      _EjercicioCompletadoDialogState();
}

class _EjercicioCompletadoDialogState extends State<EjercicioCompletadoDialog> {
  int _puntuacion = 5;
  final TextEditingController _notasController = TextEditingController();
  bool _isAnalizando = false;
  String _emocionDetectada = '';

  /// Analiza la emoción basada en los datos del ejercicio
  Future<void> _analizarEmocion() async {
    // Evitar múltiples análisis simultáneos
    if (_isAnalizando) return;

    // Limpiar estado previo
    setState(() {
      _isAnalizando = true;
      _emocionDetectada = '';
    });

    // Llamar al servicio de análisis emocional
    try {
      final emocion = await AnalisisEjercicioService.analizarEmocionEjercicio(
          ejercicio: widget.ejercicio,
          puntuacion: _puntuacion,
          notas: _notasController.text.trim().isEmpty
              ? null
              : _notasController.text.trim(),
          uid: FirebaseAuth.instance.currentUser?.uid);

      // Actualizar el estado con la emoción detectada
      if (mounted) {
        setState(() {
          _emocionDetectada = emocion;
          _isAnalizando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emocionDetectada = 'neutral';
          _isAnalizando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al analizar emoción: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '¡Ejercicio Completado!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Has completado "${widget.ejercicio.titulo}" exitosamente.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Cómo te sientes? (1-10)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Usar Wrap para evitar overflow de los números
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(10, (index) {
                final valor = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _puntuacion = valor),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _puntuacion == valor
                          ? widget.ejercicio.tipo.color
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                      boxShadow: _puntuacion == valor
                          ? [
                              BoxShadow(
                                color: widget.ejercicio.tipo.color
                                    .withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        valor.toString(),
                        style: TextStyle(
                          color: _puntuacion == valor
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text(
              'Notas (opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notasController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '¿Cómo te sentiste durante el ejercicio?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Sección de análisis emocional
            if (_emocionDetectada.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emoción detectada:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _emocionDetectada.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (_emocionDetectada.isEmpty)
              ElevatedButton.icon(
                onPressed: _isAnalizando ? null : _analizarEmocion,
                icon: _isAnalizando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology),
                label:
                    Text(_isAnalizando ? 'Analizando...' : 'Analizar emoción'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'puntuacion': _puntuacion,
              'notas': _notasController.text.trim().isEmpty
                  ? null
                  : _notasController.text.trim(),
              'emocion':
                  _emocionDetectada.isNotEmpty ? _emocionDetectada : null,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.ejercicio.tipo.color,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }
}
