import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:url_launcher/url_launcher.dart';



//* Tomamos los modulos de la base de datos de supabase.
class ModuloDetailScreen extends StatefulWidget {
  final Map<String, dynamic> modulo;

  const ModuloDetailScreen({
    Key? key,
    required this.modulo,
  }) : super(key: key);

  @override
  State<ModuloDetailScreen> createState() => _ModuloDetailScreenState();
}

class _ModuloDetailScreenState extends State<ModuloDetailScreen> {
  List<Map<String, dynamic>> _imagenes = [];
  bool _isLoadingImages = true;

  // Markdown stylesheet con fuentes mixtas (Inter para contenido, Handwriting para títulos)
  final MarkdownStyleSheet _markdownStyleSheet = MarkdownStyleSheet(
    h1: GoogleFonts.itim(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1A1A1A),
      height: 1.3,
    ),
    h2: GoogleFonts.itim(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1A1A1A),
      height: 1.3,
    ),
    h3: GoogleFonts.itim(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFF86A8E7),
      height: 1.3,
    ),
    p: GoogleFonts.inter(
      fontSize: 14,
      color: const Color(0xFF404040),
      height: 1.6,
    ),
    strong: const TextStyle(fontWeight: FontWeight.bold),
    em: const TextStyle(fontStyle: FontStyle.italic),
    blockquote: GoogleFonts.itim(
      fontSize: 14,
      fontStyle: FontStyle.italic,
      color: const Color(0xFF86A8E7),
    ),
    blockquoteDecoration: BoxDecoration(
      color: const Color(0xFFF0F9FF),
      borderRadius: BorderRadius.circular(8),
      border: Border(
        left: BorderSide(color: const Color(0xFF86A8E7), width: 4),
      ),
    ),
    code: GoogleFonts.sourceCodePro(
      fontSize: 14,
      color: const Color(0xFFD32F2F),
      backgroundColor: const Color(0xFFF0F9FF),
    ),
    codeblockDecoration: BoxDecoration(
      color: const Color(0xFFF0F9FF),
      borderRadius: BorderRadius.circular(8),
    ),
    listBullet: GoogleFonts.itim(
      fontSize: 14,
      color: const Color(0xFF86A8E7),
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadModuloImages();
  }

  Future<void> _loadModuloImages() async {
    try {
      final db = DatabaseHelper.instance;
      final imagenes =
          await db.readModuloImagenes(moduloId: widget.modulo['id']);
      setState(() {
        _imagenes = imagenes;
        _isLoadingImages = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingImages = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDFF),
      body: CustomScrollView(
        slivers: [
          // App Bar mejorado
          _buildAppBar(),
          // Contenido principal
          _buildContent(),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 150.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF86A8E7),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16, left: 0),
        title: Text(
          widget.modulo['titulo'] ?? 'Módulo',
          style: GoogleFonts.itim(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        background: Container(
          child: Center(
            child: Icon(
              Icons.psychology_outlined,
              size: 70,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tarjeta de información del módulo
            _buildInfoCard(),
            const SizedBox(height: 20),
            // Imágenes del módulo (si las hay)
            if (!_isLoadingImages && _imagenes.isNotEmpty)
              _buildImagesSection(),
            // Contenido del módulo
            _buildModuleContent(),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Información del módulo',
              style: GoogleFonts.itim(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.calendar_today,
              label: 'Creado',
              value: _formatDate(widget.modulo['fecha_creacion']),
            ),
            if (widget.modulo['fecha_actualizacion'] !=
                widget.modulo['fecha_creacion'])
              _buildInfoItem(
                icon: Icons.update,
                label: 'Actualizado',
                value: _formatDate(widget.modulo['fecha_actualizacion']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF86A8E7).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF86A8E7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF86A8E7),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.itim(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF404040),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: const Color(0xFF4CAF50),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Recursos visuales',
                  style: GoogleFonts.itim(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imagenes.length,
                itemBuilder: (context, index) {
                  final imagen = _imagenes[index];
                  return GestureDetector(
                    onTap: () => _showImageDialog(imagen['url']),
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imagen['url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF0F9FF),
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Color(0xFF86A8E7),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF86A8E7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: const Color(0xFF86A8E7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Contenido del módulo',
                    style: GoogleFonts.itim(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MarkdownBody(
                data: widget.modulo['contenido'] ?? 'Sin contenido disponible',
                styleSheet: _markdownStyleSheet,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    _launchURL(href);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: const Color(0xFFF0F9FF),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Color(0xFF86A8E7),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


String _extractYouTubeVideoId(String url) {
  // Patrones comunes de YouTube
  final patterns = [
    RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/v/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
  ];
  
  for (var pattern in patterns) {
    final match = pattern.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
  }
  
  return '';
}

Future<void> _launchURL(String url) async {
  try {
    // Log para depuración
    print('Intentando abrir URL: $url');
    
    String processedUrl = url.trim();
    
    // Para YouTube, simplificar la URL
    if (processedUrl.contains('youtube.com') || processedUrl.contains('youtu.be')) {
      final videoId = _extractYouTubeVideoId(processedUrl);
      if (videoId.isNotEmpty) {
        // Usar URL simple de YouTube
        processedUrl = 'https://www.youtube.com/watch?v=$videoId';
      }
    }
    
    // Asegurar protocolo HTTPS
    if (!processedUrl.startsWith('http')) {
      processedUrl = 'https://$processedUrl';
    }
    
    final uri = Uri.parse(processedUrl);
    
    // Método 1: Intentar con externalNonBrowserApplication (el más confiable)
    if (await canLaunchUrl(uri)) {
      print('canLaunchUrl retornó TRUE para: $processedUrl');
      await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      return;
    } else {
      print('canLaunchUrl retornó FALSE para: $processedUrl');
    }
    
    // Método 2: Si falla, intentar lanzar directamente
    try {
      // Intentar lanzar sin verificar primero
      await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      return;
    } catch (e) {
      print('Error al lanzar directamente: $e');
    }
    
    // Método 3: Intentar con externalApplication
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return;
    } catch (e) {
      print('Error con externalApplication: $e');
    }
    
    // Si todo falla, mostrar opción para copiar
    _showURLOptions(context, url);
    
  } catch (e, stackTrace) {
    print('Error en _launchURL: $e');
    print('Stack trace: $stackTrace');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

void _showURLOptions(BuildContext context, String url) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('Abrir en navegador'),
              onTap: () {
                Navigator.pop(context);
                _openInBrowser(url);
              },
            ),

          ],
        ),
      );
    },
  );
}

Future<void> _openInBrowser(String url) async {
  try {
    String processedUrl = url;
    if (!processedUrl.startsWith('http')) {
      processedUrl = 'https://$processedUrl';
    }
    
    final uri = Uri.parse(processedUrl);
    
    // Forzar apertura en navegador web
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  } catch (e) {
    print('Error abriendo en navegador: $e');
  }
}


  String _formatDate(String? dateString) {
    if (dateString == null) return 'Sin fecha';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }
}