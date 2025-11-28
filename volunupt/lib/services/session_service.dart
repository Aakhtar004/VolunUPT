import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class SessionService {
  static Timer? _inactivityTimer;
  static Timer? _sessionCheckTimer;
  static DateTime _lastActivity = DateTime.now();
  
  // Configuración de timeouts (en minutos)
  static const int _inactivityTimeoutMinutes = 30; // 30 minutos de inactividad
  static const int _sessionCheckIntervalMinutes = 5; // Verificar sesión cada 5 minutos
  
  // Callbacks
  static VoidCallback? _onSessionExpired;
  static VoidCallback? _onInactivityWarning;
  
  /// Inicializar el servicio de sesiones
  static void initialize({
    VoidCallback? onSessionExpired,
    VoidCallback? onInactivityWarning,
  }) {
    _onSessionExpired = onSessionExpired;
    _onInactivityWarning = onInactivityWarning;
    
    _startSessionMonitoring();
    _resetInactivityTimer();
  }
  
  /// Iniciar monitoreo de sesión
  static void _startSessionMonitoring() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(
      Duration(minutes: _sessionCheckIntervalMinutes),
      (timer) async {
        final isValid = await AuthService.isSessionValid();
        if (!isValid) {
          await _handleSessionExpired();
        } else {
          // Actualizar último acceso si la sesión es válida
          await AuthService.updateLastAccess();
        }
      },
    );
  }
  
  /// Reiniciar el timer de inactividad
  static void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _lastActivity = DateTime.now();
    
    _inactivityTimer = Timer(
      Duration(minutes: _inactivityTimeoutMinutes),
      () async {
        await _handleInactivityTimeout();
      },
    );
  }
  
  /// Registrar actividad del usuario
  static void recordActivity() {
    _lastActivity = DateTime.now();
    _resetInactivityTimer();
  }
  
  /// Manejar timeout por inactividad
  static Future<void> _handleInactivityTimeout() async {
    try {
      // Verificar si realmente ha pasado el tiempo de inactividad
      final timeSinceLastActivity = DateTime.now().difference(_lastActivity);
      
      if (timeSinceLastActivity.inMinutes >= _inactivityTimeoutMinutes) {
        // Mostrar advertencia primero (opcional)
        _onInactivityWarning?.call();
        
        // Esperar un poco y luego cerrar sesión
        await Future.delayed(const Duration(seconds: 3));
        await _handleSessionExpired();
      } else {
        // Reiniciar timer si no ha pasado suficiente tiempo
        _resetInactivityTimer();
      }
    } catch (e) {
      debugPrint('Error en _handleInactivityTimeout: $e');
    }
  }
  
  /// Manejar expiración de sesión
  static Future<void> _handleSessionExpired() async {
    try {
      await AuthService.signOut();
      _cleanup();
      _onSessionExpired?.call();
    } catch (e) {
      debugPrint('Error en _handleSessionExpired: $e');
    }
  }
  
  /// Limpiar timers y recursos
  static void _cleanup() {
    _inactivityTimer?.cancel();
    _sessionCheckTimer?.cancel();
    _inactivityTimer = null;
    _sessionCheckTimer = null;
  }

  /// Pausar monitoreo (cuando la app va a background)
  static void pause() {
    _inactivityTimer?.cancel();
    _sessionCheckTimer?.cancel();
  }

  /// Reanudar monitoreo (cuando la app vuelve a foreground)
  static void resume() {
    if (AuthService.isAuthenticated) {
      _startSessionMonitoring();
      
      // Verificar si expiró durante el tiempo en background
      final timeSinceLastActivity = DateTime.now().difference(_lastActivity);
      if (timeSinceLastActivity.inMinutes >= _inactivityTimeoutMinutes) {
        _handleSessionExpired();
      } else {
        // Si no ha expirado, reiniciar el timer con el tiempo restante
        _resetInactivityTimer();
      }
    }
  }

  /// Cerrar sesión manualmente
  static Future<void> logout() async {
    await AuthService.signOut();
    _cleanup();
  }
  
  /// Obtener tiempo restante de inactividad (en minutos)
  static int get remainingInactivityMinutes {
    final timeSinceLastActivity = DateTime.now().difference(_lastActivity);
    final remaining = _inactivityTimeoutMinutes - timeSinceLastActivity.inMinutes;
    return remaining > 0 ? remaining : 0;
  }
  
  /// Verificar si la sesión está cerca de expirar
  static bool get isNearExpiration {
    return remainingInactivityMinutes <= 5; // Últimos 5 minutos
  }
  
  /// Extender sesión (resetear timer de inactividad)
  static void extendSession() {
    recordActivity();
  }
  
  /// Destruir el servicio
  static void dispose() {
    _cleanup();
    _onSessionExpired = null;
    _onInactivityWarning = null;
  }
}