import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../home/home_screen.dart';
import '../../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _floatingAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userModel = await AuthService.signInWithGoogle();

      if (userModel != null && mounted) {
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

        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(_getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email-domain':
          return 'Solo se permiten cuentas institucionales: @virtual.upt.pe.\nPor favor, usa tu correo institucional.';
        case 'network-request-failed':
          return 'Error de conexión. Verifica tu conexión a internet.';
        case 'popup-closed-by-user':
          return 'Inicio de sesión cancelado.';
        default:
          return 'No pudimos iniciar sesión. Por favor, inténtalo de nuevo.';
      }
    }

    final msg = error.toString().toLowerCase();
    if (msg.contains('solo se permiten cuentas institucionales') ||
        msg.contains('solo se permiten cuentas')) {
      return 'Solo se permiten cuentas institucionales: @virtual.upt.pe.\nPor favor, usa tu correo institucional.';
    }
    if (msg.contains('network')) {
      return 'Error de conexión. Verifica tu conexión a internet.';
    }
    if (msg.contains('popup_closed_by_user') || msg.contains('cancelled')) {
      return 'Inicio de sesión cancelado.';
    }
    return 'No pudimos iniciar sesión. Por favor, inténtalo de nuevo.';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error de autenticación'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showInactivityWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sesión por expirar'),
        content: const Text(
          'Tu sesión expirará pronto por inactividad. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SessionService.logout();
            },
            child: const Text('Cerrar sesión'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              SessionService.extendSession();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.85),
              const Color(0xFF1e40af),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.2,
              right: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo con animación flotante
                          AnimatedBuilder(
                            animation: _floatingAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _floatingAnimation.value),
                                child: child,
                              );
                            },
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.volunteer_activism,
                                size: 56,
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Título
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withValues(alpha: 0.9),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'VolunUPT',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Sistema de Voluntariado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 70),

                          // Card de login
                          Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                  spreadRadius: -10,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '¡Bienvenido!',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  'Inicia sesión con tu cuenta institucional',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    height: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Botón de Google
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isLoading
                                        ? null
                                        : _signInWithGoogle,
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (_isLoading) ...[
                                            SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.primary),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Text(
                                              'Iniciando sesión...',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ] else ...[
                                            SvgPicture.asset(
                                              'assets/images/google_logo.svg',
                                              width: 22,
                                              height: 22,
                                            ),
                                            const SizedBox(width: 14),
                                            Text(
                                              'Continuar con Google',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Info adicional
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Solo cuentas @virtual.upt.pe',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Footer
                          Text(
                            'Universidad Privada de Tacna',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
