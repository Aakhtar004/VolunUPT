import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volunupt/application/blocs/auth_bloc.dart';
import 'package:volunupt/infraestructure/repositories/auth_repository_impl_local.dart';
import 'package:volunupt/infraestructure/datasources/auth_datasource_local.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String? userFullName;
  String? userEmail;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authRepository = AuthRepositoryImplLocal(AuthDatasourceLocal());
    final fullName = await authRepository.getUserFullName();
    final email = await authRepository.storage.read(key: 'user_email');
    final role = await authRepository.getUserRole();

    setState(() {
      userFullName = fullName ?? 'Usuario';
      userEmail = email ?? '';
      userRole = role ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3DBE7),
      body: Column(
        children: [
          // Header del perfil
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF253A6B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 60, color: Color(0xFF253A6B)),
                ),
                SizedBox(height: 16),
                Text(
                  userFullName ?? 'Cargando...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  userRole ?? 'Cargando...',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Opciones del perfil
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileOption(
                  icon: Icons.person,
                  title: 'Información Personal',
                  subtitle: 'Editar datos personales',
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.school,
                  title: 'Información Académica',
                  subtitle: 'Escuela, ciclo académico',
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.notifications,
                  title: 'Notificaciones',
                  subtitle: 'Configurar alertas',
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.security,
                  title: 'Privacidad y Seguridad',
                  subtitle: 'Cambiar contraseña',
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.help,
                  title: 'Ayuda y Soporte',
                  subtitle: 'FAQ, contacto',
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.info,
                  title: 'Acerca de',
                  subtitle: 'Versión de la app',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                // Botón de cerrar sesión
                Container(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      BlocProvider.of<AuthBloc>(context).add(LogoutEvent());
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF253A6B), size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF253A6B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
