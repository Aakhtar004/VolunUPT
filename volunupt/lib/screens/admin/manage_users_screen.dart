import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/app_colors.dart';
import '../../utils/skeleton_loader.dart';

class ManageUsersScreen extends StatefulWidget {
  final UserModel user;

  const ManageUsersScreen({
    super.key,
    required this.user,
  });

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _selectedRole = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Gestionar Usuarios',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _showCreateUserDialog(),
            icon: const Icon(Icons.person_add),
            tooltip: 'Crear Usuario',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildStatsCards(),
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
            hintText: 'Buscar por nombre o email...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
            ),
          ),
          const SizedBox(height: 16),
          // Filtros por rol
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleFilter('all', 'Todos', Icons.people),
                const SizedBox(width: 8),
                _buildRoleFilter('estudiante', 'Estudiantes', Icons.school),
                const SizedBox(width: 8),
                _buildRoleFilter('coordinador', 'Coordinadores', Icons.supervisor_account),
                const SizedBox(width: 8),
                _buildRoleFilter('administrador', 'Administradores', Icons.admin_panel_settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilter(String value, String label, IconData icon) {
    final isSelected = _selectedRole == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedRole = value),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildStatsCards() {
    return FutureBuilder<Map<String, int>>(
      future: _getUserStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Expanded(child: StatCardSkeleton()),
                SizedBox(width: 8),
                Expanded(child: StatCardSkeleton()),
                SizedBox(width: 8),
                Expanded(child: StatCardSkeleton()),
                SizedBox(width: 8),
                Expanded(child: StatCardSkeleton()),
              ],
            ),
          );
        }

        final stats = snapshot.data ?? {
          'total': 0,
          'students': 0,
          'coordinators': 0,
          'admins': 0,
        };

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats['total']!,
                  Icons.people,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Estudiantes',
                  stats['students']!,
                  Icons.school,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Coordinadores',
                  stats['coordinators']!,
                  Icons.supervisor_account,
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Admins',
                  stats['admins']!,
                  Icons.admin_panel_settings,
                  AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return FutureBuilder<List<UserModel>>(
      future: UserService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: ListItemSkeleton(),
          );
        }

        if (snapshot.hasError) {
          // Tratar errores como estado vacío (p.ej., falta de datos/tablas)
          return _buildEmptyState();
        }

        final allUsers = snapshot.data ?? [];
        final filteredUsers = _filterUsers(allUsers);

        if (filteredUsers.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              return _buildUserCard(filteredUsers[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showUserDetails(user),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
                    backgroundImage: user.photoURL.isNotEmpty 
                        ? NetworkImage(user.photoURL) 
                        : null,
                    child: user.photoURL.isEmpty
                        ? Text(
                            user.displayName.isNotEmpty 
                                ? user.displayName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: _getRoleColor(user.role),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (user.role == UserRole.estudiante)
                          Text(
                            '${user.totalHours.toStringAsFixed(1)} horas acumuladas',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleUserAction(value, user),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'change_role',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, size: 18),
                            SizedBox(width: 8),
                            Text('Cambiar Rol'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildRoleChip(user.role),
                  const SizedBox(width: 8),
                  if (user.role == UserRole.estudiante && user.totalHours > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            '${user.totalHours.toStringAsFixed(1)}h',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text(
                    'ID: ${user.uid.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[400],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(UserRole role) {
    final color = _getRoleColor(role);
    final text = _getRoleText(role);
    final icon = _getRoleIcon(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Eliminado: chip de estado, no hay campo isActive en UserModel actual

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron usuarios',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }


  List<UserModel> _filterUsers(List<UserModel> users) {
    var filtered = users;

    // Filtrar por rol
    if (_selectedRole != 'all') {
      filtered = filtered.where((user) => user.role.name == _selectedRole).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        return user.displayName.toLowerCase().contains(query) ||
               user.email.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.estudiante:
        return AppColors.success;
      case UserRole.coordinador:
        return AppColors.accent;
      case UserRole.administrador:
        return AppColors.primary;
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.estudiante:
        return 'Estudiante';
      case UserRole.coordinador:
        return 'Coordinador';
      case UserRole.administrador:
        return 'Administrador';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.estudiante:
        return Icons.school;
      case UserRole.coordinador:
        return Icons.supervisor_account;
      case UserRole.administrador:
        return Icons.admin_panel_settings;
    }
  }

  Future<Map<String, int>> _getUserStats() async {
    try {
      final users = await UserService.getAllUsers();
      return {
        'total': users.length,
        'students': users.where((u) => u.role == UserRole.estudiante).length,
        'coordinators': users.where((u) => u.role == UserRole.coordinador).length,
        'admins': users.where((u) => u.role == UserRole.administrador).length,
      };
    } catch (e) {
      return {
        'total': 0,
        'students': 0,
        'coordinators': 0,
        'admins': 0,
      };
    }
  }

  void _showCreateUserDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de creación de usuarios próximamente'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Detalles de: ${user.displayName}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleUserAction(String action, UserModel user) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Editar usuario próximamente')),
        );
        break;
      case 'change_role':
        _showChangeRoleDialog(user);
        break;
      case 'delete':
        _showDeleteUserDialog(user);
        break;
    }
  }

  void _showChangeRoleDialog(UserModel user) {
    UserRole selectedRole = user.role;
    // Capturar el ScaffoldMessenger del screen principal antes de abrir el diálogo
    final rootMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cambiar Rol'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: ${user.displayName}'),
              Text('Rol actual: ${_getRoleText(user.role)}'),
              const SizedBox(height: 16),
              const Text('Nuevo rol:'),
              RadioListTile<UserRole>(
                title: const Text('Estudiante'),
                value: UserRole.estudiante,
                groupValue: selectedRole,
                onChanged: (value) => setDialogState(() => selectedRole = value!),
              ),
              RadioListTile<UserRole>(
                title: const Text('Coordinador'),
                value: UserRole.coordinador,
                groupValue: selectedRole,
                onChanged: (value) => setDialogState(() => selectedRole = value!),
              ),
              RadioListTile<UserRole>(
                title: const Text('Administrador'),
                value: UserRole.administrador,
                groupValue: selectedRole,
                onChanged: (value) => setDialogState(() => selectedRole = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedRole != user.role
                  ? () async {
                      // Capturar messenger del scaffold principal ANTES de operaciones asíncronas
                      // Usar el messenger capturado del contexto principal
                      final messenger = rootMessenger;
                      // Cerrar el diálogo
                      Navigator.of(context).pop();
                      try {
                        await UserService.updateUserRole(user.uid, selectedRole);
                        // Forzar refresco de la lista en el screen principal
                        if (mounted) {
                          setState(() {});
                        }
                        messenger.showSnackBar(
                          SnackBar(content: Text('Rol actualizado a ${selectedRole.name}')),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('No se pudo cambiar el rol del usuario')),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  // Eliminado: diálogo de activar/desactivar usuario (no hay campo isActive en UserModel actual)

  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a "${user.displayName}"? Esta acción no se puede deshacer.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Eliminar usuario próximamente')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Eliminado: _formatDate (no utilizado en esta pantalla)
}