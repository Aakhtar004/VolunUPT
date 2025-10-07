import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/data/services/session_manager_service.dart';
import 'session_dialog.dart';

class SessionListener extends ConsumerStatefulWidget {
  final Widget child;

  const SessionListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<SessionListener> createState() => _SessionListenerState();
}

class _SessionListenerState extends ConsumerState<SessionListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSessionListener();
    });
  }

  void _setupSessionListener() {
    final sessionManager = ref.read(sessionManagerProvider);
    
    sessionManager.sessionEvents.listen((event) {
      if (!mounted) return;
      
      switch (event) {
        case SessionEvent.sessionStarted:
          break;
        case SessionEvent.inactivityWarning:
          SessionDialog.showInactivityWarning(context, ref);
          break;
        case SessionEvent.sessionExpired:
          ref.read(authNotifierProvider.notifier).signOut();
          context.go('/login');
          break;
        case SessionEvent.sessionEnded:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}