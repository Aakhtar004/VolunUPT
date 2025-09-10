import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:volunupt/domain/entities/qr_data.dart';

class QRAttendanceScreen extends StatefulWidget {
  const QRAttendanceScreen({super.key});

  @override
  State<QRAttendanceScreen> createState() => _QRAttendanceScreenState();
}

class _QRAttendanceScreenState extends State<QRAttendanceScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String? scannedData;
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3DBE7),
      appBar: AppBar(
        title: const Text('Tomar Asistencia'),
        backgroundColor: const Color(0xFF253A6B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Instrucciones
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Column(
              children: [
                Icon(Icons.qr_code_scanner, size: 48, color: Color(0xFF253A6B)),
                SizedBox(height: 8),
                Text(
                  'Escanea el código QR del estudiante',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF253A6B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Apunta la cámara hacia el código QR',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Scanner QR
          Expanded(
            flex: 4,
            child: isScanning
                ? MobileScanner(
                    controller: cameraController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null && isScanning) {
                          setState(() {
                            scannedData = barcode.rawValue;
                            isScanning = false;
                          });
                          _validateQRCode(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 80,
                            color: Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Asistencia registrada exitosamente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF253A6B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          // Información del resultado
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  if (scannedData != null) ...[
                    const Text(
                      'Último código escaneado:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF253A6B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scannedData!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!isScanning) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isScanning = true;
                            scannedData = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Escanear otro código'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _validateQRCode(String qrCode) {
    final qrData = QRData.fromHash(qrCode);

    if (qrData != null) {
      // Validar que sea del curso correcto (ID 1) y del ingeniero correcto (ID 2)
      if (qrData.courseId == '1' && qrData.engineerId == '2') {
        // QR válido
        _showSuccessDialog(
          'Asistencia registrada para el estudiante ${qrData.studentId}',
        );
      } else {
        // QR de otro curso o ingeniero
        _showErrorDialog('Este código QR no corresponde a este curso');
      }
    } else {
      // QR inválido
      _showErrorDialog('Código QR inválido o no reconocido');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('¡Éxito!'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
