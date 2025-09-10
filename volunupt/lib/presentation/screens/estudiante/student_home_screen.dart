import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volunupt/application/blocs/auth_bloc.dart';
import 'package:volunupt/presentation/widgets/bottom_nav_bar.dart';
import 'package:volunupt/presentation/screens/estudiante/catalog_screen.dart';
import 'package:volunupt/presentation/screens/estudiante/inscripciones_screen.dart';
import 'package:volunupt/presentation/screens/estudiante/certificados_screen.dart';
import 'package:volunupt/presentation/screens/shared/perfil_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CatalogScreen(),
    const InscripcionesScreen(),
    const CertificadosScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3DBE7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mi Asistencia'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF253A6B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Acción de retroceso
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              BlocProvider.of<AuthBloc>(context).add(LogoutEvent());
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
