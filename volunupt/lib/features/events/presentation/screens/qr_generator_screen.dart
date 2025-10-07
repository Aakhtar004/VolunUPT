import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/event_entity.dart';
import '../providers/qr_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class QrGeneratorScreen extends ConsumerStatefulWidget {
  final EventEntity event;

  const QrGeneratorScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends ConsumerState<QrGeneratorScreen> {
  bool _isGenerating = false;
  String? _qrCode;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _loadExistingQrCode();
  }

  Future<void> _loadExistingQrCode() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    try {
      final existingQr = await ref.read(eventUserQrProvider(
        (eventId: widget.event.id, userId: currentUser.id)
      ).future);

      if (existingQr != null && existingQr.isValid) {
        setState(() {
          _qrCode = existingQr.qrCode;
          _expiresAt = existingQr.expiresAt;
        });
      }
    } catch (e) {
      // No hay QR existente o hay un error, se puede generar uno nuevo
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('QR - ${widget.event.title}'),
        elevation: 0,
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Usuario no autenticado'),
            );
          }

          return _buildContent(user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildEventInfo(),
          const SizedBox(height: 24),
          if (_qrCode != null) ...[
            _buildQrCode(),
            const SizedBox(height: 24),
            _buildQrInfo(),
          ] else ...[
            _buildGenerateSection(user),
          ],
          const SizedBox(height: 24),
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildEventInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.event.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.event.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Inicio: ${_formatDate(widget.event.startDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Capacidad: ${widget.event.capacity}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCode() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Tu Código QR',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: QrImageView(
                data: _qrCode!,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Información del QR',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Expira',
              value: _expiresAt != null ? _formatDate(_expiresAt!) : 'N/A',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.qr_code,
              label: 'Código',
              value: '${_qrCode!.substring(0, 8)}...',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _regenerateQrCode,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isGenerating ? 'Generando...' : 'Generar Nuevo QR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateSection(dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.qr_code,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Generar Código QR',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Genera tu código QR para registrar tu asistencia al evento',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : () => _generateQrCode(user),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code),
                label: Text(_isGenerating ? 'Generando...' : 'Generar QR'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Instrucciones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              '1. Genera tu código QR antes del evento',
            ),
            _buildInstructionItem(
              '2. Presenta el código al coordinador para registrar tu asistencia',
            ),
            _buildInstructionItem(
              '3. El código QR expira después del evento',
            ),
            _buildInstructionItem(
              '4. Puedes generar un nuevo código si es necesario',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQrCode(dynamic user) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final qrEntity = await ref.read(qrCodeNotifierProvider.notifier)
          .generateQrCode(widget.event.id, user.id);

      if (qrEntity != null) {
        setState(() {
          _qrCode = qrEntity.qrCode;
          _expiresAt = qrEntity.expiresAt;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Código QR generado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _regenerateQrCode() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    await _generateQrCode(currentUser);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}