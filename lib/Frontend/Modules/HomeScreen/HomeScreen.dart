// HomeScreen/Screens/HomeScreen.dart
import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/ViewModels/HomeViewModel.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/MascotaFlotante.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Header/HomeHeaderSection.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Sections/Chats/HomeChatSuggestionsSection.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Sections/TOOLS/HomeToolsSection.dart';
import 'package:provider/provider.dart';
import 'package:horas2/Frontend/Modules/Diary/Screens/DiarioScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final viewModel = context.read<HomeViewModel>();
      // Recargar frase solo si la cache expiró (más de 1 hora)
      viewModel.loadMotivationalQuote(forceRefresh: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HomeHeaderSection(),
            const SizedBox(height: 30),
            _buildMainContent(context),
          ],
        ),
      ),
      floatingActionButton: MascotaFlotante(
        onTap: () => _navigateToDiary(context),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección de Psicología
        HomeToolsSection(),
        const SizedBox(height: 30),
        // Sección de Sugerencias de chat
        HomeChatSuggestionsSection(viewModel: viewModel),
        const SizedBox(height: 40),
      ],
    );
  }

  void _navigateToDiary(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DiarioScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }
}