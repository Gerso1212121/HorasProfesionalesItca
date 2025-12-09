import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Modules/Auth/ViewModels/AuthUserDataVM.dart';
import 'package:horas2/Frontend/Modules/Auth/widgets/UserData/UserDataHeader.dart';
import 'package:horas2/Frontend/Modules/Auth/widgets/forms/UserDataForm.dart';
import 'package:horas2/Frontend/widgets/Buttons/Buttons.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class UserDataScreen extends StatefulWidget {
  const UserDataScreen({Key? key}) : super(key: key);

  @override
  State<UserDataScreen> createState() => _UserDataScreenState();
}

class _UserDataScreenState extends State<UserDataScreen> {
  late UserDataVM _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController(); // Controlador para el scroll
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _carnetController = TextEditingController();

  // Claves para identificar cada campo del formulario
  final _nombreKey = GlobalKey();
  final _telefonoKey = GlobalKey();
  final _carnetKey = GlobalKey();
  final _sedeKey = GlobalKey();
  final _carreraKey = GlobalKey();
  final _anioKey = GlobalKey();

  String? _selectedSede;
  String? _selectedCarrera;
  String? _selectedAnio;
  bool _initialized = false;
  bool _validatingPhone = false;
  bool _validatingCarnet = false;
  String? _phoneValidationError;
  String? _carnetValidationError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _viewModel = Provider.of<UserDataVM>(context, listen: false);
      _initialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeData();
        }
      });
    }
  }

  Future<void> _initializeData() async {
    try {
      await _viewModel.verificarCorreoItca();
      _viewModel.addListener(_onViewModelChanged);

      if (_viewModel.user != null) {
        await _viewModel.loadUserData(_viewModel.user!.uid);
      }
    } catch (e) {
      print('Error inicializando datos: $e');
    }
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Listener para el scroll controller
  void _scrollListener() {
    // Puedes agregar lógica adicional aquí si es necesario
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _carnetController.dispose();
    _scrollController.dispose(); // No olvidar desechar el controller
    if (_initialized) {
      _viewModel.removeListener(_onViewModelChanged);
    }
    super.dispose();
  }

  Future<void> _validatePhoneNumber() async {
    if (_validatingPhone) return;
    
    final telefono = _telefonoController.text.trim();
    
    final formatError = _viewModel.validateTelefono(telefono);
    if (formatError != null) {
      setState(() {
        _phoneValidationError = formatError;
        _validatingPhone = false;
      });
      return;
    }

    if (telefono.length == 8) {
      setState(() {
        _validatingPhone = true;
        _phoneValidationError = null;
      });

      try {
        final error = await _viewModel.validarTelefonoExistente(telefono);
        setState(() {
          _phoneValidationError = error;
          _validatingPhone = false;
        });
      } catch (e) {
        setState(() {
          _phoneValidationError = 'Error al verificar el teléfono';
          _validatingPhone = false;
        });
      }
    } else {
      setState(() {
        _phoneValidationError = null;
      });
    }
  }

  Future<void> _validateCarnetNumber() async {
    if (!_viewModel.esItca) return;
    if (_validatingCarnet) return;
    
    final carnet = _carnetController.text.trim();
    
    final formatError = _viewModel.validateCarnet(carnet, _viewModel.esItca);
    if (formatError != null) {
      setState(() {
        _carnetValidationError = formatError;
        _validatingCarnet = false;
      });
      return;
    }

    if (carnet.length == 6) {
      setState(() {
        _validatingCarnet = true;
        _carnetValidationError = null;
      });

      try {
        final error = await _viewModel.validarCarnetExistente(carnet);
        setState(() {
          _carnetValidationError = error;
          _validatingCarnet = false;
        });
      } catch (e) {
        setState(() {
          _carnetValidationError = 'Error al verificar el carnet';
          _validatingCarnet = false;
        });
      }
    } else {
      setState(() {
        _carnetValidationError = null;
      });
    }
  }

  String? _validateTelefonoWithExistence(String? value) {
    final formatError = _viewModel.validateTelefono(value);
    if (formatError != null) {
      return formatError;
    }
    
    if (_phoneValidationError != null) {
      return _phoneValidationError;
    }
    
    return null;
  }

  String? _validateCarnetWithExistence(String? value) {
    if (!_viewModel.esItca) return null;
    
    final formatError = _viewModel.validateCarnet(value, _viewModel.esItca);
    if (formatError != null) {
      return formatError;
    }
    
    if (_carnetValidationError != null) {
      return _carnetValidationError;
    }
    
    return null;
  }

  // Método para desplazarse al primer campo con error
  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lista de claves en el orden de aparición en el formulario
      final keysInOrder = [
        if (_viewModel.esItca && _carnetKey.currentContext != null) _carnetKey,
        if (_nombreKey.currentContext != null) _nombreKey,
        if (_telefonoKey.currentContext != null) _telefonoKey,
        if (_viewModel.esItca && _sedeKey.currentContext != null) _sedeKey,
        if (_viewModel.esItca && _carreraKey.currentContext != null) _carreraKey,
        if (_viewModel.esItca && _anioKey.currentContext != null) _anioKey,
      ];

      for (final key in keysInOrder) {
        final context = key.currentContext;
        if (context != null) {
          // Encuentra el RenderBox del widget
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            // Calcula la posición relativa al scrollable
            final offset = renderBox.localToGlobal(
              Offset.zero,
              ancestor: _scrollController.position.context.notificationContext?.findRenderObject(),
            );

            // Si el widget está por debajo del área visible, desplázate hacia él
            final scrollableHeight = _scrollController.position.viewportDimension;
            if (offset.dy > scrollableHeight - 50 || offset.dy < 0) {
              _scrollController.animateTo(
                _scrollController.offset + offset.dy - 100,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
            break; // Solo desplázate al primer error encontrado
          }
        }
      }
    });
  }

  Future<void> _submitForm() async {
    // Primero validar el teléfono existente
    if (_telefonoController.text.trim().length == 8) {
      await _validatePhoneNumber();
      
      if (_phoneValidationError != null) {
        _formKey.currentState?.validate();
        _scrollToFirstError(); // Desplazar al error
        return;
      }
    }

    // Si es ITCA, validar el carnet existente
    if (_viewModel.esItca && _carnetController.text.trim().length == 6) {
      await _validateCarnetNumber();
      
      if (_carnetValidationError != null) {
        _formKey.currentState?.validate();
        _scrollToFirstError(); // Desplazar al error
        return;
      }
    }

    // Validar el resto del formulario
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError(); // Desplazar al primer error
      return;
    }

    final success = await _viewModel.guardarDatos(
      nombre: _nombreController.text.trim(),
      telefono: _telefonoController.text.trim(),
      carnet: _viewModel.esItca ? _carnetController.text.trim() : null,
      sede: _selectedSede,
      carrera: _selectedCarrera,
      anioIngreso: _selectedAnio,
    );

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al guardar datos. Intenta nuevamente.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Método mejorado para mostrar errores y desplazar
  void _showErrorAndScroll(String errorMessage) {
    // Mostrar snackbar con el error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );

    // Desplazar al primer campo con error
    _scrollToFirstError();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (_initialized && _viewModel.correo != null)
              UserDataHeader(
                esItca: _viewModel.esItca,
                correo: _viewModel.correo,
                onBackPressed: () => context.go('/login'),
              ),

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // Conectar el controller
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    // Sección del cerebrito y título
                    Column(
                      children: [
                        Center(
                          child: _buildCerebritoImage(),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _initialized &&
                                            _viewModel.hasExistingData ||
                                        _viewModel.esItca == true
                                    ? 'Completemos tu información '
                                    : 'Completa tu información',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                              ),
                              if (_initialized &&
                                  (_viewModel.hasExistingData ||
                                      _viewModel.esItca == true))
                                TextSpan(
                                  text: 'ESTUDIANTE ITCA',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _viewModel.esItca
                                            ? AppColors.primaryLight
                                            : Colors.green[700],
                                      ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: Text(
                            _viewModel.esItca
                                ? 'Por favor completa la siguiente información para continuar como estudiante ITCA'
                                : 'Por favor completa la siguiente información para continuar',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Formulario - PASAR LAS CLAVES AL WIDGET DEL FORMULARIO
                    if (_initialized)
                      UserDataFormWidget(
                        esItca: _viewModel.esItca,
                        correo: _viewModel.correo,
                        formKey: _formKey,
                        nombreController: _nombreController,
                        telefonoController: _telefonoController,
                        carnetController: _carnetController,
                        selectedSede: _selectedSede,
                        selectedCarrera: _selectedCarrera,
                        selectedAnio: _selectedAnio,
                        // Pasar las claves para cada campo
                        nombreKey: _nombreKey,
                        telefonoKey: _telefonoKey,
                        carnetKey: _carnetKey,
                        sedeKey: _sedeKey,
                        carreraKey: _carreraKey,
                        anioKey: _anioKey,
                        onSedeSelected: (value) =>
                            setState(() => _selectedSede = value),
                        onCarreraSelected: (value) =>
                            setState(() => _selectedCarrera = value),
                        onAnioSelected: (value) =>
                            setState(() => _selectedAnio = value),
                        validateNombre: (value) =>
                            _viewModel.validateNombre(value),
                        validateTelefono: _validateTelefonoWithExistence,
                        validateCarnet: _validateCarnetWithExistence,
                        validateSede: (value) => _viewModel.esItca &&
                                (value == null || value.isEmpty)
                            ? 'Selecciona una sede'
                            : null,
                        validateCarrera: (value) => _viewModel.esItca &&
                                (value == null || value.isEmpty)
                            ? 'Selecciona una carrera'
                            : null,
                        validateAnio: (value) => _viewModel.esItca &&
                                (value == null || value.isEmpty)
                            ? 'Selecciona un año de ingreso'
                            : null,
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(),
                      ),

                    const SizedBox(height: AppSpacing.xl),

                    // Botón de continuar
                    if (_initialized)
                      PrimaryButton(
                        text: _viewModel.hasExistingData
                            ? 'Actualizar'
                            : 'Continuar',
                        onPressed: _submitForm,
                        backgroundColor: AppColors.primary,
                        icon: Icons.arrow_forward,
                        isLoading: _viewModel.isLoading || 
                                 _validatingPhone || 
                                 _validatingCarnet,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCerebritoImage() {
    final String imageAsset = _viewModel.esItca
        ? 'assets/images/brainitca.png'
        : 'assets/images/brainreadingbook.png';

    return Image.asset(
      imageAsset,
      width: 150,
      height: 150,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          _viewModel.esItca ? Icons.school_rounded : Icons.person_rounded,
          size: 60,
          color: _viewModel.esItca ? Colors.blue[700] : Colors.green[700],
        );
      },
    );
  }
}