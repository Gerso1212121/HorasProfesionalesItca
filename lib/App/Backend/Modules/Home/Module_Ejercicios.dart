import 'package:ai_app_tests/Frontend/Screens/EJERCICIOS_REFACTOR.dart';
import 'package:flutter/material.dart';

import '../../../Data/DataBase/DatabaseHelper.dart';

class Ejercicios extends StatelessWidget {
  const Ejercicios({super.key});

  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper.instance;
    return FutureBuilder(
      future: dbHelper.syncEjercicios(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const EjerciciosScreen();
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
