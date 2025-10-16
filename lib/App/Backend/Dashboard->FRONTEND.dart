import 'package:ai_app_tests/App/Backend/Modules/Module_Diary.dart';
import 'package:ai_app_tests/App/Backend/Modules/Module_Ejercicios.dart';
import 'package:ai_app_tests/App/Backend/Modules/Module_Home.dart';
import 'package:ai_app_tests/App/Backend/Auth/Client/Auth_ProfileUser.dart';
import 'package:ai_app_tests/Frontend/Widgets/custom_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'Modules/Debug/DebugScreen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Diario(),
    const Ejercicios(),
    const Perfil(),
    const DebugScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
