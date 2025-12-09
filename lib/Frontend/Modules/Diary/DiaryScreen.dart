import 'package:flutter/material.dart';

// --- Colores Personalizados (Para replicar la paleta de la imagen) ---
const Color kPrimaryColor = Color.fromARGB(255, 214, 0, 196); // Púrpura/Violeta intenso para el botón
const Color kTextFieldFillColor = Color(0xFFF0F0F0); // Gris muy claro para el fondo de los campos
const Color kAccentTextColor = Color(0xFF1976D2); // Azul estándar para el enlace



class Auth extends StatelessWidget {
  const Auth({super.key});

  // Estilo base para los TextFields
  InputDecoration _inputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: kTextFieldFillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      // Elimina el borde visualmente, pero mantiene la forma
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none, // Clave para el look plano
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.0), // Borde suave al enfocar
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definimos el padding general para la pantalla
    const double horizontalPadding = 24.0;
    const double verticalSpacing = 16.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- 1. Logo/Branding ---
              const Text(
                'brand.ai',
                style: TextStyle(
                  fontSize: 34.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 50.0), // Espacio entre logo y título

              // --- 2. Títulos ---
              const Text(
                'Create an account',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Let\'s get started by filling out the form below.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30.0),

              // --- 3. Campos de Entrada (TextFormFields) ---
              // Email
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email'),
              ),
              const SizedBox(height: verticalSpacing),

              // Password
              TextFormField(
                obscureText: true,
                decoration: _inputDecoration(
                  'Password',
                  suffixIcon: const Icon(Icons.visibility_off, color: Colors.grey),
                ),
              ),
              const SizedBox(height: verticalSpacing),

              // Confirm Password
              TextFormField(
                obscureText: true,
                decoration: _inputDecoration(
                  'Confirm Password',
                  suffixIcon: const Icon(Icons.visibility_off, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30.0),

              // --- 4. Botón Principal ---
              SizedBox(
                width: double.infinity, // Para que ocupe todo el ancho
                height: 55.0, // Altura estándar para botones grandes
                child: ElevatedButton(
                  onPressed: () {
                    // Acción al crear la cuenta
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor, // Color de fondo púrpura
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 4.0, // Ligera sombra para el efecto elevado
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // --- 5. Enlace de Inicio de Sesión ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 15.0, color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Acción para ir a la pantalla de Sign In
                    },
                    child: const Text(
                      'Sign In here',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: kAccentTextColor, // Color azul para el enlace
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}