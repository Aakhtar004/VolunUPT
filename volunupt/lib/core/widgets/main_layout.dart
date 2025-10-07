import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void didUpdateWidget(MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: widget.child,
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentIndex = _getCurrentIndex();
    
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
          onTap: (index) => _onTabTapped(context, index),
          items: [
            _buildNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Inicio',
              isSelected: currentIndex == 0,
            ),
            _buildNavItem(
              icon: Icons.event_outlined,
              activeIcon: Icons.event,
              label: 'Eventos',
              isSelected: currentIndex == 1,
            ),
            _buildNavItem(
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment,
              label: 'Mis Eventos',
              isSelected: currentIndex == 2,
            ),
            _buildNavItem(
              icon: Icons.workspace_premium_outlined,
              activeIcon: Icons.workspace_premium,
              label: 'Certificados',
              isSelected: currentIndex == 3,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Perfil',
              isSelected: currentIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
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

  int _getCurrentIndex() {
    if (widget.currentPath.startsWith('/home')) return 0;
    if (widget.currentPath.startsWith('/events')) return 1;
    if (widget.currentPath.startsWith('/my-events')) return 2;
    if (widget.currentPath.startsWith('/certificates')) return 3;
    if (widget.currentPath.startsWith('/profile')) return 4;
    if (widget.currentPath.startsWith('/admin')) return 0;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    if (index == _getCurrentIndex()) return;
    
    HapticFeedback.lightImpact();
    
    _previousIndex = _getCurrentIndex();
    
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/events');
        break;
      case 2:
        context.go('/my-events');
        break;
      case 3:
        context.go('/certificates');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}