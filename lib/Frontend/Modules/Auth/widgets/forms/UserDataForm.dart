import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/widgets/Inputs/CustomTextField.dart';
import 'package:horas2/Frontend/widgets/CheckList/WheelSelectorField.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:horas2/Backend/Models/Auth/UserDataModelForm.dart';

class UserDataFormWidget extends StatefulWidget {
  final bool esItca;
  final String? correo;
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController telefonoController;
  final TextEditingController carnetController;
  final String? selectedSede;
  final String? selectedCarrera;
  final String? selectedAnio;
  
  // Nuevas claves para cada campo
  final GlobalKey? nombreKey;
  final GlobalKey? telefonoKey;
  final GlobalKey? carnetKey;
  final GlobalKey? sedeKey;
  final GlobalKey? carreraKey;
  final GlobalKey? anioKey;
  
  final Function(String?) onSedeSelected;
  final Function(String?) onCarreraSelected;
  final Function(String?) onAnioSelected;
  final Function(String?) validateNombre;
  final Function(String?) validateTelefono;
  final Function(String?) validateCarnet;
  final Function(String?) validateSede;
  final Function(String?) validateCarrera;
  final Function(String?) validateAnio;
  // Nueva propiedad para validar teléfono existente
  final Future<String?> Function(String?)? validateTelefonoExistente;

  const UserDataFormWidget({
    Key? key,
    required this.esItca,
    this.correo,
    required this.formKey,
    required this.nombreController,
    required this.telefonoController,
    required this.carnetController,
    required this.selectedSede,
    required this.selectedCarrera,
    required this.selectedAnio,
    // Nuevos parámetros para las claves
    this.nombreKey,
    this.telefonoKey,
    this.carnetKey,
    this.sedeKey,
    this.carreraKey,
    this.anioKey,
    required this.onSedeSelected,
    required this.onCarreraSelected,
    required this.onAnioSelected,
    required this.validateNombre,
    required this.validateTelefono,
    required this.validateCarnet,
    required this.validateSede,
    required this.validateCarrera,
    required this.validateAnio,
    this.validateTelefonoExistente,
  }) : super(key: key);

  @override
  State<UserDataFormWidget> createState() => _UserDataFormWidgetState();
}

class _UserDataFormWidgetState extends State<UserDataFormWidget> {
  bool _validatingTelefono = false;
  String? _telefonoError;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          
          if (widget.correo != null) _buildCorreoInfo(),
          
          // Campo Nombre con su clave
          KeyedSubtree(
            key: widget.nombreKey,
            child: CustomTextField(
              controller: widget.nombreController,
              fillColor: Colors.white,
              labelText: "Primer Nombre y Primer Apellido",
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              focusedColor: AppColors.primary,
              validator: (value) => widget.validateNombre(value),
              hintText: "Ej: Carlos Rodríguez",
            ),
          ),
          const SizedBox(height: 20),
          
          // Campo Teléfono con su clave
          KeyedSubtree(
            key: widget.telefonoKey,
            child: Stack(
              children: [
                CustomTextField(
                  controller: widget.telefonoController,
                  fillColor: Colors.white,
                  labelText: "Teléfono",
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  focusedColor: AppColors.primary,
                  // Validación que combina formato y existencia
                  validator: (value) {
                    // Primero validar formato
                    final formatError = widget.validateTelefono(value);
                    if (formatError != null) return formatError;
                    
                    // Luego verificar si hay error de existencia
                    if (_telefonoError != null) return _telefonoError;
                    
                    return null;
                  },
                  hintText: "Ej: 77778888",
                  maxLength: 8,
                  onChanged: (value) {
                    // Limpiar error cuando el usuario empieza a escribir
                    if (_telefonoError != null && value.length < 8) {
                      setState(() {
                        _telefonoError = null;
                      });
                    }
                  },
                ),
                if (_validatingTelefono)
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_telefonoError != null && !_validatingTelefono)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _telefonoError!,
                      style: GoogleFonts.itim(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          if (widget.esItca) ..._buildITCAFields(),
        ],
      ),
    );
  }

  // Método para construir los campos específicos de ITCA
  List<Widget> _buildITCAFields() {
    return [
      const SizedBox(height: 20),
      // Campo Carnet con su clave
      KeyedSubtree(
        key: widget.carnetKey,
        child: CustomTextField(
          controller: widget.carnetController,
          labelText: "Carnet de Estudiante",
          fillColor: Colors.white,
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          focusedColor: AppColors.primary,
          validator: (value) => widget.validateCarnet(value),
          hintText: "Ej: 123456",
          maxLength: 6,
        ),
      ),
      const SizedBox(height: 20),
      // Campo Sede con su clave
      KeyedSubtree(
        key: widget.sedeKey,
        child: WheelSelectorField(
          label: "Sede ITCA",
          items: ITCAOptions.sedes,
          selectedValue: widget.selectedSede,
          onSelected: widget.onSedeSelected,
          validator: (value) => widget.validateSede(value),
        ),
      ),
      const SizedBox(height: 20),
      // Campo Carrera con su clave
      KeyedSubtree(
        key: widget.carreraKey,
        child: WheelSelectorField(
          label: "Carrera",
          items: ITCAOptions.carreras,
          selectedValue: widget.selectedCarrera,
          onSelected: widget.onCarreraSelected,
          validator: (value) => widget.validateCarrera(value),
        ),
      ),
      const SizedBox(height: 20),
      // Campo Año con su clave
      KeyedSubtree(
        key: widget.anioKey,
        child: WheelSelectorField(
          label: "Año de ingreso",
          items: ITCAOptions.aniosIngreso,
          selectedValue: widget.selectedAnio,
          onSelected: widget.onAnioSelected,
          validator: (value) => widget.validateAnio(value),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF86A8E7).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF86A8E7).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue[700],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Estos datos nos ayudan a verificar tu identidad como estudiante ITCA',
                style: GoogleFonts.itim(
                  fontSize: 14,
                  color: Colors.blue[800],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // Método para validar el teléfono de forma asíncrona
  Future<void> _validateTelefonoAsync() async {
    final telefono = widget.telefonoController.text.trim();
    
    // Validar formato primero
    final formatError = widget.validateTelefono(telefono);
    if (formatError != null) {
      setState(() {
        _telefonoError = formatError;
        _validatingTelefono = false;
      });
      return;
    }

    // Solo validar existencia si tiene 8 dígitos
    if (telefono.length == 8 && widget.validateTelefonoExistente != null) {
      setState(() {
        _validatingTelefono = true;
        _telefonoError = null;
      });

      try {
        final error = await widget.validateTelefonoExistente!(telefono);
        setState(() {
          _telefonoError = error;
          _validatingTelefono = false;
        });
      } catch (e) {
        setState(() {
          _telefonoError = 'Error al verificar el teléfono';
          _validatingTelefono = false;
        });
      }
    }
  }

  // Método para ser llamado desde el formulario principal
  Future<bool> validateForm() async {
    // Validar teléfono de forma asíncrona antes de enviar
    await _validateTelefonoAsync();
    
    // Si hay error en el teléfono, no proceder
    if (_telefonoError != null) {
      return false;
    }
    
    // Validar el resto del formulario
    return widget.formKey.currentState?.validate() ?? false;
  }

  Widget _buildCorreoInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: widget.esItca ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.esItca ? Colors.orange[200]! : Colors.green[200]!,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.esItca ? Icons.school : Icons.person,
                color: widget.esItca ? Colors.orange : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.correo!,
                  style: GoogleFonts.itim(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.esItca ? 'Estudiante ITCA' : 'Usuario externo',
            style: GoogleFonts.itim(
              fontSize: 14,
              color: widget.esItca ? Colors.orange : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}