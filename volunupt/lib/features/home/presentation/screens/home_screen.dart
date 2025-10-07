import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/floating_menu.dart';
import '../../../../core/widgets/page_transition.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../events/presentation/providers/events_providers.dart';
import '../providers/user_stats_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: authState.when(
        data: (user) {
          if (user == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/login');
            });
            return const SizedBox.shrink();
          }

          return userProfileAsync.when(
            data: (userProfile) => CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text('Volun UPT'),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Image(
                          image: AssetImage('lib/img/Logo.png'),
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WelcomeCard(user: userProfile),
                        const SizedBox(height: 24),
                        _QuickStats(),
                        const SizedBox(height: 24),
                        _QuickActions(userRole: userProfile?.role ?? 'estudiante'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text('Error cargando perfil: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error de autenticación: $error'),
        ),
      ),
      floatingActionButton: authState.when(
        data: (user) => user != null 
            ? userProfileAsync.when(
                data: (userProfile) => QuickActionsMenu(userRole: userProfile?.role ?? 'estudiante'),
                loading: () => null,
                error: (_, __) => null,
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

}

class _WelcomeCard extends StatelessWidget {
  final dynamic user;

  const _WelcomeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return SlideInAnimation(
      delay: Duration.zero,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              PulseAnimation(
                duration: const Duration(milliseconds: 3000),
                maxScale: 1.03,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${user.name}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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

class _QuickStats extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideInAnimation(
          delay: const Duration(milliseconds: 100),
          child: Text(
            'Tu Progreso',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        userStatsAsync.when(
          data: (stats) => StaggeredAnimation(
            delay: const Duration(milliseconds: 150),
            staggerDelay: const Duration(milliseconds: 100),
            direction: Axis.horizontal,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.event_available,
                      title: 'Eventos\nCompletados',
                      value: '${stats.completedEvents}',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.schedule,
                      title: 'Horas\nAcumuladas',
                      value: '${stats.totalHours}',
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.workspace_premium,
                      title: 'Certificados\nObtenidos',
                      value: '${stats.certificates}',
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No hay estadísticas disponibles',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Participa en eventos para ver tu progreso',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatefulWidget {
  final String userRole;

  const _QuickActions({required this.userRole});

  @override
  State<_QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<_QuickActions> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideInAnimation(
          delay: const Duration(milliseconds: 200),
          child: Text(
            'Acciones Rápidas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.userRole == 'estudiante') ..._buildStudentActions(context),
        if (widget.userRole == 'coordinador') ..._buildCoordinatorActions(context),
        if (widget.userRole == 'gestor_rsu') ..._buildAdminActions(context),
      ],
    );
  }

  List<Widget> _buildStudentActions(BuildContext context) {
    return [
      SlideInAnimation(
        delay: const Duration(milliseconds: 300),
        child: Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.event,
                title: 'Explorar Eventos',
                subtitle: 'Descubre nuevas oportunidades',
                onTap: () => context.go('/events'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.assignment,
                title: 'Mis Eventos',
                subtitle: 'Gestiona tus inscripciones',
                onTap: () => context.go('/my-events'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SlideInAnimation(
        delay: const Duration(milliseconds: 400),
        child: Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.workspace_premium,
                title: 'Certificados',
                subtitle: 'Ve tus logros',
                onTap: () => context.go('/certificates'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.qr_code,
                title: 'Mi Código QR',
                subtitle: 'Para asistencia',
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildCoordinatorActions(BuildContext context) {
    return [
      SlideInAnimation(
        delay: const Duration(milliseconds: 300),
        child: Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.qr_code_scanner,
                title: 'Escanear QR',
                subtitle: 'Registrar asistencia',
                onTap: () => _showEventSelectionDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.event,
                title: 'Ver Eventos',
                subtitle: 'Eventos disponibles',
                onTap: () => context.go('/events'),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildAdminActions(BuildContext context) {
    return [
      SlideInAnimation(
        delay: const Duration(milliseconds: 300),
        child: Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.dashboard,
                title: 'Dashboard',
                subtitle: 'Panel de control',
                onTap: () => context.go('/admin'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.people,
                title: 'Usuarios',
                subtitle: 'Gestionar usuarios',
                onTap: () => context.go('/admin/users'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SlideInAnimation(
        delay: const Duration(milliseconds: 400),
        child: Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.event,
                title: 'Eventos',
                subtitle: 'Crear y gestionar',
                onTap: () => context.go('/admin/events'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.analytics,
                title: 'Reportes',
                subtitle: 'Estadísticas',
                onTap: () => context.go('/admin/reports'),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  void _showEventSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final eventsAsync = ref.watch(eventsNotifierProvider);
          
          return AlertDialog(
            title: const Text('Seleccionar Evento'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: eventsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error al cargar eventos', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(error.toString(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay eventos disponibles'),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(event.title),
                        subtitle: Text(event.startDate.toString().split(' ')[0]),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/scanner/${event.id}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PulseAnimation(
                duration: const Duration(milliseconds: 2000),
                maxScale: 1.05,
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}