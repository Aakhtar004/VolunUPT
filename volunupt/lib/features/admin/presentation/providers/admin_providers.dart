import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/activity_log.dart';
import '../../domain/entities/system_health.dart';
import '../../domain/usecases/get_admin_stats_usecase.dart';
import '../../domain/usecases/get_recent_activity_usecase.dart';
import '../../domain/usecases/get_system_health_usecase.dart';
import '../../../shared/data/repositories/firebase_admin_repository.dart';

final adminRepositoryProvider = Provider((ref) => FirebaseAdminRepository());

final getAdminStatsUseCaseProvider = Provider((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return GetAdminStatsUseCase(repository);
});

final getRecentActivityUseCaseProvider = Provider((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return GetRecentActivityUseCase(repository);
});

final getSystemHealthUseCaseProvider = Provider((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return GetSystemHealthUseCase(repository);
});

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final useCase = ref.watch(getAdminStatsUseCaseProvider);
  return await useCase.execute();
});

final recentActivityProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final useCase = ref.watch(getRecentActivityUseCaseProvider);
  return await useCase.execute();
});

final systemHealthProvider = FutureProvider<SystemHealth>((ref) async {
  final useCase = ref.watch(getSystemHealthUseCaseProvider);
  return await useCase.execute();
});

final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final adminStatsFilteredProvider = FutureProvider<AdminStats>((ref) async {
  final useCase = ref.watch(getAdminStatsUseCaseProvider);
  final dateRange = ref.watch(selectedDateRangeProvider);
  
  if (dateRange != null) {
    return await useCase.executeWithDateRange(dateRange.start, dateRange.end);
  }
  
  return await useCase.execute();
});

final userManagementProvider = StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return UserManagementNotifier(repository);
});

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final FirebaseAdminRepository _repository;

  UserManagementNotifier(this._repository) : super(const UserManagementState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final users = await _repository.getAllUsers();
      state = state.copyWith(
        users: users,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _repository.updateUserRole(userId, newRole);
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _repository.toggleUserStatus(userId, isActive);
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _repository.deleteUser(userId);
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class UserManagementState {
  final List<AdminUser> users;
  final bool isLoading;
  final String? error;

  const UserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UserManagementState copyWith({
    List<AdminUser>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final int totalInscriptions;
  final int attendedEvents;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
    required this.totalInscriptions,
    required this.attendedEvents,
  });

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'estudiante',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
      totalInscriptions: map['totalInscriptions'] ?? 0,
      attendedEvents: map['attendedEvents'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'totalInscriptions': totalInscriptions,
      'attendedEvents': attendedEvents,
    };
  }
}