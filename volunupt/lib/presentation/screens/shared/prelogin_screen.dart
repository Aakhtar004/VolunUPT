import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volunupt/application/blocs/auth_bloc.dart';

class PreLoginScreen extends StatefulWidget {
  const PreLoginScreen({super.key});

  @override
  State<PreLoginScreen> createState() => _PreLoginScreenState();
}

class _PreLoginScreenState extends State<PreLoginScreen> {
  @override
  void initState() {
    super.initState();
    // Verificar estado de autenticación al iniciar
    context.read<AuthBloc>().add(CheckAuthStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedInWithRole) {
          // Si el usuario ya está autenticado, navegar directamente al home
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is AuthUnauthenticated) {
          // Si no está autenticado, permanecer en la pantalla prelogin
          // No hacer nada, mostrar la UI de login
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFD3DBE7),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Center(
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
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
            );
          },
        ),
      ),
    );
  }
}
