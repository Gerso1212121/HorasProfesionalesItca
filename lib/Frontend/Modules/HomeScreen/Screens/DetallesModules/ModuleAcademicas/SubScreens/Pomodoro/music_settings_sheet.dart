import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleAcademicas/SubScreens/Pomodoro/models/music_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart'; // Asegúrate de añadir esta dependencia

class MusicSettingsSheet extends StatefulWidget {
  final MusicSettings settings;
  final Function(MusicSettings) onSettingsChanged;
  final Function() onPlayTest;
  final Function() onStopTest;
  final Color accentColor;

  const MusicSettingsSheet({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onPlayTest,
    required this.onStopTest,
    required this.accentColor,
  }) : super(key: key);

  @override
  _MusicSettingsSheetState createState() => _MusicSettingsSheetState();
}

class _MusicSettingsSheetState extends State<MusicSettingsSheet> {
  late MusicSettings _localSettings;
  late AudioPlayer _audioPlayer; // Para probar la música
  List<File> _userMusicFiles = [];

  @override
  void initState() {
    super.initState();
    _localSettings = MusicSettings()
      ..isEnabled = widget.settings.isEnabled
      ..isPlaying = widget.settings.isPlaying
      ..volume = widget.settings.volume
      ..selectedType = 'local'
      ..selectedSource = widget.settings.selectedSource;

    _audioPlayer = AudioPlayer();

    // Cargar archivos existentes si los hay
    _loadExistingFiles();
  }

  void _loadExistingFiles() async {
    // Si hay una fuente guardada que no está en las opciones locales,
    // podría ser un archivo del usuario
    if (_localSettings.selectedSource.isNotEmpty &&
        !MusicSettings.localMusicOptions
            .any((option) => option.source == _localSettings.selectedSource)) {
      // Verificar si el archivo aún existe
      final file = File(_localSettings.selectedSource);
      if (await file.exists()) {
        setState(() {
          _userMusicFiles.add(file);
        });
      }
    }
  }

  void _updateSettings() {
    widget.onSettingsChanged(_localSettings);
  }

Future<void> _selectMusicFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // 👈 OBLIGATORIO
      allowMultiple: true,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg'], // 👈 AHORA SÍ SE PERMITE
    );

    if (result != null) {
      setState(() {
        _userMusicFiles.addAll(result.files.map((file) => File(file.path!)));

        // Seleccionar el primer archivo por defecto
        if (_userMusicFiles.isNotEmpty &&
            _localSettings.selectedSource.isEmpty) {
          _localSettings.selectedSource = _userMusicFiles.first.path;
          _updateSettings();
        }
      });
    }
  } catch (e) {
    print("Error al seleccionar archivos: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al seleccionar archivos: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  Future<void> _playTestMusic(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un archivo de música primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(_localSettings.volume);
      await _audioPlayer.setSourceDeviceFile(filePath);
      await _audioPlayer.resume();

      setState(() {
        _localSettings.isPlaying = true;
      });
      _updateSettings();

      // Actualizar el widget padre
      widget.onPlayTest();
    } catch (e) {
      print("Error al reproducir: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reproducir el archivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopTestMusic() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _localSettings.isPlaying = false;
      });
      _updateSettings();

      // Actualizar el widget padre
      widget.onStopTest();
    } catch (e) {
      print("Error al detener: $e");
    }
  }

  void _removeMusicFile(File file) {
    setState(() {
      _userMusicFiles.remove(file);

      // Si el archivo eliminado era el seleccionado, limpiar la selección
      if (_localSettings.selectedSource == file.path) {
        _localSettings.selectedSource = '';
        _updateSettings();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Configuración de Música',
                style: GoogleFonts.itim(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMusicToggle(),
          const SizedBox(height: 20),
          _buildSelectMusicButton(),
          const SizedBox(height: 20),
          _buildMusicList(),
          const SizedBox(height: 20),
          _buildVolumeControl(),
          const SizedBox(height: 20),
          _buildTestButton(),
          const SizedBox(height: 10),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildMusicToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Música de fondo',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Switch(
          value: _localSettings.isEnabled,
          activeColor: widget.accentColor,
          onChanged: (value) {
            setState(() {
              _localSettings.isEnabled = value;
            });
            _updateSettings();
          },
        ),
      ],
    );
  }

  Widget _buildSelectMusicButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _selectMusicFile,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Seleccionar archivos MP3',
          style: GoogleFonts.itim(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMusicList() {
    final allMusicOptions = [
      ...MusicSettings.localMusicOptions,
      ..._userMusicFiles.map((file) => MusicOption(
            name: file.path.split('/').last,
            source: file.path,
            type: 'local', // <--- ESTE FALTABA
          )),
    ];

    if (allMusicOptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            'Selecciona archivos MP3 o usa música predeterminada',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seleccionar música:',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: allMusicOptions.length,
            itemBuilder: (context, index) {
              final option = allMusicOptions[index];
              return _buildMusicItem(option);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMusicItem(MusicOption option) {
    final isUserFile =
        _userMusicFiles.any((file) => file.path == option.source);
    final isSelected = _localSettings.selectedSource == option.source;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? widget.accentColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? widget.accentColor : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.check_circle : Icons.music_note,
          color: isSelected ? widget.accentColor : Colors.grey[400],
        ),
        title: Text(
          option.name,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isSelected ? widget.accentColor : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          isUserFile ? 'Archivo local' : 'Música predeterminada',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isSelected
                ? widget.accentColor.withOpacity(0.8)
                : Colors.grey[500],
          ),
        ),
        trailing: isUserFile
            ? IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red[300],
                onPressed: () {
                  final file = File(option.source);
                  _removeMusicFile(file);
                },
              )
            : null,
        onTap: () {
          setState(() {
            _localSettings.selectedSource = option.source;
          });
          _updateSettings();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildVolumeControl() {
    return Row(
      children: [
        Icon(Icons.volume_down, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Volumen: ${(_localSettings.volume * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              Slider(
                value: _localSettings.volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _localSettings.volume = value;
                  });
                  _updateSettings();

                  // Actualizar volumen en reproducción actual
                  if (_localSettings.isPlaying) {
                    _audioPlayer.setVolume(value);
                  }
                },
                activeColor: widget.accentColor,
                inactiveColor: Colors.grey[300],
              ),
            ],
          ),
        ),
        Icon(Icons.volume_up, size: 20, color: Colors.grey[600]),
      ],
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          if (_localSettings.isPlaying) {
            _stopTestMusic();
          } else {
            _playTestMusic(_localSettings.selectedSource);
          }
        },
        icon: Icon(
          _localSettings.isPlaying ? Icons.stop : Icons.play_arrow,
          color: Colors.white,
        ),
        label: Text(
          _localSettings.isPlaying ? 'Detener Música' : 'Probar Música',
          style: GoogleFonts.itim(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Cerrar',
          style: GoogleFonts.itim(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ),
    );
  }
}
