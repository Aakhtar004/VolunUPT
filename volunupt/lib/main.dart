import 'package:flutter/material.dart';

// Paquete para manejar estados con el patrón BLoC
import 'package:flutter_bloc/flutter_bloc.dart';
// Importación del bloque de autenticación (gestiona login, registro, etc.)
import 'package:volunupt/application/blocs/auth_bloc.dart';

// Casos de uso de dominio: lógica de negocio para login y registro
import 'package:volunupt/domain/usecases/login_usecase.dart';
import 'package:volunupt/domain/usecases/register_usecase.dart';

// Implementación del repositorio de autenticación (conecta casos de uso con la capa de datos)
import 'package:volunupt/infraestructure/repositories/auth_repository_impl.dart';

// Fuente de datos concreta para autenticación (API, Firebase, etc.)
import 'package:volunupt/infraestructure/datasources/auth_datasource.dart';

// Interfaces gráficas: pantallas de la aplicación
import 'package:volunupt/presentation/screens/prelogin_screen.dart'; // Pantalla de preinicio de sesión
import 'package:volunupt/presentation/screens/login_screen.dart'; // Pantalla de inicio de sesión
import 'package:volunupt/presentation/screens/register_screen.dart'; // Pantalla de registro de usuarios
import 'package:volunupt/presentation/screens/home_screen.dart'; // Pantalla principal tras iniciar sesión

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyección de dependencias
    final authRepository = AuthRepositoryImpl(AuthDatasource());
    final loginUseCase = LoginUseCase(authRepository: authRepository);
    final registerUseCase = RegisterUseCase(authRepository: authRepository); //

    return BlocProvider(
      create: (context) =>
          AuthBloc(loginUseCase, registerUseCase), // Agregamos registerUseCase
      child: MaterialApp(
        title: 'VolunUPT',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const PreLoginScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(), // Nueva ruta
          '/home': (context) => const HomeScreen(), // Agregar esta línea
        },
      ),
    );
  }
}
