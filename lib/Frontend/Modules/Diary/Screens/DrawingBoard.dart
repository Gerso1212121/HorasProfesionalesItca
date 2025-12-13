// lib/Frontend/Modules/Diary/Widget/drawing_board.dart
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingBoard extends StatefulWidget {
  final Function(Uint8List?) onDrawingComplete;
  final Uint8List? initialDrawing;

  const DrawingBoard({
    super.key,
    required this.onDrawingComplete,
    this.initialDrawing,
  });

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  final GlobalKey _drawingKey = GlobalKey();

  // Para el dibujo
  List<DrawingStroke> _strokes = [];
  List<DrawingStroke> _undoStack = [];
  Color _drawingColor = Colors.black;
  double _strokeWidth = 3.0;

  @override
  void initState() {
    super.initState();
    // Si hay un dibujo inicial, cargarlo
    if (widget.initialDrawing != null) {
      // Aquí podrías cargar el dibujo inicial si fuera necesario
    }
  }

  void _startNewStroke(Offset position) {
    setState(() {
      _strokes.add(DrawingStroke(
        color: _drawingColor,
        width: _strokeWidth,
        points: [position],
      ));
      // Limpiar el stack de deshacer cuando se hace un nuevo trazo
      _undoStack.clear();
    });
  }

  void _updateCurrentStroke(Offset position) {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.last.points.add(position);
      });
    }
  }

  void _endCurrentStroke() {
    // Puedes agregar lógica adicional aquí si es necesario
  }

  void _undoLastStroke() {
    if (_strokes.isNotEmpty) {
      setState(() {
        // Guardar el último trazo en la pila de deshacer
        _undoStack.add(_strokes.removeLast());
      });
    }
  }

  void _redoLastStroke() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _strokes.add(_undoStack.removeLast());
      });
    }
  }

  void _clearDrawing() {
    setState(() {
      _strokes.clear();
      _undoStack.clear();
    });
  }

  Future<Uint8List?> _captureDrawing() async {
    try {
      if (_strokes.isEmpty) return null;

      final RenderRepaintBoundary boundary = _drawingKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      print("Error al capturar dibujo: $e");
    }
    return null;
  }

// En DrawingBoard.dart, modifica el método _saveAndExit:
  void _saveAndExit() async {
    final drawingBytes = await _captureDrawing();

    // Verifica si hay algo que guardar
    if (drawingBytes != null) {
      print("🖌️ Dibujo capturado: ${drawingBytes.length} bytes");
      // Usa Navigator.pop con el resultado
      Navigator.pop(context, drawingBytes);
    } else {
      print("⚠️ No hay dibujo para guardar");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
// Y también modifica el botón de cerrar:
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () {
            // Pregunta al usuario si quiere descartar cambios
            if (_strokes.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Descartar dibujo'),
                  content: const Text(
                      '¿Estás seguro de que quieres descartar el dibujo?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Cierra el diálogo
                        Navigator.pop(context); // Cierra el DrawingBoard
                      },
                      child: const Text('Descartar',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Pizarra de dibujo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveAndExit,
            icon: const Icon(Icons.check, color: Colors.blue, size: 20),
            label: const Text(
              'Listo',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas de dibujo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: RepaintBoundary(
                    key: _drawingKey,
                    child: GestureDetector(
                      onPanStart: (details) {
                        final localPosition = details.localPosition;
                        _startNewStroke(localPosition);
                      },
                      onPanUpdate: (details) {
                        final localPosition = details.localPosition;
                        _updateCurrentStroke(localPosition);
                      },
                      onPanEnd: (details) {
                        _endCurrentStroke();
                      },
                      child: Container(
                        color: Colors.white,
                        child: CustomPaint(
                          painter: DrawingPainter(_strokes),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Indicador de tamaño
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Área de dibujo: 300 x 300',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Herramientas de dibujo
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                  child: Column(
                children: [
                  // Paleta de colores
                  _buildColorPalette(),

                  // Herramientas de grosor y acciones
                  _buildToolbar(),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    final List<Color> colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.brown,
      Colors.pink,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Color:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildColorCircle(colors[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _drawingColor = color;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _drawingColor == color ? Colors.blue : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _drawingColor == color
            ? const Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Grosor del pincel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grosor:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Row(
                children: [
                  _buildStrokeWidthButton(2.0, 'Fino'),
                  const SizedBox(width: 12),
                  _buildStrokeWidthButton(4.0, 'Medio'),
                  const SizedBox(width: 12),
                  _buildStrokeWidthButton(6.0, 'Grueso'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Acciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.undo,
                label: 'Deshacer',
                onPressed: _undoLastStroke,
                isEnabled: _strokes.isNotEmpty,
                color: const Color(0xFF4285F4),
              ),
              _buildActionButton(
                icon: Icons.redo,
                label: 'Rehacer',
                onPressed: _redoLastStroke,
                isEnabled: _undoStack.isNotEmpty,
                color: const Color(0xFF34A853),
              ),
              _buildActionButton(
                icon: Icons.delete,
                label: 'Borrar',
                onPressed: _clearDrawing,
                isEnabled: _strokes.isNotEmpty,
                color: const Color(0xFFEA4335),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrokeWidthButton(double width, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _strokeWidth = width;
        });
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _strokeWidth == width
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _strokeWidth == width ? Colors.blue : Colors.grey[300]!,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: width * 4,
                height: width,
                decoration: BoxDecoration(
                  color: _drawingColor,
                  borderRadius: BorderRadius.circular(width / 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _strokeWidth == width ? Colors.blue : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isEnabled,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(isEnabled ? 0.1 : 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: isEnabled ? color : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: IconButton(
            onPressed: isEnabled ? onPressed : null,
            icon: Icon(
              icon,
              color: isEnabled ? color : Colors.grey[400],
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isEnabled ? color : Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class DrawingStroke {
  final Color color;
  final double width;
  final List<Offset> points;

  DrawingStroke({
    required this.color,
    required this.width,
    required this.points,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
