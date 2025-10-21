import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum ConnectivityStatus {
  connected,
  disconnected,
  unknown,
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final StreamController<ConnectivityStatus> _connectivityController =
      StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get connectivityStream =>
      _connectivityController.stream;

  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  Timer? _connectivityTimer;

  ConnectivityStatus get currentStatus => _currentStatus;

  void initialize() {
    _startConnectivityCheck();
  }

  void _startConnectivityCheck() {
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnectivity(),
    );
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _hasInternetConnection();
      final newStatus = result 
          ? ConnectivityStatus.connected 
          : ConnectivityStatus.disconnected;

      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _connectivityController.add(_currentStatus);
      }
    } catch (e) {
      if (_currentStatus != ConnectivityStatus.disconnected) {
        _currentStatus = ConnectivityStatus.disconnected;
        _connectivityController.add(_currentStatus);
      }
    }
  }

  Future<bool> _hasInternetConnection() async {
    if (kIsWeb) {
      return true;
    }

    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkConnectivity() async {
    return await _hasInternetConnection();
  }

  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
  }
}