import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionManagerService {
  static const String _lastActivityKey = 'last_activity';
  static const String _sessionTimeoutKey = 'session_timeout';
  static const Duration _defaultSessionTimeout = Duration(hours: 24);
  static const Duration _inactivityTimeout = Duration(minutes: 30);
  
  final FlutterSecureStorage _secureStorage;
  final FirebaseAuth _firebaseAuth;
  
  Timer? _inactivityTimer;
  Timer? _sessionCheckTimer;
  DateTime? _lastActivity;
  
  final StreamController<SessionEvent> _sessionEventController = 
      StreamController<SessionEvent>.broadcast();
  
  Stream<SessionEvent> get sessionEvents => _sessionEventController.stream;
  
  SessionManagerService(this._secureStorage, this._firebaseAuth) {
    _initializeSessionManager();
  }
  
  void _initializeSessionManager() {
    _updateLastActivity();
    _startSessionChecking();
  }
  
  void _startSessionChecking() {
    _sessionCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSessionValidity(),
    );
  }
  
  Future<void> _checkSessionValidity() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    
    final lastActivityString = await _secureStorage.read(key: _lastActivityKey);
    if (lastActivityString == null) {
      await _handleSessionExpired();
      return;
    }
    
    final lastActivity = DateTime.parse(lastActivityString);
    final now = DateTime.now();
    
    final timeSinceLastActivity = now.difference(lastActivity);
    
    if (timeSinceLastActivity > _inactivityTimeout) {
      await _handleInactivityTimeout();
    } else if (timeSinceLastActivity > _defaultSessionTimeout) {
      await _handleSessionExpired();
    }
  }
  
  Future<void> _handleInactivityTimeout() async {
    _sessionEventController.add(SessionEvent.inactivityWarning);
  }
  
  Future<void> _handleSessionExpired() async {
    await _clearSession();
    _sessionEventController.add(SessionEvent.sessionExpired);
  }
  
  Future<void> _clearSession() async {
    await _secureStorage.delete(key: _lastActivityKey);
    await _secureStorage.delete(key: _sessionTimeoutKey);
    await _firebaseAuth.signOut();
  }
  
  void updateActivity() {
    _updateLastActivity();
    _resetInactivityTimer();
  }
  
  Future<void> _updateLastActivity() async {
    _lastActivity = DateTime.now();
    await _secureStorage.write(
      key: _lastActivityKey,
      value: _lastActivity!.toIso8601String(),
    );
  }
  
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, () {
      _sessionEventController.add(SessionEvent.inactivityWarning);
    });
  }
  
  Future<bool> isSessionValid() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    
    final lastActivityString = await _secureStorage.read(key: _lastActivityKey);
    if (lastActivityString == null) return false;
    
    final lastActivity = DateTime.parse(lastActivityString);
    final timeSinceLastActivity = DateTime.now().difference(lastActivity);
    
    return timeSinceLastActivity <= _defaultSessionTimeout;
  }
  
  Future<void> extendSession() async {
    await _updateLastActivity();
    _resetInactivityTimer();
  }
  
  Future<void> startSession() async {
    await _updateLastActivity();
    _resetInactivityTimer();
    _sessionEventController.add(SessionEvent.sessionStarted);
  }
  
  Future<void> endSession() async {
    await _clearSession();
    _inactivityTimer?.cancel();
    _sessionCheckTimer?.cancel();
    _sessionEventController.add(SessionEvent.sessionEnded);
  }
  
  void dispose() {
    _inactivityTimer?.cancel();
    _sessionCheckTimer?.cancel();
    _sessionEventController.close();
  }
}

enum SessionEvent {
  sessionStarted,
  sessionEnded,
  sessionExpired,
  inactivityWarning,
}