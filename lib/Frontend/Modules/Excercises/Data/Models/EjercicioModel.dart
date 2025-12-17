import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum TipoEjercicio {
  respiracion,
  meditacion,
  cognitivo,
  fisico,
  otro
}

class EjercicioModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String categoria; // Ej: 'Reducción de Ansiedad', 'Gestión de Estrés'
  final TipoEjercicio tipo;
  final int duracionMinutos;
  final String dificultad;
  final List<String> objetivos;
  final List<String> instrucciones;
  final DateTime? fechaCreacion;

  EjercicioModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.tipo,
    required this.duracionMinutos,
    required this.dificultad,
    required this.objetivos,
    required this.instrucciones,
    this.fechaCreacion,
  });

  factory EjercicioModel.fromJson(Map<String, dynamic> json) {
    return EjercicioModel(
      id: json['id_ejercicio'] as int,
      titulo: json['titulo'] ?? 'Sin título',
      descripcion: json['descripcion'] ?? '',
      categoria: json['categoria'] ?? 'General',
      tipo: _parseTipo(json['tipo']),
      duracionMinutos: json['duracion_minutos'] ?? 5,
      dificultad: json['dificultad'] ?? 'Media',
      objetivos: _parseList(json['objetivos']),
      instrucciones: _parseList(json['instrucciones']),
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.tryParse(json['fecha_creacion'].toString()) 
          : null,
    );
  }

  static TipoEjercicio _parseTipo(String? tipoStr) {
    switch (tipoStr?.toLowerCase()) {
      case 'respiracion': return TipoEjercicio.respiracion;
      case 'meditacion': return TipoEjercicio.meditacion;
      case 'cognitivo': return TipoEjercicio.cognitivo;
      case 'fisico': return TipoEjercicio.fisico;
      default: return TipoEjercicio.otro;
    }
  }

  static List<String> _parseList(dynamic rawData) {
    if (rawData == null) return [];
    if (rawData is List) return rawData.map((e) => e.toString()).toList();
    if (rawData is String) {
      return rawData.split('\n').where((e) => e.trim().isNotEmpty).toList();
    }
    return [];
  }

  // =========================================================
  // 🔥 LÓGICA VISUAL ACTUALIZADA (Colores Vibrantes) 🔥
  // =========================================================
  
  // Basado en las categorías de tu captura de pantalla
  Color get colorTema {
    final cat = categoria.toLowerCase();
    
    // 1. Reducción de Ansiedad -> Verde Menta
    if (cat.contains('ansiedad')) return const Color(0xFF4ADE80);
    
    // 2. Gestión de Estrés -> Púrpura (Calma mental/Foco)
    if (cat.contains('estrés') || cat.contains('estres')) return const Color(0xFFA855F7);
    
    // 3. Bienestar General -> Ámbar/Amarillo (Energía)
    if (cat.contains('bienestar')) return const Color(0xFFFFB74D);
    
    // 4. Relajación -> Azul Cielo (Aire/Tranquilidad)
    if (cat.contains('relajación') || cat.contains('relajacion')) return const Color(0xFF38BDF8);
    
    // 5. Emocional -> Naranja (Calidez)
    if (cat.contains('emocional')) return const Color(0xFFFB923C);
    
    // 6. Mejora de Autoestima -> Índigo (Confianza/Fuerza)
    if (cat.contains('autoestima')) return const Color(0xFF6366F1);
    
    // Fallback: Si no coincide, usamos el color basado en el Tipo
    return _getColorPorTipo();
  }

  IconData get icono {
    final cat = categoria.toLowerCase();
    
    // 1. Reducción de Ansiedad -> Hoja
    if (cat.contains('ansiedad')) return LucideIcons.leaf;
    
    // 2. Gestión de Estrés -> Ondas (Calma) o Cerebro
    if (cat.contains('estrés') || cat.contains('estres')) return LucideIcons.waves;
    
    // 3. Bienestar General -> Brillos
    if (cat.contains('bienestar')) return LucideIcons.sparkles;
    
    // 4. Relajación -> Nube
    if (cat.contains('relajación') || cat.contains('relajacion')) return LucideIcons.cloud;
    
    // 5. Emocional -> Corazón
    if (cat.contains('emocional')) return LucideIcons.heart;
    
    // 6. Mejora de Autoestima -> Estrella (Brillar)
    if (cat.contains('autoestima')) return LucideIcons.star;
    
    return _getIconoPorTipo();
  }

  // Fallbacks por si la categoría es nueva o desconocida
  Color _getColorPorTipo() {
    switch (tipo) {
      case TipoEjercicio.respiracion: return const Color(0xFF4ADE80); // Verde
      case TipoEjercicio.meditacion: return const Color(0xFF38BDF8); // Azul
      case TipoEjercicio.cognitivo: return const Color(0xFFA855F7); // Púrpura
      case TipoEjercicio.fisico: return const Color(0xFFFF9800); // Naranja
      default: return const Color(0xFFFFB74D); // Ámbar
    }
  }

  IconData _getIconoPorTipo() {
    switch (tipo) {
      case TipoEjercicio.respiracion: return LucideIcons.wind;
      case TipoEjercicio.meditacion: return LucideIcons.moon;
      case TipoEjercicio.cognitivo: return LucideIcons.brainCircuit;
      case TipoEjercicio.fisico: return LucideIcons.activity;
      default: return LucideIcons.sparkles;
    }
  }
}