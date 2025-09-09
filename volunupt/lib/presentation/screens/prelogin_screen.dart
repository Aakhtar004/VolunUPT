import 'package:flutter/material.dart';

class PreLoginScreen extends StatelessWidget {
  const PreLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3DBE7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono central
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: const Icon(
                  Icons.layers,
                  size: 48,
                  color: Color(0xFF253A6B),
                ),
              ),
              const SizedBox(height: 32),
              // Título
              const Text(
                'Sistema de Voluntariado UPT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF253A6B),
                ),
              ),
              const SizedBox(height: 16),
              // Descripción
              const Text(
                'Conecta, colabora y contribuye. Tu oportunidad para generar un impacto positivo en la comunidad universitaria y más allá.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF253A6B)),
              ),
              const SizedBox(height: 40),
              // Botón continuar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Términos y condiciones
              GestureDetector(
                onTap: () {
                  // Aquí puedes navegar a una pantalla de términos si la tienes
                },
                child: const Text(
                  'Términos y Condiciones y Política de Privacidad',
                  style: TextStyle(
                    color: Color(0xFF253A6B),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
