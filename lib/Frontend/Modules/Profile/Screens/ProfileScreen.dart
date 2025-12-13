import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Modules/Profile/ViewModels/AnimationStateVM.dart';
import 'package:horas2/Frontend/Modules/Profile/widgets/ProfileSkeleton.dart';
import 'package:provider/provider.dart';
import 'package:horas2/Frontend/Modules/Profile/Animated/ProfileAnimatedHeader.dart';
import 'package:horas2/Frontend/Modules/Profile/Animated/SequentialFadeIn.dart';
import 'package:horas2/Frontend/Modules/Profile/ViewModels/ProfileVM.dart';
import 'package:horas2/Frontend/Modules/Profile/widgets/ProfileInfoCard.dart';
import 'package:horas2/Frontend/Modules/Profile/widgets/ActionButtonsSection.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _lastUserId;
  Map<String, dynamic>? _lastUserData;

  @override
  void initState() {
    super.initState();
    print('📱 ProfileScreen.initState()');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final animationState = context.read<AnimationStateVM>();
        animationState.setProfileScreenAnimated(true);
        print('✅ Animación configurada');
      } catch (e) {
        print('⚠️ Error configurando animación: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ ProfileScreen.build()');
    
    return Consumer<ProfileVM>(
      builder: (context, vm, child) {
        final currentUserId = vm.auth.currentUser?.uid;
        
        print('👀 ProfileScreen - Estado actual:');
        print('   - currentUserId: $currentUserId');
        print('   - lastUserId: $_lastUserId');
        print('   - vm.isLoading: ${vm.isLoading}');
        print('   - vm.usuario: ${vm.usuario != null ? "PRESENTE" : "NULO"}');
        print('   - vm.hasError: ${vm.hasError}');
        
        // Detectar cambio de usuario
        final bool userChanged = currentUserId != null && 
                                _lastUserId != null && 
                                currentUserId != _lastUserId;
        
        if (userChanged) {
          print('🔄 ¡CAMBIO DE USUARIO DETECTADO!');
          print('   - De: $_lastUserId');
          print('   - A: $currentUserId');
          
          // Limpiar datos del usuario anterior
          _lastUserData = null;
          _lastUserId = currentUserId;
          
          // Forzar recarga para el nuevo usuario
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !vm.isLoading) {
              print('🔄 Cargando datos para nuevo usuario...');
              vm.cargarUsuario();
            }
          });
          
          return const ProfileSkeleton();
        }
        
        // Guardar el userId actual
        if (currentUserId != null && _lastUserId == null) {
          _lastUserId = currentUserId;
        }
        
        // 1. Si está cargando Y no tenemos datos previos, mostrar skeleton
        if (vm.isLoading && _lastUserData == null) {
          print('⏳ Mostrando skeleton (carga inicial)');
          return const ProfileSkeleton();
        }
        
        // 2. Si hay error Y no tenemos datos previos, mostrar skeleton
        if (vm.hasError && _lastUserData == null) {
          print('❌ Error sin datos previos - Mostrando skeleton');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !vm.isLoading) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  print('🔄 Reintentando carga por error...');
                  vm.cargarUsuario();
                }
              });
            }
          });
          return const ProfileSkeleton();
        }
        
        // 3. Si no hay usuario (nulo) Y no tenemos datos previos, mostrar skeleton
        if (vm.usuario == null && _lastUserData == null) {
          print('⚠️ Usuario nulo sin datos previos - Mostrando skeleton');
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !vm.isLoading) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  print('🔄 Intentando cargar usuario...');
                  vm.cargarUsuario();
                }
              });
            }
          });
          
          return const ProfileSkeleton();
        }
        
        // 4. Determinar qué datos usar: últimos datos válidos o datos actuales
        Map<String, dynamic>? dataToUse;
        
        if (vm.usuario != null && !vm.hasError && !vm.isLoading) {
          // Usar datos actuales si son válidos
          dataToUse = vm.usuario;
          
          // Verificar que los datos correspondan al usuario actual
          final uidEnDatos = vm.usuario!['uid']?.toString() ?? 
                            vm.usuario!['uid_firebase']?.toString();
          
          if (uidEnDatos != currentUserId) {
            print('⚠️ Desfase de UID en datos actuales');
            print('   - UID en datos: $uidEnDatos');
            print('   - UID actual: $currentUserId');
            
            // No usar estos datos, usar los últimos válidos o skeleton
            if (_lastUserData != null) {
              print('📋 Usando últimos datos válidos');
              dataToUse = _lastUserData;
            } else {
              print('🔄 Forzando recarga...');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                vm.cargarUsuario();
              });
              return const ProfileSkeleton();
            }
          } else {
            // Datos válidos, guardarlos como últimos válidos
            _lastUserData = Map<String, dynamic>.from(vm.usuario!);
            dataToUse = vm.usuario;
            print('✅ Datos actuales válidos y guardados');
          }
        } else if (_lastUserData != null) {
          // Usar últimos datos válidos mientras se carga/corrige
          print('📋 Usando últimos datos válidos (mientras se actualiza)');
          dataToUse = _lastUserData;
          
          // Intentar corregir en segundo plano si hay problema
          if (vm.hasError || vm.usuario == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !vm.isLoading) {
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    print('🔄 Reintentando carga en segundo plano...');
                    vm.cargarUsuario();
                  }
                });
              }
            });
          }
        } else {
          // No hay datos válidos, mostrar skeleton
          print('❌ No hay datos válidos disponibles');
          return const ProfileSkeleton();
        }
        
        // Si llegamos aquí, tenemos datos válidos para mostrar
        print('🎨 Construyendo UI con datos verificados');
        return _buildProfileUI(context, vm, dataToUse!);
      },
    );
  }

  Widget _buildProfileUI(
    BuildContext context, 
    ProfileVM vm, 
    Map<String, dynamic> userData,
  ) {
    final rawNombre = userData['nombre'];
    final rawApellido = userData['apellido'];
    
    final nombre = (rawNombre?.toString() ?? '').trim();
    final apellido = (rawApellido?.toString() ?? '').trim();
    
    final nombreCompleto = nombre.isNotEmpty && apellido.isNotEmpty 
        ? '$nombre $apellido'
        : nombre.isNotEmpty 
            ? nombre 
            : 'Usuario';
    
    final inicial = nombre.isNotEmpty 
        ? nombre[0].toUpperCase() 
        : 'U';

    print('👤 Mostrando información:');
    print('   - Nombre: $nombreCompleto');
    print('   - Correo: ${userData['correo']}');
    print('   - Carrera: ${userData['carrera']}');
    print('   - UID: ${userData['uid'] ?? userData['uid_firebase']}');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          ProfileAnimatedHeader(
            nombre: nombreCompleto,
            inicial: inicial,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  children: [
                    SequentialFadeIn(
                      delay: 600,
                      animationId: 'profile_info_card23',
                      child: ProfileInfoCard(usuario: userData),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          SequentialFadeIn(
                            delay: 700,
                            animationId: 'action_buttons',
                            child: ActionButtonsSection(
                              vm: vm,
                              esEstudianteItca: vm.esEstudianteItca,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}