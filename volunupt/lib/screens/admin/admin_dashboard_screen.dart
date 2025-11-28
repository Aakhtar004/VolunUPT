import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/event_service.dart';
import '../coordinator/manage_events_screen.dart';
import '../coordinator/validate_attendance_screen.dart';
import 'manage_users_screen.dart';
import 'reports_screen.dart';
import '../../utils/app_colors.dart';
import '../../utils/skeleton_loader.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel user;
  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loadingCounts = true;
  int _totalUsers = 0;
  int _students = 0;
  int _coordinators = 0;
  int _admins = 0;
  int _pendingValidations = 0;

  @override
  void initState() {
    super.initState();
    _loadOverviewCounts();
  }

  Future<void> _loadOverviewCounts() async {
    try {
      // Usuarios: contamos por rol
      final users = await UserService.getAllUsers();
      int students = 0, coords = 0, admins = 0;
      for (final u in users) {
        switch (u.role) {
          case UserRole.estudiante:
            students++;
            break;
          case UserRole.coordinador:
            coords++;
            break;
          case UserRole.administrador:
            admins++;
            break;
        }
      }

      // Asistencias pendientes de validación (global)
      final pendingQuery = await FirebaseFirestore.instance
          .collection('attendanceRecords')
          .where('status', isEqualTo: 'checkedIn')
          .get();

      setState(() {
        _totalUsers = users.length;
        _students = students;
        _coordinators = coords;
        _admins = admins;
        _pendingValidations = pendingQuery.docs.length;
        _loadingCounts = false;
      });
    } catch (e) {
      setState(() {
        _loadingCounts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Panel de Administración', style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
              Tab(icon: Icon(Icons.event), text: 'Eventos'),
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
              Tab(icon: Icon(Icons.admin_panel_settings), text: 'Roles'),
              Tab(icon: Icon(Icons.analytics), text: 'Reportes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildCoordinatorActionsTab(),
            _buildUsersTab(),
            _buildRolesTab(),
            _buildReportsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: () => _loadOverviewCounts(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resumen General',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _loadingCounts = true;
                    _loadOverviewCounts();
                  }),
                  icon: const Icon(Icons.refresh),
                  color: AppColors.primary,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _loadingCounts
                ? GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: const [
                      StatCardSkeleton(),
                      StatCardSkeleton(),
                      StatCardSkeleton(),
                      StatCardSkeleton(),
                      StatCardSkeleton(),
                      StatCardSkeleton(),
                    ],
                  )
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _statCard('Usuarios', _totalUsers.toString(), Icons.people, AppColors.primary),
                      _statCard('Estudiantes', _students.toString(), Icons.school, AppColors.success),
                      _statCard('Coordinadores', _coordinators.toString(), Icons.supervisor_account, AppColors.accent),
                      _statCard('Administradores', _admins.toString(), Image.asset('assets/images/logop.png'), const Color(0xFF6366F1)),
                      _statCard('Validaciones Pendientes', _pendingValidations.toString(), Icons.pending_actions, const Color(0xFFF59E0B)),
                    ],
                  ),
            const SizedBox(height: 24),
            const Text(
              'Eventos y Actividades',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.event, color: AppColors.primary, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<List<EventModel>>(
                            stream: EventService.getActiveEvents(),
                            builder: (context, snapshot) {
                              final count = snapshot.hasData ? snapshot.data!.length : 0;
                              return Text(
                                '$count',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                              );
                            },
                          ),
                          const Text(
                            'Programas publicados',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calendar_today, color: AppColors.success, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<SubEventModel>>(
                          stream: EventService.getAvailableSubEvents(),
                          builder: (context, snapshot) {
                            final count = snapshot.hasData ? snapshot.data!.length : 0;
                            return Text(
                              '$count',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.success),
                            );
                          },
                        ),
                        const Text(
                          'Actividades próximas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildCoordinatorActionsTab() {
    final options = [
      {
        'title': 'Gestionar Eventos',
        'subtitle': 'Crear y administrar programas',
        'icon': Icons.event_note,
        'color': AppColors.primary,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManageEventsScreen(user: widget.user),
            ),
          );
        },
      },
      {
        'title': 'Validar Asistencia',
        'subtitle': 'Confirmar participación',
        'icon': Icons.check_circle,
        'color': AppColors.accent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ValidateAttendanceScreen(user: widget.user),
            ),
          );
        },
      },
      {
        'title': 'Escanear QR',
        'subtitle': 'Registrar asistencia',
        'icon': Icons.qr_code_scanner,
        'color': AppColors.success,
        'onTap': () {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(const SnackBar(
            content: Text('Selecciona el evento desde Gestionar Eventos'),
            duration: Duration(seconds: 2),
          ));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManageEventsScreen(user: widget.user),
            ),
          );
        },
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones de Coordinador',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Herramientas para gestionar eventos y asistencias',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: options.map((option) {
              return _buildOptionCard(
                title: option['title'] as String,
                subtitle: option['subtitle'] as String,
                icon: option['icon'] as IconData,
                color: option['color'] as Color,
                onTap: option['onTap'] as VoidCallback,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión de Usuarios',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Administra cuentas y permisos de usuarios',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildOptionCard(
                title: 'Gestionar Usuarios',
                subtitle: 'Ver lista completa',
                icon: Icons.people,
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageUsersScreen(user: widget.user),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión de Roles',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Distribuición de roles en el sistema',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _loadingCounts
              ? GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: const [
                    StatCardSkeleton(),
                    StatCardSkeleton(),
                    StatCardSkeleton(),
                  ],
                )
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _statCard('Estudiantes', _students.toString(), Icons.school, AppColors.success),
                    _statCard('Coordinadores', _coordinators.toString(), Icons.supervisor_account, AppColors.accent),
                    _statCard('Administradores', _admins.toString(), Image.asset('assets/images/logop.png'), const Color(0xFF6366F1)),
                  ],
                ),
          const SizedBox(height: 24),
          const Text(
            'Acciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            title: 'Editar Roles',
            subtitle: 'Cambiar rol de usuarios',
            icon: Icons.swap_horiz,
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageUsersScreen(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportes y Análisis',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estadísticas detalladas del sistema',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildOptionCard(
                title: 'Ver Reportes',
                subtitle: 'Estadísticas completas',
                icon: Icons.analytics,
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportsScreen(user: widget.user),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, dynamic icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: icon is IconData 
                      ? Icon(icon, color: color, size: 20)
                      : SizedBox(width: 20, height: 20, child: icon),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
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
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
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
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
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
}

/// Ruta protegida para Admin: obtiene el usuario actual y verifica el rol
class AdminRouteGuard extends StatelessWidget {
  const AdminRouteGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: AuthService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: const Text('Error', style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text('No se pudo cargar la información del usuario.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          );
        }
        final user = snapshot.data!;
        if (user.role != UserRole.administrador) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: const Text('Acceso denegado', style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text('Esta sección es solo para administradores.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          );
        }
        return AdminDashboardScreen(user: user);
      },
    );
  }
}