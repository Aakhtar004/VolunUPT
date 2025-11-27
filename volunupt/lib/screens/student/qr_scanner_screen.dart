import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../models/sub_event_model.dart';
import '../../models/event_model.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey _scannerKey = GlobalKey(debugLabel: 'MobileScanner');
  MobileScannerController? controller;
  bool _isProcessing = false;
  bool _hasPermission = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    // Obtener usuario actual
    final user = await AuthService.getCurrentUserData();
    if (user != null) {
      _currentUserId = user.uid;
    }

    // Solicitar permisos de cámara
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status == PermissionStatus.granted;
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // Restart the scanner on hot-reload
    controller?.stop();
    controller?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () async {
              await controller?.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () async {
              await controller?.switchCamera();
            },
          ),
        ],
      ),
      body: _hasPermission ? _buildScanner() : _buildPermissionDenied(),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              MobileScanner(
                key: _scannerKey,
                controller: controller ??= MobileScannerController(
                  detectionSpeed: DetectionSpeed.noDuplicates,
                  facing: CameraFacing.back,
                ),
                onDetect: _onDetect,
              ),
              // Simple overlay similar to QrScannerOverlayShape
              IgnorePointer(
                child: Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Procesando...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container
            (
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 36, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Apunta la cámara hacia el código QR del evento',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Permisos de cámara requeridos',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Para escanear códigos QR necesitamos acceso a tu cámara.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final status = await Permission.camera.request();
                setState(() {
                  _hasPermission = status == PermissionStatus.granted;
                });
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Conceder permisos'),
            ),
          ],
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _processQRCode(code);
        break;
      }
    }
  }

  Future<void> _processQRCode(String qrCode) async {
    if (_currentUserId == null) {
      _showErrorDialog('Error', 'Usuario no autenticado');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Pausar la cámara mientras procesamos
      await controller?.stop();

      // Verificar si el usuario puede hacer check-in
      final canCheckIn = await AttendanceService.canUserCheckIn(
        _currentUserId!,
        qrCode,
      );

      if (!canCheckIn['canCheckIn']) {
        _showErrorDialog(
          'No se puede registrar asistencia',
          canCheckIn['reason'],
        );
        return;
      }

      // Mostrar información del evento antes de confirmar
      final eventInfo = await AttendanceService.getCheckInInfo(qrCode);
      if (eventInfo['isValid']) {
        _showCheckInConfirmation(qrCode, eventInfo);
      } else {
        _showErrorDialog(
          'Código QR inválido',
          eventInfo['error'] ?? 'Código no reconocido',
        );
      }
    } catch (e) {
      _showErrorDialog('Error', 'No se pudo procesar el código QR. Inténtalo nuevamente');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showCheckInConfirmation(String qrCode, Map<String, dynamic> eventInfo) {
    final subEvent = eventInfo['subEvent'] as SubEventModel?;
    final event = eventInfo['event'] as EventModel?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Check-in'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event != null) ...[
              Text(
                'Programa: ${event.title}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            if (subEvent != null) ...[
              Text('Actividad: ${subEvent.title}'),
              const SizedBox(height: 4),
              Text('Fecha: ${_formatDate(subEvent.startTime)}'),
              const SizedBox(height: 4),
              Text(
                'Hora: ${_formatTime(subEvent.startTime)} - ${_formatTime(subEvent.endTime)}',
              ),
              const SizedBox(height: 4),
              Text('Ubicación: ${subEvent.location}'),
            ],
            const SizedBox(height: 16),
            const Text(
              '¿Confirmas tu asistencia a este evento?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeScanning();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performCheckIn(qrCode);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCheckIn(String qrCode) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      await AttendanceService.checkInStudent(
        userId: _currentUserId!,
        qrCodeData: qrCode,
      );

      _showSuccessDialog(
        'Check-in exitoso',
        'Tu asistencia ha sido registrada correctamente. El coordinador validará tu participación.',
      );
    } catch (e) {
      _showErrorDialog('Error en check-in', e.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Volver a la pantalla anterior
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeScanning();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _resumeScanning() {
    controller?.start();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
