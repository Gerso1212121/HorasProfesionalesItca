import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Modules/Profile/ViewModels/AnimationStateVM.dart';
import 'package:horas2/Frontend/Modules/Profile/ViewModels/ProfileCache.dart';
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
  late Map<String, dynamic>? _cachedData;

  @override
  void initState() {
    super.initState();
    
    // Intentar obtener datos cacheados
    _cachedData = ProfileCache.getCachedUserData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final animationState =
          Provider.of<AnimationStateVM>(context, listen: false);
      animationState.setProfileScreenAnimated(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileVM()),
      ],
      child: Consumer<ProfileVM>(
        builder: (context, vm, child) {
          // Mostrar skeleton si está cargando Y no hay datos cacheados
          if (vm.isLoading && !ProfileCache.hasCachedData()) {
            return const ProfileSkeleton();
          }

          // Si hay datos cacheados, mostrar UI con esos datos mientras carga
          if (_cachedData != null) {
            return _buildProfileUI(context, vm, _cachedData!);
          }

          if (vm.usuario == null) {
            return const Scaffold(
              body: Center(child: Text('No se pudo cargar el perfil')),
            );
          }

          // Guardar datos en caché una vez cargados
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (vm.usuario != null && !vm.isLoading) {
              ProfileCache.cacheUserData(vm.usuario!);
            }
          });

          return _buildProfileUI(context, vm, vm.usuario!);
        },
      ),
    );
  }

  Widget _buildProfileUI(
      BuildContext context, ProfileVM vm, Map<String, dynamic> userData) {
    final nombre = userData['nombre'] ?? 'Usuario';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header animado
          ProfileAnimatedHeader(
            nombre: nombre,
            inicial: inicial,
          ),

          // Contenido principal
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  children: [
                    // Tarjeta de información principal
                    SequentialFadeIn(
                      delay: 600,
                      animationId: 'profile_info_card23',
                      child: ProfileInfoCard(usuario: userData),
                    ),

                    const SizedBox(height: 24),

                    // Botones de acción
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