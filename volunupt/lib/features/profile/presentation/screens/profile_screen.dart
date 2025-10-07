import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuario no autenticado'));
          }

          return userProfile.when(
            data: (profile) => SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: 24),
                  _ProfileOptions(
                    profile: profile,
                    onBiometricToggle: (enabled) {
                      ref
                          .read(profileNotifierProvider.notifier)
                          .updateBiometricSettings(user.id, enabled);
                    },
                    onNotificationToggle: (enabled) {
                      ref
                          .read(profileNotifierProvider.notifier)
                          .updateNotificationSettings(user.id, enabled);
                    },
                    onSignOut: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(userProfileStreamProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error de autenticación: $error')),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: profile?.photoUrl != null
                  ? NetworkImage(profile!.photoUrl!)
                  : null,
              child: profile?.photoUrl == null
                  ? Icon(
                      Icons.person,
                      size: 50,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              profile?.name ?? 'Usuario',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              profile?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (profile?.studentCode != null) ...[
              const SizedBox(height: 4),
              Text(
                'Código: ${profile!.studentCode}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getRoleDisplayName(profile?.role ?? 'estudiante'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'coordinador':
        return 'Coordinador';
      case 'estudiante':
        return 'Estudiante';
      case 'admin':
        return 'Administrador';
      default:
        return 'Usuario';
    }
  }
}

class _ProfileOptions extends StatelessWidget {
  final dynamic profile;
  final Function(bool) onBiometricToggle;
  final Function(bool) onNotificationToggle;
  final VoidCallback onSignOut;

  const _ProfileOptions({
    required this.profile,
    required this.onBiometricToggle,
    required this.onNotificationToggle,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileOptionTile(
          icon: Icons.person_outline,
          title: 'Información Personal',
          subtitle: 'Editar perfil y datos personales',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
          },
        ),
        _ProfileSwitchTile(
          icon: Icons.security,
          title: 'Autenticación Biométrica',
          subtitle: 'Usar huella dactilar para acceder',
          value: profile?.biometricEnabled ?? false,
          onChanged: onBiometricToggle,
        ),
        _ProfileSwitchTile(
          icon: Icons.notifications_outlined,
          title: 'Notificaciones',
          subtitle: 'Recibir alertas y recordatorios',
          value: profile?.notificationsEnabled ?? true,
          onChanged: onNotificationToggle,
        ),
        if (profile?.career != null) ...[
          _ProfileInfoTile(
            icon: Icons.school,
            title: 'Carrera',
            subtitle: profile!.career!,
          ),
        ],
        if (profile?.semester != null) ...[
          _ProfileInfoTile(
            icon: Icons.grade,
            title: 'Semestre',
            subtitle: 'Semestre ${profile!.semester}',
          ),
        ],
        _ProfileOptionTile(
          icon: Icons.help_outline,
          title: 'Ayuda y Soporte',
          subtitle: 'Preguntas frecuentes y contacto',
          onTap: () {
            _showHelpDialog(context);
          },
        ),
        _ProfileOptionTile(
          icon: Icons.info_outline,
          title: 'Acerca de',
          subtitle: 'Versión de la aplicación e información',
          onTap: () {
            _showAboutDialog(context);
          },
        ),
        _ProfileOptionTile(
          icon: Icons.logout,
          title: 'Cerrar Sesión',
          subtitle: 'Salir de la aplicación',
          isDestructive: true,
          onTap: () {
            _showSignOutDialog(context);
          },
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSignOut();
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda y Soporte'),
        content: const Text(
          'Para obtener ayuda, contacta al administrador del sistema o envía un correo a soporte@upt.pe',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acerca de VolunUPT'),
        content: const Text(
          'VolunUPT v1.0.0\n\nAplicación para la gestión de eventos de voluntariado de la Universidad Privada de Tacna.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _ProfileSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
