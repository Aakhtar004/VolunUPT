import '../entities/system_health.dart';
import '../repositories/admin_repository.dart';

class GetSystemHealthUseCase {
  final AdminRepository _repository;

  GetSystemHealthUseCase(this._repository);

  Future<SystemHealth> execute() async {
    try {
      return await _repository.getSystemHealth();
    } catch (e) {
      throw Exception('Error al obtener estado del sistema: $e');
    }
  }

  Future<List<HealthCheck>> executeDetailedCheck() async {
    try {
      return await _repository.performDetailedHealthCheck();
    } catch (e) {
      throw Exception('Error al realizar verificación detallada: $e');
    }
  }

  Future<HealthCheck> checkService(String serviceName) async {
    try {
      return await _repository.checkSpecificService(serviceName);
    } catch (e) {
      throw Exception('Error al verificar servicio $serviceName: $e');
    }
  }

  Future<SystemMetrics> getCurrentMetrics() async {
    try {
      return await _repository.getCurrentSystemMetrics();
    } catch (e) {
      throw Exception('Error al obtener métricas actuales: $e');
    }
  }

  Future<List<SystemMetrics>> getMetricsHistory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _repository.getMetricsHistory(startDate, endDate);
    } catch (e) {
      throw Exception('Error al obtener historial de métricas: $e');
    }
  }

  Future<Map<String, dynamic>> getPerformanceReport() async {
    try {
      return await _repository.getPerformanceReport();
    } catch (e) {
      throw Exception('Error al obtener reporte de rendimiento: $e');
    }
  }

  Future<bool> isServiceHealthy(String serviceName) async {
    try {
      final check = await _repository.checkSpecificService(serviceName);
      return check.isHealthy;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, bool>> getAllServicesStatus() async {
    try {
      return await _repository.getAllServicesStatus();
    } catch (e) {
      throw Exception('Error al obtener estado de todos los servicios: $e');
    }
  }

  Future<void> restartService(String serviceName) async {
    try {
      await _repository.restartService(serviceName);
    } catch (e) {
      throw Exception('Error al reiniciar servicio $serviceName: $e');
    }
  }

  Future<List<String>> getSystemAlerts() async {
    try {
      return await _repository.getSystemAlerts();
    } catch (e) {
      throw Exception('Error al obtener alertas del sistema: $e');
    }
  }

  Future<void> acknowledgeAlert(String alertId) async {
    try {
      await _repository.acknowledgeAlert(alertId);
    } catch (e) {
      throw Exception('Error al reconocer alerta: $e');
    }
  }

  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      return await _repository.getDatabaseStats();
    } catch (e) {
      throw Exception('Error al obtener estadísticas de base de datos: $e');
    }
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      return await _repository.getStorageStats();
    } catch (e) {
      throw Exception('Error al obtener estadísticas de almacenamiento: $e');
    }
  }

  Future<void> performMaintenanceTask(String taskName) async {
    try {
      await _repository.performMaintenanceTask(taskName);
    } catch (e) {
      throw Exception('Error al realizar tarea de mantenimiento $taskName: $e');
    }
  }

  Future<List<String>> getScheduledMaintenanceTasks() async {
    try {
      return await _repository.getScheduledMaintenanceTasks();
    } catch (e) {
      throw Exception('Error al obtener tareas de mantenimiento programadas: $e');
    }
  }

  Future<void> scheduleMaintenanceTask(String taskName, DateTime scheduledTime) async {
    try {
      await _repository.scheduleMaintenanceTask(taskName, scheduledTime);
    } catch (e) {
      throw Exception('Error al programar tarea de mantenimiento: $e');
    }
  }

  Future<Map<String, dynamic>> getSystemConfiguration() async {
    try {
      return await _repository.getSystemConfiguration();
    } catch (e) {
      throw Exception('Error al obtener configuración del sistema: $e');
    }
  }

  Future<void> updateSystemConfiguration(Map<String, dynamic> config) async {
    try {
      await _repository.updateSystemConfiguration(config);
    } catch (e) {
      throw Exception('Error al actualizar configuración del sistema: $e');
    }
  }
}