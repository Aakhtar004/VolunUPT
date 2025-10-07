import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class FloatingMenu extends StatefulWidget {
  final List<FloatingMenuItem> items;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const FloatingMenu({
    super.key,
    required this.items,
    this.backgroundColor,
    this.iconColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  State<FloatingMenu> createState() => _FloatingMenuState();
}

class _FloatingMenuState extends State<FloatingMenu>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
    });

    if (_isOpen) {
      _controller.forward();
      _rotationController.forward();
    } else {
      _controller.reverse();
      _rotationController.reverse();
    }
  }

  void _onItemTap(FloatingMenuItem item) {
    HapticFeedback.selectionClick();
    _toggle();
    item.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_isOpen)
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black26,
            ),
          ),
        
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              
              return AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  final delay = index * 0.1;
                  final animationValue = (_scaleAnimation.value - delay).clamp(0.0, 1.0);
                  
                  return Transform.scale(
                    scale: animationValue,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.label != null)
                            Container(
                              margin: const EdgeInsets.only(right: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                item.label!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          
                          FloatingActionButton(
                            mini: true,
                            heroTag: 'floating_menu_$index',
                            backgroundColor: item.backgroundColor ?? theme.colorScheme.primary,
                            foregroundColor: item.iconColor ?? theme.colorScheme.onPrimary,
                            onPressed: () => _onItemTap(item),
                            child: Icon(item.icon),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList().reversed,
            
            FloatingActionButton(
              heroTag: 'floating_menu_main',
              backgroundColor: widget.backgroundColor ?? theme.colorScheme.primary,
              foregroundColor: widget.iconColor ?? theme.colorScheme.onPrimary,
              elevation: widget.elevation ?? 6,
              onPressed: _toggle,
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: Icon(_isOpen ? Icons.close : Icons.add),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FloatingMenuItem {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const FloatingMenuItem({
    required this.icon,
    required this.onTap,
    this.label,
    this.backgroundColor,
    this.iconColor,
  });
}

class QuickActionsMenu extends StatelessWidget {
  final String userRole;

  const QuickActionsMenu({
    super.key,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    List<FloatingMenuItem> items = [
      FloatingMenuItem(
        icon: Icons.event_available,
        label: 'Mis Eventos',
        onTap: () => context.go('/my-events'),
        backgroundColor: Colors.green,
      ),
    ];

    if (userRole == 'gestor_rsu') {
      items.addAll([
        FloatingMenuItem(
          icon: Icons.dashboard,
          label: 'Panel Admin',
          onTap: () => context.go('/admin'),
          backgroundColor: Colors.orange,
        ),
        FloatingMenuItem(
          icon: Icons.people,
          label: 'Usuarios',
          onTap: () => context.go('/admin/users'),
          backgroundColor: Colors.purple,
        ),
      ]);
    }

    return FloatingMenu(items: items);
  }
}

class AnimatedFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool isExtended;
  final String? label;

  const AnimatedFAB({
    super.key,
    this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.isExtended = false,
    this.label,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: widget.isExtended && widget.label != null
                  ? FloatingActionButton.extended(
                      onPressed: widget.onPressed,
                      tooltip: widget.tooltip,
                      backgroundColor: widget.backgroundColor,
                      foregroundColor: widget.foregroundColor,
                      elevation: widget.elevation,
                      icon: widget.child,
                      label: Text(widget.label!),
                    )
                  : FloatingActionButton(
                      onPressed: widget.onPressed,
                      tooltip: widget.tooltip,
                      backgroundColor: widget.backgroundColor,
                      foregroundColor: widget.foregroundColor,
                      elevation: widget.elevation,
                      child: widget.child,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class SpeedDial extends StatefulWidget {
  final List<SpeedDialChild> children;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final String? heroTag;
  final double? elevation;
  final bool visible;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  const SpeedDial({
    super.key,
    required this.children,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.heroTag,
    this.elevation,
    this.visible = true,
    this.onOpen,
    this.onClose,
  });

  @override
  State<SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<SpeedDial>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _controller.reverse();
      widget.onClose?.call();
    } else {
      _controller.forward();
      widget.onOpen?.call();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_isOpen)
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
        
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...widget.children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final animationValue = Curves.elasticOut.transform(
                    (_controller.value - (index * 0.1)).clamp(0.0, 1.0),
                  );
                  
                  return Transform.scale(
                    scale: animationValue,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: child,
                    ),
                  );
                },
              );
            }).toList().reversed,
            
            FloatingActionButton(
              heroTag: widget.heroTag,
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
              tooltip: widget.tooltip,
              elevation: widget.elevation,
              onPressed: _toggle,
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: widget.child,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SpeedDialChild extends StatelessWidget {
  final Widget child;
  final String? label;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SpeedDialChild({
    super.key,
    required this.child,
    this.label,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        FloatingActionButton(
          mini: true,
          backgroundColor: backgroundColor ?? theme.colorScheme.secondary,
          foregroundColor: foregroundColor ?? theme.colorScheme.onSecondary,
          onPressed: onTap,
          child: child,
        ),
      ],
    );
  }
}