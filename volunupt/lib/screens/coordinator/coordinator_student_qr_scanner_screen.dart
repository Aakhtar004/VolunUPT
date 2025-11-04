import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/student_qr_service.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/user_service.dart';
import '../../models/models.dart';

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
  String? _lastCode;

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
      if (coordinator == null || coordinator.role != UserRole.coordinador) {
        _showMessage('No autorizado. Inicia sesión como coordinador.');
        return;
      }

      // Fetch student info for display
      final studentProfile = await UserService.getUserProfile(studentId);

      if (!mounted) return;
      await _showConfirmSheet(studentProfile);
    } catch (e) {
      _showMessage('Error procesando QR: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showConfirmSheet(UserModel? student) async {
    final name = student?.displayName ?? 'Estudiante';
    final email = student?.email ?? '';
    final eventTitle = widget.eventTitle ?? 'Evento';
    final subEventTitle = widget.subEventTitle ?? 'Actividad';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Confirmar asistencia', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _confirmCheckIn(student?.uid);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Pasar asistencia'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmCheckIn(String? studentId) async {
    if (studentId == null) {
      _showMessage('Estudiante inválido');
      return;
    }
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
      _showMessage('Error al registrar asistencia: $e');
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Asistencia registrada'),
        content: const Text('Se registró la asistencia correctamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final eventTitle = widget.eventTitle ?? 'Evento';
    final subEventTitle = widget.subEventTitle ?? 'Actividad';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasar asistencia'),
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
        ],
      ),
    );
  }
}