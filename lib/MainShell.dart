import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Modules/Diary/Screens/DiarioScreen.dart';
import 'package:horas2/Frontend/Modules/Excercises/ExcersicesScreen.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/HomeScreen.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ChatBotScreen.dart';
import 'package:horas2/Frontend/Modules/Profile/Screens/ProfileScreen.dart';
import 'package:horas2/Frontend/widgets/NavigatorBottom.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    DiarioScreen(),
    const ChatBotScreen(),
    const ExcersicesScreen(),
    const ProfileScreen(),
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
