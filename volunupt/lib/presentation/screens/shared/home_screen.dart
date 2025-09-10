import 'package:flutter/material.dart';
import 'package:volunupt/infraestructure/repositories/auth_repository_impl_local.dart';
import 'package:volunupt/infraestructure/datasources/auth_datasource_local.dart';
import 'package:volunupt/presentation/screens/estudiante/student_home_screen.dart';
import 'package:volunupt/presentation/screens/coordinador/engineer_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final authRepository = AuthRepositoryImplLocal(AuthDatasourceLocal());
    final role = await authRepository.getUserRole();
    setState(() {
      userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Redirigir según el role del usuario
    if (userRole == 'Estudiante') {
      return const StudentHomeScreen();
    } else if (userRole == 'Coordinador') {
      return const EngineerHomeScreen();
    }

    // Fallback en caso de role desconocido
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Role de usuario no reconocido')),
    );
  }
}
