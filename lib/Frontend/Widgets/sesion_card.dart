import 'package:flutter/material.dart';
import '../../App/Data/Models/sesion_chat.dart';
import '../../App/Services/Services_Cifrado.dart';
import 'dart:developer' as developer;

class SesionCard extends StatefulWidget {
  final SesionChat sesion;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SesionCard({
    super.key,
    required this.sesion,
    this.onTap,
    this.onDelete,
  });

  @override
  State<SesionCard> createState() => _SesionCardState();
}

class _SesionCardState extends State<SesionCard> {
  @override
  Widget build(BuildContext context) {
    // Usar título dinámico si existe, sino usar resumen
    final titulo = widget.sesion.tituloDinamico ?? widget.sesion.resumen;

    // Formatear fecha para mostrar de forma más amigable
    String fechaFormateada = widget.sesion.fecha;
    try {
      final fecha = DateTime.parse(widget.sesion.fecha);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fecha);

      if (diferencia.inDays == 0) {
        fechaFormateada = "Hoy";
      } else if (diferencia.inDays == 1) {
        fechaFormateada = "Ayer";
      } else if (diferencia.inDays < 7) {
        fechaFormateada = "Hace ${diferencia.inDays} días";
      } else {
        fechaFormateada = "${fecha.day}/${fecha.month}/${fecha.year}";
      }
    } catch (e) {
      // Si hay error parseando la fecha, usar la original
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      child: ListTile(
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💬 ${widget.sesion.mensajes.length} mensajes',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              '📅 $fechaFormateada',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: widget.onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onDelete,
                tooltip: "Eliminar conversación",
              )
            : null,
        onTap: widget.onTap,
      ),
    );
  }
}
