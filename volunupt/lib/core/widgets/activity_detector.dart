import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';

class ActivityDetector extends ConsumerWidget {
  final Widget child;

  const ActivityDetector({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _updateActivity(ref),
      onPanDown: (_) => _updateActivity(ref),
      onScaleStart: (_) => _updateActivity(ref),
      behavior: HitTestBehavior.translucent,
      child: Listener(
        onPointerDown: (_) => _updateActivity(ref),
        onPointerMove: (_) => _updateActivity(ref),
        onPointerUp: (_) => _updateActivity(ref),
        child: child,
      ),
    );
  }

  void _updateActivity(WidgetRef ref) {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    authNotifier.updateActivity();
  }
}