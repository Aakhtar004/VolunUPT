import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
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
import '../coordinator/manage_events_screen.dart' show ManageEventsScreen;
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Se cerrará tu sesión actual. Podrás volver a entrar cuando lo necesites.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final ctx = context;

    // Mostrar diálogo de cargando
    showDialog(
      // ignore: use_build_context_synchronously
      context: ctx,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cerrando sesión...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      await AuthService.signOut();
      SessionService.dispose();

      if (mounted) {
        // Cerrar el diálogo de cargando
        Navigator.of(context).pop();
        
        // Navegar a login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        // Cerrar el diálogo de cargando
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No pudimos cerrar sesión. Inténtalo otra vez.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Error al cargar los datos del usuario',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'VolunUPT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          // Notificaciones
          StreamBuilder<int>(
            stream: NotificationService.getUnreadNotificationCount(_user!.uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NotificationsScreen(user: _user!),
                          ),
                        );
                      },
                      tooltip: 'Notificaciones',
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
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
                ),
              );
            },
          ),
          // Perfil
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: CircleAvatar(
                radius: 18,
                backgroundImage: _user!.photoURL.isNotEmpty
                    ? NetworkImage(_user!.photoURL)
                    : null,
                backgroundColor: Colors.white,
                child: _user!.photoURL.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 18,
                        color: AppColors.primary,
                      )
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
          ),
          // Menú
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                    Icon(
                      Icons.person_outline,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: 12),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppColors.error),
                    SizedBox(width: 12),
                    Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoCard(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildRoleSpecificSection(),
              if (_user!.role == UserRole.estudiante) ...[
                const SizedBox(height: 20),
                _buildMainFeaturesGrid(),
              ],
              const SizedBox(height: 20),
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
          colors: [AppColors.primary, Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: _user!.photoURL.isNotEmpty
                        ? NetworkImage(_user!.photoURL)
                        : null,
                    backgroundColor: Colors.white,
                    child: _user!.photoURL.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 32,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
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
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRoleDisplayName(_user!.role),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _user!.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Horas Totales',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_user!.totalHours}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Estado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Activo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
        // {
        //   'title': 'Actividades',
        //   'icon': Icons.event_rounded,
        //   'color': AppColors.primary,
        //   'onTap': () => Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (context) => const EventsScreen()),
        //   ),
        // },
        {
          'title': 'Certificados',
          'icon': Icons.workspace_premium_rounded,
          'color': AppColors.primary,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CertificatesScreen(user: _user!),
            ),
          ),
        },
        {
          'title': 'Mi QR',
          'icon': Icons.qr_code_2_rounded,
          'color': AppColors.primary,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QRScreen(user: _user!)),
          ),
        },
        {
          'title': 'Perfil',
          'icon': Icons.person_rounded,
          'color': AppColors.primary,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(user: _user!),
            ),
          ),
        },
      ]);
    } else {
      actions.addAll([
        {
          'title': 'Perfil',
          'icon': Icons.person_rounded,
          'color': AppColors.primary,
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
          'Accesos rápidos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < actions.length - 1 ? 10 : 0,
                ),
                child: _buildQuickActionCard(
                  title: action['title'] as String,
                  icon: action['icon'] as IconData,
                  color: action['color'] as Color,
                  onTap: action['onTap'] as VoidCallback,
                ),
              ),
            );
          }).toList(),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  if (badge != null && badge > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
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
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          'Tu espacio de ${_getRoleDisplayName(_user!.role)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
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
        'icon': Icons.event_available_rounded,
        'color': AppColors.primary,
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
        'icon': Icons.trending_up_rounded,
        'color': AppColors.primary,
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
        'icon': Icons.event_note_rounded,
        'color': AppColors.primary,
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
        'icon': Icons.check_circle_rounded,
        'color': AppColors.primary,
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
        'title': 'Panel Admin',
        'subtitle': 'Centro de control',
        'icon': Icons.dashboard_rounded,
        'color': AppColors.primary,
        'onTap': () {
          Navigator.pushNamed(context, '/admin');
        },
      },
      {
        'title': 'Gestionar Usuarios',
        'subtitle': 'Administrar usuarios',
        'icon': Icons.people_rounded,
        'color': AppColors.primary,
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
        'icon': Icons.analytics_rounded,
        'color': AppColors.primary,
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
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < options.length - 1 ? 10 : 0,
            ),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
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
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainFeaturesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explora',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final features = [
              {
                'title': 'Eventos',
                'subtitle': 'Ver eventos disponibles',
                'icon': Icons.event_rounded,
                'color': AppColors.primary,
                'onTap': () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventsScreen()),
                ),
              },
              {
                'title': 'Mi QR',
                'subtitle': 'Código QR personal',
                'icon': Icons.qr_code_2_rounded,
                'color': AppColors.primary,
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
                'icon': Icons.history_rounded,
                'color': AppColors.primary,
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
                'icon': Icons.card_membership_rounded,
                'color': AppColors.primary,
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.08),
                color.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
