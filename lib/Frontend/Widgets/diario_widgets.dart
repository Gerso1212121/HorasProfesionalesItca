import 'package:ai_app_tests/App/Data/Models/diario_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Widget para mostrar una entrada del diario
class DiarioEntryCard extends StatelessWidget {
  final DiarioEntry entrada;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DiarioEntryCard({
    super.key,
    required this.entrada,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con fecha y acciones
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy')
                        .format(DateTime.parse(entrada.fecha)),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Eliminar',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),

              // Categoría y estado de ánimo
              if (entrada.categoria != null || entrada.estadoAnimo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(
                    children: [
                      if (entrada.categoria != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoriaColor(entrada.categoria!)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getCategoriaColor(entrada.categoria!)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            entrada.categoria!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getCategoriaColor(entrada.categoria!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (entrada.estadoAnimo != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getEstadoAnimoEmoji(entrada.estadoAnimo!),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entrada.estadoAnimo!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Contenido
              Text(
                entrada.contenido,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Valoración
              if (entrada.valoracion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < entrada.valoracion!
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        );
                      }),
                    ],
                  ),
                ),

              // Etiquetas
              if (entrada.etiquetas != null && entrada.etiquetas!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: entrada.etiquetas!.map((etiqueta) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#$etiqueta',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'personal':
        return Colors.purple;
      case 'académico':
        return Colors.blue;
      case 'salud':
        return Colors.green;
      case 'relaciones':
        return Colors.pink;
      case 'trabajo':
        return Colors.orange;
      case 'reflexión':
        return Colors.indigo;
      case 'metas':
        return Colors.teal;
      case 'gratitud':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoAnimoEmoji(String estadoAnimo) {
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
        return '😐';
    }
  }
}

// Widget para selector de estado de ánimo
class EstadoAnimoSelector extends StatelessWidget {
  final String? estadoSeleccionado;
  final Function(String?) onChanged;

  const EstadoAnimoSelector({
    super.key,
    this.estadoSeleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cómo te sientes?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EstadoAnimo.values.map((estado) {
            final isSelected = estadoSeleccionado == estado.nombre;
            return GestureDetector(
              onTap: () => onChanged(isSelected ? null : estado.nombre),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.orange
                        : Colors.grey.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      estado.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      estado.nombre,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.orange : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Widget para selector de categoría
class CategoriaSelector extends StatelessWidget {
  final String? categoriaSeleccionada;
  final Function(String?) onChanged;

  const CategoriaSelector({
    super.key,
    this.categoriaSeleccionada,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CategoriaEntrada.values.map((categoria) {
            final isSelected = categoriaSeleccionada == categoria.nombre;
            return GestureDetector(
              onTap: () => onChanged(isSelected ? null : categoria.nombre),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getCategoriaColor(categoria.nombre)
                          .withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _getCategoriaColor(categoria.nombre)
                        : Colors.grey.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  categoria.nombre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? _getCategoriaColor(categoria.nombre)
                        : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'personal':
        return Colors.purple;
      case 'académico':
        return Colors.blue;
      case 'salud':
        return Colors.green;
      case 'relaciones':
        return Colors.pink;
      case 'trabajo':
        return Colors.orange;
      case 'reflexión':
        return Colors.indigo;
      case 'metas':
        return Colors.teal;
      case 'gratitud':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

// Widget para valoración con estrellas
class ValoracionSelector extends StatelessWidget {
  final int? valoracion;
  final Function(int?) onChanged;

  const ValoracionSelector({
    super.key,
    this.valoracion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Valoración del día',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ...List.generate(5, (index) {
              final estrella = index + 1;
              return GestureDetector(
                onTap: () =>
                    onChanged(valoracion == estrella ? null : estrella),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    valoracion != null && estrella <= valoracion!
                        ? Icons.star
                        : Icons.star_border,
                    size: 32,
                    color: Colors.amber,
                  ),
                ),
              );
            }),
            if (valoracion != null) ...[
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(
                  Icons.clear,
                  size: 24,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// Widget para mostrar estadísticas
class DiarioStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const DiarioStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas del Diario',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Entradas',
                    stats['totalEntradas']?.toString() ?? '0',
                    Icons.book,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Este Mes',
                    stats['entradasEsteMes']?.toString() ?? '0',
                    Icons.calendar_month,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Racha',
                    '${stats['rachaEscritura'] ?? 0} días',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Valoración',
                    '${(stats['promedioValoracion'] ?? 0.0).toStringAsFixed(1)} ⭐',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            if (stats['estadoAnimoMasComun'] != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado de ánimo más común:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats['estadoAnimoMasComun'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Widget para estado vacío
class EmptyDiarioState extends StatelessWidget {
  final VoidCallback? onCreateFirst;

  const EmptyDiarioState({
    super.key,
    this.onCreateFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tu diario está vacío',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Comienza a escribir tu primera entrada!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (onCreateFirst != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateFirst,
              icon: const Icon(Icons.add),
              label: const Text('Escribir primera entrada'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
