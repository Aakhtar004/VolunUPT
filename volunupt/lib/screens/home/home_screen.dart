import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../events/events_screen.dart';
import '../qr/qr_screen.dart';
import '../history/history_screen.dart';
import '../certificates/certificates_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../student/my_registrations_screen.dart';
import '../student/hours_progress_screen.dart';
import '../coordinator/manage_events_screen.dart';
import '../coordinator/validate_attendance_screen.dart';
import '../admin/manage_users_screen.dart';
import '../admin/reports_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getCurrentUserData();

      if (userData != null) {
        setState(() {
          _user = userData;
          _isLoading = false;
        });
      } else {
        // Si no hay datos del usuario, redirigir al login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    // Confirmación antes de cerrar sesión
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Se cerrará tu sesión actual. Podrás volver a entrar cuando lo necesites.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AuthService.signOut();

      if (mounted) {
        // Navegación segura, limpiando el historial
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No pudimos cerrar sesión. Inténtalo otra vez.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _handleLogout,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
          ),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Error al cargar los datos del usuario')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'VolunUPT',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          // Icono de notificaciones
          StreamBuilder<int>(
            stream: NotificationService.getUnreadNotificationCount(_user!.uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(user: _user!),
                        ),
                      );
                    },
                    tooltip: 'Notificaciones',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Icono de perfil
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundImage: _user!.photoURL.isNotEmpty
                  ? NetworkImage(_user!.photoURL)
                  : null,
              backgroundColor: Colors.white,
              child: _user!.photoURL.isEmpty
                  ? const Icon(Icons.person, size: 16, color: Color(0xFF1E3A8A))
                  : null,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(user: _user!),
                ),
              );
            },
            tooltip: 'Perfil',
          ),
          // Menú de opciones
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(user: _user!),
                    ),
                  );
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: const Color(0xFF1E3A8A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRoleSpecificSection(),
              const SizedBox(height: 24),
              _buildMainFeaturesGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(user: _user!),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 35,
                  backgroundImage: _user!.photoURL.isNotEmpty
                      ? NetworkImage(_user!.photoURL)
                      : null,
                  backgroundColor: Colors.white,
                  child: _user!.photoURL.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 35,
                          color: Color(0xFF1E3A8A),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${_user!.displayName.split(' ').first}!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getRoleDisplayName(_user!.role),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _user!.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(user: _user!),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                tooltip: 'Editar perfil',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Horas Totales',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_user!.totalHours}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Estado',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Activo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final isStudent = _user!.role == UserRole.estudiante;
    final actions = <Map<String, dynamic>>[];

    if (isStudent) {
      actions.addAll([
        {
          'title': 'Mi QR',
          'icon': Icons.qr_code,
          'color': const Color(0xFF8B5CF6),
          'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRScreen(user: _user!),
                ),
              ),
        },
        {
          'title': 'Notificaciones',
          'icon': Icons.notifications,
          'color': const Color(0xFFF59E0B),
          'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsScreen(user: _user!),
                ),
              ),
        },
        {
          'title': 'Perfil',
          'icon': Icons.person,
          'color': const Color(0xFF10B981),
          'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(user: _user!),
                ),
              ),
        },
      ]);
    } else {
      // Coordinador/Administrador: solo acciones generales
      actions.addAll([
        {
          'title': 'Notificaciones',
          'icon': Icons.notifications,
          'color': const Color(0xFFF59E0B),
          'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsScreen(user: _user!),
                ),
              ),
        },
        {
          'title': 'Perfil',
          'icon': Icons.person,
          'color': const Color(0xFF10B981),
          'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(user: _user!),
                ),
              ),
        },
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              Expanded(
                child: _buildQuickActionCard(
                  title: actions[i]['title'] as String,
                  icon: actions[i]['icon'] as IconData,
                  color: actions[i]['color'] as Color,
                  onTap: actions[i]['onTap'] as VoidCallback,
                ),
              ),
              if (i < actions.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (badge != null && badge > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSpecificSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opciones de ${_getRoleDisplayName(_user!.role)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        _buildRoleSpecificOptions(),
      ],
    );
  }

  Widget _buildRoleSpecificOptions() {
    switch (_user!.role) {
      case UserRole.estudiante:
        return _buildStudentOptions();
      case UserRole.coordinador:
        return _buildCoordinatorOptions();
      case UserRole.administrador:
        return _buildAdminOptions();
    }
  }

  Widget _buildStudentOptions() {
    final options = [
      {
        'title': 'Mis Inscripciones',
        'subtitle': 'Ver eventos inscritos',
        'icon': Icons.event_available,
        'color': const Color(0xFF3B82F6),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyRegistrationsScreen(user: _user!),
            ),
          );
        },
      },
      {
        'title': 'Progreso de Horas',
        'subtitle': 'Ver mi progreso',
        'icon': Icons.trending_up,
        'color': const Color(0xFF10B981),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HoursProgressScreen(user: _user!),
            ),
          );
        },
      },
    ];

    return _buildOptionsRow(options);
  }

  Widget _buildCoordinatorOptions() {
    final options = [
      {
        'title': 'Gestionar Eventos',
        'subtitle': 'Crear y editar eventos',
        'icon': Icons.event_note,
        'color': const Color(0xFF8B5CF6),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManageEventsScreen(user: _user!),
            ),
          );
        },
      },
      {
        'title': 'Validar Asistencia',
        'subtitle': 'Confirmar participación',
        'icon': Icons.check_circle,
        'color': const Color(0xFFF59E0B),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ValidateAttendanceScreen(user: _user!),
            ),
          );
        },
      },
    ];

    return _buildOptionsRow(options);
  }

  Widget _buildAdminOptions() {
    final options = [
      {
        'title': 'Panel de Administración',
        'subtitle': 'Centro de control de Admin',
        'icon': Icons.dashboard,
        'color': const Color(0xFF1E3A8A),
        'onTap': () {
          Navigator.pushNamed(context, '/admin');
        },
      },
      {
        'title': 'Gestionar Usuarios',
        'subtitle': 'Administrar usuarios',
        'icon': Icons.people,
        'color': const Color(0xFFEF4444),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManageUsersScreen(user: _user!),
            ),
          );
        },
      },
      {
        'title': 'Reportes',
        'subtitle': 'Ver estadísticas',
        'icon': Icons.analytics,
        'color': const Color(0xFF6366F1),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportsScreen(user: _user!),
            ),
          );
        },
      },
    ];

    return _buildOptionsRow(options);
  }

  Widget _buildOptionsRow(List<Map<String, dynamic>> options) {
    return Row(
      children: options.map((option) {
        final index = options.indexOf(option);
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < options.length - 1 ? 12 : 0),
            child: _buildOptionCard(
              title: option['title'] as String,
              subtitle: option['subtitle'] as String,
              icon: option['icon'] as IconData,
              color: option['color'] as Color,
              onTap: option['onTap'] as VoidCallback,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainFeaturesGrid() {
    if (_user!.role != UserRole.estudiante) {
      // Para coordinador/administrador, ocultamos el grid de funciones principales del estudiante
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Funciones Principales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final features = [
              {
                'title': 'Eventos',
                'subtitle': 'Ver eventos disponibles',
                'icon': Icons.event,
                'color': const Color(0xFF10B981),
                'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventsScreen()),
                ),
              },
              {
                'title': 'Mi QR',
                'subtitle': 'Código QR personal',
                'icon': Icons.qr_code,
                'color': const Color(0xFF8B5CF6),
                'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRScreen(user: _user!),
                  ),
                ),
              },
              {
                'title': 'Historial',
                'subtitle': 'Ver mi historial',
                'icon': Icons.history,
                'color': const Color(0xFFF59E0B),
                'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(user: _user!),
                  ),
                ),
              },
              {
                'title': 'Certificados',
                'subtitle': 'Mis certificados',
                'icon': Icons.card_membership,
                'color': const Color(0xFFEF4444),
                'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CertificatesScreen(user: _user!),
                  ),
                ),
              },
            ];

            final feature = features[index];
            return _buildFeatureCard(
              title: feature['title'] as String,
              subtitle: feature['subtitle'] as String,
              icon: feature['icon'] as IconData,
              color: feature['color'] as Color,
              onTap: feature['onTap'] as VoidCallback,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.estudiante:
        return 'Estudiante';
      case UserRole.coordinador:
        return 'Coordinador';
      case UserRole.administrador:
        return 'Administrador';
    }
  }
}
