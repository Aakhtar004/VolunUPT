import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

class RoleBasedNavigation extends ConsumerWidget {
  final String currentPath;
  final Function(int) onTabTapped;

  const RoleBasedNavigation({
    super.key,
    required this.currentPath,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        
        final navigationItems = _getNavigationItemsForRole(user.role);
        final currentIndex = _getCurrentIndex(navigationItems);
        
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
              elevation: 0,
              onTap: (index) => _onTabTapped(context, index, navigationItems),
              items: navigationItems.map((item) => _buildNavItem(
                context: context,
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
                isSelected: currentIndex == navigationItems.indexOf(item),
              )).toList(),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<NavigationItem> _getNavigationItemsForRole(String role) {
    switch (role.toLowerCase()) {
      case 'estudiante':
        return [
          NavigationItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Inicio',
            route: '/home',
          ),
          NavigationItem(
            icon: Icons.event_outlined,
            activeIcon: Icons.event,
            label: 'Eventos',
            route: '/events',
          ),
          NavigationItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            label: 'Mis Eventos',
            route: '/my-events',
          ),
          NavigationItem(
            icon: Icons.workspace_premium_outlined,
            activeIcon: Icons.workspace_premium,
            label: 'Certificados',
            route: '/certificates',
          ),
          NavigationItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Perfil',
            route: '/profile',
          ),
        ];
      
      case 'coordinador':
      case 'gestor_rsu':
        return [
          NavigationItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            route: '/admin',
          ),
          NavigationItem(
            icon: Icons.event_outlined,
            activeIcon: Icons.event,
            label: 'Eventos',
            route: '/admin/events',
          ),
          NavigationItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Usuarios',
            route: '/admin/users',
          ),
          NavigationItem(
            icon: Icons.assessment_outlined,
            activeIcon: Icons.assessment,
            label: 'Reportes',
            route: '/admin/reports',
          ),
          NavigationItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Perfil',
            route: '/profile',
          ),
        ];
      
      case 'admin':
        return [
          NavigationItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            route: '/admin',
          ),
          NavigationItem(
            icon: Icons.event_outlined,
            activeIcon: Icons.event,
            label: 'Eventos',
            route: '/admin/events',
          ),
          NavigationItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Usuarios',
            route: '/admin/users',
          ),
          NavigationItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            label: 'Notificaciones',
            route: '/admin/notifications',
          ),
          NavigationItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Configuración',
            route: '/admin/settings',
          ),
        ];
      
      default:
        return [
          NavigationItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Inicio',
            route: '/home',
          ),
          NavigationItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Perfil',
            route: '/profile',
          ),
        ];
    }
  }

  int _getCurrentIndex(List<NavigationItem> items) {
    for (int i = 0; i < items.length; i++) {
      if (currentPath.startsWith(items[i].route)) {
        return i;
      }
    }
    return 0;
  }

  void _onTabTapped(BuildContext context, int index, List<NavigationItem> items) {
    if (index >= items.length) return;
    
    final currentIndex = _getCurrentIndex(items);
    if (index == currentIndex) return;
    
    HapticFeedback.lightImpact();
    context.go(items[index].route);
    onTabTapped(index);
  }

  BottomNavigationBarItem _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: isSelected ? 26 : 24,
        ),
      ),
      activeIcon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          activeIcon,
          size: 26,
        ),
      ),
      label: label,
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}