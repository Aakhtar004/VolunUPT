import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volunupt/application/blocs/auth_bloc.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFD3DBE7), // Fondo gris azulado
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Título principal
                const Text(
                  'UPT-Tacna',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF253A6B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Card principal
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Título secundario
                      const Text(
                        'Voluntariado UPT',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF253A6B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Descripción
                      const Text(
                        'Ingresa con tu correo y contraseña',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF253A6B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Campo de correo
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          hintText: 'Correo institucional',
                          filled: true,
                          fillColor: Color(0xFFE7ECF3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: Color(0xFF253A6B),
                          ),
                          hintStyle: TextStyle(
                            color: Color(0xFFB0B7C3),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      // Campo de contraseña
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          hintText: 'Contraseña',
                          filled: true,
                          fillColor: Color(0xFFE7ECF3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Color(0xFF253A6B),
                          ),
                          hintStyle: TextStyle(
                            color: Color(0xFFB0B7C3),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 18),
                      // Botón de iniciar sesión
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: BlocConsumer<AuthBloc, AuthState>(
                          listener: (context, state) {
                            if (state is AuthAuthenticated) {
                              Navigator.pushReplacementNamed(context, '/home');
                            } else if (state is AuthError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(state.message),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      BlocProvider.of<AuthBloc>(context).add(
                                        LoginEvent(
                                          email: emailController.text.trim(),
                                          password: passwordController.text,
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: state is AuthLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Botón de crear cuenta
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            'Crear Cuenta',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Ayuda
                      GestureDetector(
                        onTap: () {
                          // Acción para ayuda
                        },
                        child: const Text(
                          '¿Necesitas ayuda?',
                          style: TextStyle(
                            color: Color(0xFF253A6B),
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Barra de navegación inferior
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.grid_view, color: Color(0xFF253A6B)),
                          Text(
                            'Catálogo',
                            style: TextStyle(
                              color: Color(0xFF253A6B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.assignment, color: Color(0xFF253A6B)),
                          Text(
                            'Inscripciones',
                            style: TextStyle(
                              color: Color(0xFF253A6B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.verified, color: Color(0xFF253A6B)),
                          Text(
                            'Certificados',
                            style: TextStyle(
                              color: Color(0xFF253A6B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person, color: Color(0xFF253A6B)),
                          Text(
                            'Perfil',
                            style: TextStyle(
                              color: Color(0xFF253A6B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
