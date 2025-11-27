import 'package:flutter/material.dart';

/// Widget de skeleton loader para evitar parpadeos al cargar datos
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[300]!.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

/// Card skeleton para listas de eventos
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: SkeletonLoader(width: double.infinity, height: 20),
                ),
                const SizedBox(width: 12),
                SkeletonLoader(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonLoader(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            const SkeletonLoader(width: 200, height: 14),
            const SizedBox(height: 12),
            Row(
              children: [
                SkeletonLoader(
                  width: 120,
                  height: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(width: 16),
                SkeletonLoader(
                  width: 100,
                  height: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SkeletonLoader(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 8),
                SkeletonLoader(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// List skeleton para listas de elementos
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: SkeletonLoader(
          width: 40,
          height: 40,
          borderRadius: BorderRadius.circular(20),
        ),
        title: const SkeletonLoader(width: double.infinity, height: 16),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const SkeletonLoader(width: 150, height: 12),
            const SizedBox(height: 4),
            const SkeletonLoader(width: 120, height: 12),
          ],
        ),
        trailing: SkeletonLoader(
          width: 50,
          height: 24,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Skeleton para estadísticas (cards pequeños)
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          SkeletonLoader(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 6),
          const SkeletonLoader(width: 40, height: 20),
          const SizedBox(height: 4),
          const SkeletonLoader(width: 60, height: 12),
        ],
      ),
    );
  }
}

