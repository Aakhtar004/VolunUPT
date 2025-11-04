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
        appBar: AppBar(
          title: const Text('Panel de Administración'),
          bottom: const TabBar(
            isScrollable: true,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen General',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _loadingCounts
              ? const Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statCard('Usuarios', _totalUsers.toString(), Icons.people, const Color(0xFF1E3A8A)),
                    _statCard('Estudiantes', _students.toString(), Icons.school, const Color(0xFF10B981)),
                    _statCard('Coordinadores', _coordinators.toString(), Icons.group, const Color(0xFFF59E0B)),
                    _statCard('Administradores', _admins.toString(), Icons.admin_panel_settings, const Color(0xFFEF4444)),
                    _statCard('Validaciones Pendientes', _pendingValidations.toString(), Icons.pending_actions, const Color(0xFF6366F1)),
                  ],
                ),
          const SizedBox(height: 20),
          const Text(
            'Eventos activos y próximos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Eventos activos', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        StreamBuilder<List<EventModel>>(
                          stream: EventService.getActiveEvents(),
                          builder: (context, snapshot) {
                            final count = snapshot.hasData ? snapshot.data!.length : 0;
                            return Text(
                              '$count',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Actividades próximas', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        StreamBuilder<List<SubEventModel>>(
                          stream: EventService.getAvailableSubEvents(),
                          builder: (context, snapshot) {
                            final count = snapshot.hasData ? snapshot.data!.length : 0;
                            return Text(
                              '$count',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            );
                          },
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
    );
  }

  Widget _buildCoordinatorActionsTab() {
    final options = [
      {
        'title': 'Gestionar Eventos',
        'subtitle': 'Crear y administrar programas',
        'icon': Icons.event_note,
        'color': const Color(0xFF8B5CF6),
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
        'color': const Color(0xFFF59E0B),
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
        'subtitle': 'Registrar asistencia de estudiantes',
        'icon': Icons.qr_code_scanner,
        'color': const Color(0xFF10B981),
        'onTap': () {
          // Para escanear QR se requiere seleccionar un evento y actividad específica
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(const SnackBar(
            content: Text('Selecciona primero el evento y la actividad a escanear.'),
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildOptionsRow(options),
    );
  }

  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Usuarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildOptionCard(
            title: 'Gestionar Usuarios',
            subtitle: 'Ver, editar y eliminar usuarios',
            icon: Icons.people,
            color: const Color(0xFFEF4444),
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

  Widget _buildRolesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Roles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard('Estudiantes', _students.toString(), Icons.school, const Color(0xFF10B981)),
              _statCard('Coordinadores', _coordinators.toString(), Icons.group, const Color(0xFFF59E0B)),
              _statCard('Administradores', _admins.toString(), Icons.admin_panel_settings, const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 20),
          _buildOptionCard(
            title: 'Editar Roles',
            subtitle: 'Cambiar rol de usuarios',
            icon: Icons.edit,
            color: const Color(0xFF6366F1),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reportes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildOptionCard(
            title: 'Abrir Reportes',
            subtitle: 'Ver estadísticas y exportar',
            icon: Icons.analytics,
            color: const Color(0xFF6366F1),
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
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
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
}

/// Ruta protegida para Admin: obtiene el usuario actual y verifica el rol
class AdminRouteGuard extends StatelessWidget {
  const AdminRouteGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: AuthService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data!;
        if (user.role != UserRole.administrador) {
          return Scaffold(
            appBar: AppBar(title: const Text('Acceso denegado')),
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