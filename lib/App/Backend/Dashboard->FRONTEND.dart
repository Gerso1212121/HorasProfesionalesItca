import 'package:ai_app_tests/App/Backend/Modules/Home/Module_Diary.dart';
import 'package:ai_app_tests/App/Backend/Modules/Home/Module_Ejercicios.dart';
import 'package:ai_app_tests/App/Backend/Modules/Home/Module_Home.dart';
import 'package:ai_app_tests/App/Backend/Auth/Client/Auth_ProfileUser.dart';
import 'package:ai_app_tests/App/Backend/Modules/Module_ChatIA.dart';
import 'package:ai_app_tests/Frontend/Widgets/BOTTOM_BAR.dart';
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
    const ChatAi(),
    const Ejercicios(),
    const Diario(),
    const Perfil(),
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
