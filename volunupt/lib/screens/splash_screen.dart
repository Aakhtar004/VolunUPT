import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthenticationStatus();
  }

  void _initializeAnimations() {
    // Controlador para el logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controlador para el texto
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animación de escala para el logo
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Animación de opacidad para el texto
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Animación de deslizamiento para el texto
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Iniciar animaciones
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      // Esperar un mínimo de tiempo para mostrar la animación
      await Future.delayed(const Duration(milliseconds: 2500));

      if (!mounted) return;

      // Verificar si hay un usuario autenticado
      if (AuthService.isAuthenticated) {
        // Verificar que la sesión sea válida
        final isSessionValid = await AuthService.isSessionValid();
        
        if (isSessionValid) {
          // Obtener datos del usuario
          final userData = await AuthService.getCurrentUserData();
          
          if (userData != null) {
            // Inicializar servicio de sesiones
            _initializeSessionService();
            
            // Navegar a la pantalla principal
            _navigateToHome();
            return;
          }
        }
      }

      // Si no hay sesión válida, ir a login
      _navigateToLogin();
    } catch (e) {
      debugPrint('Error en _checkAuthenticationStatus: $e');
      // En caso de error, ir a login
      _navigateToLogin();
    }
  }

  void _initializeSessionService() {
    SessionService.initialize(
      onSessionExpired: () {
        if (mounted) {
          _navigateToLogin();
        }
      },
      onInactivityWarning: () {
        if (mounted) {
          _showInactivityWarning();
        }
      },
    );
  }

  void _showInactivityWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sesión por expirar'),
        content: const Text(
          'Tu sesión expirará pronto por inactividad. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SessionService.logout();
              _navigateToLogin();
            },
            child: const Text('Cerrar sesión'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              SessionService.extendSession();
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A), // Azul UPT
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.volunteer_activism,
                        size: 60,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Texto animado
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _textAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'VolunUPT',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sistema de Voluntariado UPT',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Indicador de carga
              FadeTransition(
                opacity: _textAnimation,
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}