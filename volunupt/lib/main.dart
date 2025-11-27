import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'services/session_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const VolunUPTApp());
}

class VolunUPTApp extends StatefulWidget {
  const VolunUPTApp({super.key});

  @override
  State<VolunUPTApp> createState() => _VolunUPTAppState();
}

class _VolunUPTAppState extends State<VolunUPTApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Manejar ciclo de vida para control de sesión
    switch (state) {
      case AppLifecycleState.resumed:
        // Volver a monitorear la sesión
        SessionService.resume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // Pausar monitoreo. En Web no cerramos sesión para evitar interferir con flujos de autenticación (popup/redirect)
        SessionService.pause();
        if (!kIsWeb) {
          // Si se prefiere un "periodo de gracia", aquí podemos programar el logout en X segundos/minutos.
          SessionService.logout();
        }
        break;
      case AppLifecycleState.detached:
        // La app se está cerrando: asegurar que la sesión se termine
        if (!kIsWeb) {
          SessionService.logout();
        }
        break;
      case AppLifecycleState.hidden:
        // Estado adicional: en Web no cerrar sesión para no interferir con flujos de autenticación
        SessionService.pause();
        if (!kIsWeb) {
          SessionService.logout();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volun Upt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primary,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.primary,
          contentTextStyle: TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      // Registrar actividad del usuario en cualquier interacción táctil/ratón
      builder: (context, child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => SessionService.recordActivity(),
        onPointerMove: (_) => SessionService.recordActivity(),
        onPointerUp: (_) => SessionService.recordActivity(),
        child: child ?? const SizedBox.shrink(),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminRouteGuard(),
      },
      home: const SplashScreen(),
    );
  }
}
