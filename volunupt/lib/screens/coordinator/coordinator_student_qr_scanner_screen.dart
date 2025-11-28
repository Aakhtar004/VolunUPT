import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

import '../../services/student_qr_service.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/user_service.dart';
import '../../models/models.dart';
import '../../utils/feedback_overlay.dart';
import '../../utils/app_dialogs.dart';
import '../../utils/app_colors.dart';

class CoordinatorStudentQRScannerScreen extends StatefulWidget {
  final String eventId;
  final String subEventId;
  final String? eventTitle;
  final String? subEventTitle;

  const CoordinatorStudentQRScannerScreen({
    super.key,
    required this.eventId,
    required this.subEventId,
    this.eventTitle,
    this.subEventTitle,
  });

  @override
  State<CoordinatorStudentQRScannerScreen> createState() => _CoordinatorStudentQRScannerScreenState();
}

class _CoordinatorStudentQRScannerScreenState extends State<CoordinatorStudentQRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _processing = false;
  bool _confirming = false;
  String? _lastCode;

  @override
  void initState() {
    super.initState();
    // No bloquear al abrir - la validación se hará al escanear el QR
    debugPrint('✅ Pantalla de escáner QR abierta');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue;
    if (code == null || code.isEmpty || code == _lastCode) return;
    _lastCode = code;
    setState(() => _processing = true);

    try {
      final validation = await StudentQRService.validateScannedData(code);
      if (!validation.isValid || validation.userId == null) {
        _showMessage(validation.reason ?? 'QR inválido');
        return;
      }

      final studentId = validation.userId!;
      final coordinator = await AuthService.getCurrentUserData();
      
      if (coordinator == null) {
        debugPrint('❌ Coordinador es null al escanear');
        _showMessage('No se pudo verificar tu sesión. Por favor, inicia sesión nuevamente.');
        return;
      }
      
      debugPrint('🔍 Usuario escaneando: ${coordinator.displayName} (${coordinator.email})');
      debugPrint('🔍 Rol del usuario: ${coordinator.role}');
      debugPrint('🔍 Rol como string: ${coordinator.role.toString()}');
      
      // Permitir coordinadores y administradores - verificación más flexible
      final roleString = coordinator.role.toString().toLowerCase();
      final isCoordinator = coordinator.role == UserRole.coordinador || 
                           roleString.contains('coordinador');
      final isAdmin = coordinator.role == UserRole.administrador || 
                     roleString.contains('administrador');
      
      debugPrint('🔍 isCoordinator: $isCoordinator, isAdmin: $isAdmin');
      
      if (!isCoordinator && !isAdmin) {
        debugPrint('❌ Usuario no autorizado para escanear. Rol: ${coordinator.role}');
        _showMessage('No autorizado. Solo coordinadores y administradores pueden escanear.');
        return;
      }
      
      debugPrint('✅ Usuario autorizado para escanear QR');

      // Fetch student info for display
      final studentProfile = await UserService.getUserProfile(studentId);

      if (!mounted) return;
      await _showConfirmSheet(studentProfile);
    } catch (e) {
      _showMessage('No se pudo procesar el código QR');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showConfirmSheet(UserModel? student) async {
    final name = student?.displayName ?? 'Estudiante';
    final email = student?.email ?? '';
    final eventTitle = widget.eventTitle ?? 'Evento';
    final subEventTitle = widget.subEventTitle ?? 'Actividad';
    AppDialogs.modal(
      context,
      title: 'Confirmar asistencia',
      icon: Icons.qr_code_scanner,
      iconColor: AppColors.primary,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(name),
            subtitle: Text(email),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.event),
            title: Text(eventTitle),
            subtitle: Text(subEventTitle),
          ),
        ],
      ),
      actions: [
        AppDialogs.cancelAction(onPressed: () => Navigator.of(context).pop()),
        AppDialogs.primaryAction(
          label: 'Pasar asistencia',
          onPressed: () async {
            Navigator.of(context).pop();
            await _confirmCheckIn(student?.uid);
          },
        ),
      ],
    );
  }

  Future<void> _confirmCheckIn(String? studentId) async {
    if (studentId == null) {
      _showMessage('Estudiante inválido');
      return;
    }
    if (_confirming) return; // Evita doble envío por múltiples clics
    setState(() => _confirming = true);
    try {
      final coordinator = await AuthService.getCurrentUserData();
      if (coordinator == null) {
        _showMessage('Sesión inválida');
        return;
      }

      final canProceed = await AttendanceService.canCoordinatorCheckInStudent(
        coordinatorId: coordinator.uid,
        eventId: widget.eventId,
        subEventId: widget.subEventId,
        studentId: studentId,
      );
      if (!canProceed.allowed) {
        _showMessage(canProceed.reason ?? 'No se puede registrar asistencia');
        return;
      }

      await AttendanceService.coordinatorCheckInStudent(
        coordinatorId: coordinator.uid,
        eventId: widget.eventId,
        subEventId: widget.subEventId,
        studentId: studentId,
      );

      await StudentQRService.markQrUsed(studentId);
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      _showMessage('No se pudo registrar la asistencia');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _showSuccess() {
    HapticFeedback.lightImpact();
    FeedbackOverlay.showSuccess(context, 'Se registró la asistencia correctamente.');
  }

  void _showMessage(String message) {
    FeedbackOverlay.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final eventTitle = widget.eventTitle ?? 'Evento';
    final subEventTitle = widget.subEventTitle ?? 'Actividad';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasar asistencia'),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '$eventTitle • $subEventTitle',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_processing)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Escanea el QR del estudiante para registrar asistencia',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 72,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'torch',
                  backgroundColor: Colors.black.withAlpha(153),
                  foregroundColor: Colors.white,
                  onPressed: () => _controller.toggleTorch(),
                  child: const Icon(Icons.flashlight_on),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'camera',
                  backgroundColor: Colors.black.withAlpha(153),
                  foregroundColor: Colors.white,
                  onPressed: () => _controller.switchCamera(),
                  child: const Icon(Icons.cameraswitch),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}