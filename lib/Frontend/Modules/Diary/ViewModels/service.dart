import 'package:firebase_auth/firebase_auth.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:horas2/Frontend/Modules/Diary/model/DiarioModel.dart';
import 'package:intl/intl.dart';

class DiarioService {
  static final DiarioService _instance = DiarioService._internal();
  factory DiarioService() => _instance;
  DiarioService._internal();

  final _auth = FirebaseAuth.instance;
  final _dbHelper = DatabaseHelper.instance;

  // Obtener ID del estudiante actual
  Future<int> _getEstudianteId() async {
    final uid = _auth.currentUser?.uid;
    final email = _auth.currentUser?.email;
    if (uid == null) throw Exception('Usuario no autenticado');

    return await _dbHelper.getOrCreateEstudianteByUID(uid, email);
  }

  // Crear nueva entrada
  Future<DiarioModel> crearEntrada({
    required String contenido,
    String? categoria,
    String? estadoAnimo,
    int? valoracion,
    List<String>? etiquetas,
  }) async {
    if (contenido.trim().isEmpty) {
      throw Exception('El contenido no puede estar vacío');
    }

    final idEstudiante = await _getEstudianteId();
    final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final timestamp = DateTime.now().toIso8601String();

    final entrada = DiarioModel(
      fecha: fecha,
      contenido: contenido.trim(),
      timestamp: timestamp,
      idEstudiante: idEstudiante,
      categoria: categoria,
      estadoAnimo: estadoAnimo,
      valoracion: valoracion,
      etiquetas: etiquetas,
    );

    final id = await _dbHelper.insertDiarioEntryEnhanced(entrada.toMap());
    return entrada.copyWith(idDiario: id);
  }

  // Obtener todas las entradas del usuario
  Future<List<DiarioModel>> obtenerEntradas({
    String? categoria,
    String? estadoAnimo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? busqueda,
  }) async {
    try {
      final idEstudiante = await _getEstudianteId();
      final entradasMap = await _dbHelper.getDiarioEntriesFiltered(
        idEstudiante,
        categoria: categoria,
        estadoAnimo: estadoAnimo,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        busqueda: busqueda,
      );

      return entradasMap.map((map) => DiarioModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al cargar entradas: $e');
    }
  }

  // Actualizar entrada existente
  Future<DiarioModel> actualizarEntrada(DiarioModel entrada) async {
    if (entrada.idDiario == null) {
      throw Exception('ID de entrada requerido para actualizar');
    }

    if (entrada.contenido.trim().isEmpty) {
      throw Exception('El contenido no puede estar vacío');
    }

    final entradaActualizada = entrada.copyWith(
      contenido: entrada.contenido.trim(),
      timestamp: DateTime.now().toIso8601String(),
    );

    await _dbHelper.updateDiarioEntryEnhanced(
      entrada.idDiario!,
      entradaActualizada.toMap(),
    );

    return entradaActualizada;
  }

  // Eliminar entrada
  Future<void> eliminarEntrada(int idDiario) async {
    await _dbHelper.deleteDiarioEntry(idDiario);
  }

  // Obtener estadísticas del diario
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final idEstudiante = await _getEstudianteId();
      return await _dbHelper.getDiarioStatistics(idEstudiante);
    } catch (e) {
      return {
        'totalEntradas': 0,
        'entradasEsteMes': 0,
        'estadoAnimoMasComun': null,
        'categoriaMasUsada': null,
        'promedioValoracion': 0.0,
        'rachaEscritura': 0,
      };
    }
  }

  // Obtener entradas por mes para vista de calendario
  Future<Map<String, List<DiarioModel>>> obtenerEntradasPorMes(
      DateTime mes) async {
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0);

    final entradas = await obtenerEntradas(
      fechaInicio: inicioMes,
      fechaFin: finMes,
    );

    final entradasPorDia = <String, List<DiarioModel>>{};
    for (final entrada in entradas) {
      final fecha = entrada.fecha;
      if (!entradasPorDia.containsKey(fecha)) {
        entradasPorDia[fecha] = [];
      }
      entradasPorDia[fecha]!.add(entrada);
    }

    return entradasPorDia;
  }

  // Buscar entradas por texto
  Future<List<DiarioModel>> buscarEntradas(String query) async {
    if (query.trim().isEmpty) return [];

    return await obtenerEntradas(busqueda: query.trim());
  }

  // Obtener entradas recientes (últimos 7 días)
  Future<List<DiarioModel>> obtenerEntradasRecientes() async {
    final fechaInicio = DateTime.now().subtract(const Duration(days: 7));
    return await obtenerEntradas(fechaInicio: fechaInicio);
  }

  // Verificar si el usuario ha escrito hoy
  Future<bool> haEscritoHoy() async {
    final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final entradas = await obtenerEntradas();
    return entradas.any((entrada) => entrada.fecha == hoy);
  }

  // Obtener racha de escritura (días consecutivos)
  Future<int> obtenerRachaEscritura() async {
    final entradas = await obtenerEntradas();
    if (entradas.isEmpty) return 0;

    // Ordenar por fecha descendente
    entradas.sort((a, b) => b.fecha.compareTo(a.fecha));

    int racha = 0;
    DateTime fechaActual = DateTime.now();
    final formatoFecha = DateFormat('yyyy-MM-dd');

    for (final entrada in entradas) {
      final fechaEntrada = DateTime.parse(entrada.fecha);
      final fechaEsperada =
          formatoFecha.format(fechaActual.subtract(Duration(days: racha)));

      if (entrada.fecha == fechaEsperada) {
        racha++;
      } else {
        break;
      }
    }

    return racha;
  }

  // Exportar entradas a texto
  Future<String> exportarEntradasTexto({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final entradas = await obtenerEntradas(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );

    final buffer = StringBuffer();
    buffer.writeln('=== MI DIARIO ===');
    buffer.writeln(
        'Exportado el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln('Total de entradas: ${entradas.length}');
    buffer.writeln('');

    for (final entrada in entradas) {
      buffer.writeln(
          '--- ${DateFormat('dd/MM/yyyy').format(DateTime.parse(entrada.fecha))} ---');

      if (entrada.categoria != null) {
        buffer.writeln('Categoría: ${entrada.categoria}');
      }

      if (entrada.estadoAnimo != null) {
        buffer.writeln('Estado de ánimo: ${entrada.estadoAnimo}');
      }

      if (entrada.valoracion != null) {
        buffer.writeln('Valoración: ${'⭐' * entrada.valoracion!}');
      }

      buffer.writeln('');
      buffer.writeln(entrada.contenido);

      if (entrada.etiquetas != null && entrada.etiquetas!.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Etiquetas: ${entrada.etiquetas!.join(', ')}');
      }

      buffer.writeln('');
      buffer.writeln('${'=' * 50}');
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
