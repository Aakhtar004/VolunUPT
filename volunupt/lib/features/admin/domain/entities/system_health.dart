import 'package:cloud_firestore/cloud_firestore.dart';

class SystemHealth {
  final String databaseStatus;
  final String authStatus;
  final String storageStatus;
  final String notificationStatus;
  final DateTime lastChecked;
  final List<HealthCheck> checks;
  final SystemMetrics metrics;

  const SystemHealth({
    required this.databaseStatus,
    required this.authStatus,
    required this.storageStatus,
    required this.notificationStatus,
    required this.lastChecked,
    required this.checks,
    required this.metrics,
  });

  factory SystemHealth.fromMap(Map<String, dynamic> map) {
    return SystemHealth(
      databaseStatus: map['databaseStatus'] ?? 'unknown',
      authStatus: map['authStatus'] ?? 'unknown',
      storageStatus: map['storageStatus'] ?? 'unknown',
      notificationStatus: map['notificationStatus'] ?? 'unknown',
      lastChecked: _parseDate(map['lastChecked']),
      checks:
          (map['checks'] as List<dynamic>?)
              ?.map((item) => HealthCheck.fromMap(item))
              .toList() ??
          [],
      metrics: SystemMetrics.fromMap(map['metrics'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'databaseStatus': databaseStatus,
      'authStatus': authStatus,
      'storageStatus': storageStatus,
      'notificationStatus': notificationStatus,
      'lastChecked': lastChecked.toIso8601String(),
      'checks': checks.map((check) => check.toMap()).toList(),
      'metrics': metrics.toMap(),
    };
  }

  bool get isHealthy {
    return databaseStatus == 'healthy' &&
        authStatus == 'healthy' &&
        storageStatus == 'healthy' &&
        notificationStatus == 'healthy';
  }

  SystemHealth copyWith({
    String? databaseStatus,
    String? authStatus,
    String? storageStatus,
    String? notificationStatus,
    DateTime? lastChecked,
    List<HealthCheck>? checks,
    SystemMetrics? metrics,
  }) {
    return SystemHealth(
      databaseStatus: databaseStatus ?? this.databaseStatus,
      authStatus: authStatus ?? this.authStatus,
      storageStatus: storageStatus ?? this.storageStatus,
      notificationStatus: notificationStatus ?? this.notificationStatus,
      lastChecked: lastChecked ?? this.lastChecked,
      checks: checks ?? this.checks,
      metrics: metrics ?? this.metrics,
    );
  }
}

class HealthCheck {
  final String service;
  final String status;
  final String message;
  final DateTime timestamp;
  final int responseTime;
  final Map<String, dynamic> details;

  const HealthCheck({
    required this.service,
    required this.status,
    required this.message,
    required this.timestamp,
    required this.responseTime,
    required this.details,
  });

  factory HealthCheck.fromMap(Map<String, dynamic> map) {
    return HealthCheck(
      service: map['service'] ?? '',
      status: map['status'] ?? 'unknown',
      message: map['message'] ?? '',
      timestamp: _parseDate(map['timestamp']),
      responseTime: map['responseTime'] ?? 0,
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service': service,
      'status': status,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'responseTime': responseTime,
      'details': details,
    };
  }

  bool get isHealthy => status == 'healthy';
}

class SystemMetrics {
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final int activeConnections;
  final int requestsPerMinute;
  final double averageResponseTime;
  final int errorRate;
  final DateTime lastUpdated;

  const SystemMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.activeConnections,
    required this.requestsPerMinute,
    required this.averageResponseTime,
    required this.errorRate,
    required this.lastUpdated,
  });

  factory SystemMetrics.fromMap(Map<String, dynamic> map) {
    return SystemMetrics(
      cpuUsage: (map['cpuUsage'] ?? 0.0).toDouble(),
      memoryUsage: (map['memoryUsage'] ?? 0.0).toDouble(),
      diskUsage: (map['diskUsage'] ?? 0.0).toDouble(),
      activeConnections: map['activeConnections'] ?? 0,
      requestsPerMinute: map['requestsPerMinute'] ?? 0,
      averageResponseTime: (map['averageResponseTime'] ?? 0.0).toDouble(),
      errorRate: map['errorRate'] ?? 0,
      lastUpdated: _parseDate(map['lastUpdated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'diskUsage': diskUsage,
      'activeConnections': activeConnections,
      'requestsPerMinute': requestsPerMinute,
      'averageResponseTime': averageResponseTime,
      'errorRate': errorRate,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

enum HealthStatus {
  healthy('healthy', 'Saludable'),
  warning('warning', 'Advertencia'),
  critical('critical', 'Crítico'),
  unknown('unknown', 'Desconocido');

  const HealthStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static HealthStatus fromValue(String value) {
    return HealthStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => HealthStatus.unknown,
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
