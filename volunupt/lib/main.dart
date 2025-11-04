import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'services/session_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1E3A8A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
              color: Color(0xFF1E3A8A),
              width: 2,
            ),
          ),
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
