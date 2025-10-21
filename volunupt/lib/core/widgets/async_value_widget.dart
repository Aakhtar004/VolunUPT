import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'empty_state_widget.dart';
import '../providers/connectivity_providers.dart';
import '../services/connectivity_service.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final Widget Function()? empty;
  final bool Function(T data)? isEmpty;
  final String? loadingMessage;
  final String? emptyTitle;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final VoidCallback? onRetry;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.empty,
    this.isEmpty,
    this.loadingMessage,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) {
        final isDataEmpty = isEmpty?.call(data) ?? _isDataEmpty(data);
        
        if (isDataEmpty) {
          return empty?.call() ?? _buildDefaultEmpty();
        }
        
        return this.data(data);
      },
      loading: () => loading?.call() ?? _buildDefaultLoading(),
      error: (err, stack) => error?.call(err, stack) ?? _buildDefaultError(err),
    );
  }

  bool _isDataEmpty(T data) {
    if (data is List) {
      return data.isEmpty;
    }
    if (data is Map) {
      return data.isEmpty;
    }
    if (data is String) {
      return data.isEmpty;
    }
    return data == null;
  }

  Widget _buildDefaultLoading() {
    return LoadingStateWidget(message: loadingMessage);
  }

  Widget _buildDefaultEmpty() {
    return EmptyStateWidget(
      icon: emptyIcon ?? Icons.inbox_outlined,
      title: emptyTitle ?? 'No hay datos disponibles',
      message: emptyMessage ?? 'No se encontraron elementos para mostrar.',
      actionText: onRetry != null ? 'Actualizar' : null,
      onActionPressed: onRetry,
    );
  }

  Widget _buildDefaultError(Object error) {
    return EmptyStateWidget.error(
      onActionPressed: onRetry,
    );
  }
}

class AsyncValueListWidget<T> extends StatelessWidget {
  final AsyncValue<List<T>> value;
  final Widget Function(List<T> data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final Widget Function()? empty;
  final String? loadingMessage;
  final String? emptyTitle;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final VoidCallback? onRetry;

  const AsyncValueListWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.empty,
    this.loadingMessage,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncValueWidget<List<T>>(
      value: value,
      data: data,
      loading: loading,
      error: error,
      empty: empty,
      isEmpty: (list) => list.isEmpty,
      loadingMessage: loadingMessage,
      emptyTitle: emptyTitle,
      emptyMessage: emptyMessage,
      emptyIcon: emptyIcon,
      onRetry: onRetry,
    );
  }
}

class ConnectivityAwareWidget extends ConsumerWidget {
  final Widget child;
  final Widget Function()? offlineWidget;

  const ConnectivityAwareWidget({
    super.key,
    required this.child,
    this.offlineWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    return connectivityAsync.when(
      data: (status) {
        if (status == ConnectivityStatus.disconnected) {
          return offlineWidget?.call() ?? const EmptyStateWidget.noConnection();
        }
        return child;
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}