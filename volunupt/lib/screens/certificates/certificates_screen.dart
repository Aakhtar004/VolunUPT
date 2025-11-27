import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/models.dart';
import '../../services/services.dart';

class CertificatesScreen extends StatefulWidget {
  final UserModel user;

  const CertificatesScreen({super.key, required this.user});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  // Cache ligero para títulos de eventos
  final Map<String, String> _eventTitleCache = {};

  Future<String> _getEventTitle(String eventId) async {
    if (_eventTitleCache.containsKey(eventId)) {
      return _eventTitleCache[eventId]!;
    }
    try {
      final event = await EventService.getEventById(eventId);
      final title = event?.title ?? 'Evento $eventId';
      _eventTitleCache[eventId] = title;
      return title;
    } catch (_) {
      return 'Evento $eventId';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Certificados'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CertificateModel>>(
        stream: CertificateService.getUserCertificates(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Mostrar el estado vacío cuando ocurre un error (p.ej., tablas/índices faltantes)
            return _buildEmptyState();
          }

          final certificates = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Lista de certificados
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Certificados',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (certificates.isEmpty)
                        _buildEmptyState()
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: certificates.length,
                            itemBuilder: (context, index) {
                              final certificate = certificates[index];
                              return _buildCertificateCard(certificate);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: null,
    );
  }


  Widget _buildCertificateCard(CertificateModel certificate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCertificateDetails(certificate),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: _getEventTitle(certificate.baseEventId),
                          builder: (context, snapshot) {
                            final title = snapshot.data ?? 'Programa';
                            return Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Emitido el ${_formatDate(certificate.dateIssued)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.access_time,
                    '${certificate.hoursCompleted.toStringAsFixed(1)} horas',
                    AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_membership, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No tienes certificados disponibles',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  

  void _showCertificateDetails(CertificateModel certificate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Título
                Text(
                  'Detalles del Certificado',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Detalles
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Usuario', widget.user.displayName),
                        _buildDetailRow(
                          'Horas completadas',
                          '${certificate.hoursCompleted.toStringAsFixed(1)} horas',
                        ),
                        _buildDetailRow(
                          'Fecha de emisión',
                          _formatDate(certificate.dateIssued),
                        ),
                        FutureBuilder<String>(
                          future: _getEventTitle(certificate.baseEventId),
                          builder: (context, snapshot) {
                            final title = snapshot.data ?? 'Programa';
                            return _buildDetailRow('Programa', title);
                          },
                        ),

                        const SizedBox(height: 20),

                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _downloadCertificate(certificate),
                                icon: const Icon(Icons.download),
                                label: const Text('Descargar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _shareCertificate(certificate),
                                icon: const Icon(Icons.share),
                                label: const Text('Compartir'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }


  void _downloadCertificate(CertificateModel certificate) async {
    try {
      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Descargando certificado...'),
            ],
          ),
        ),
      );

      // Simular descarga (en implementación real, aquí se descargaría el PDF)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.of(context).pop(); // Cerrar diálogo de carga

      final eventTitle = await _getEventTitle(certificate.baseEventId);
      if (!mounted) return;

      // Mostrar diálogo de éxito con opciones
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Row(
            children: [
              Icon(Icons.download_done, color: AppColors.success),
              SizedBox(width: 8),
              Text('Descarga completada'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tu certificado ha sido descargado exitosamente.'),
              const SizedBox(height: 12),
              Text(
                'Certificado: $eventTitle',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Fecha de emisión: ${_formatDate(certificate.dateIssued)}'),
              Text('Horas certificadas: ${certificate.hoursCompleted}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _shareCertificate(certificate);
              },
              icon: const Icon(Icons.share),
              label: const Text('Compartir'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar diálogo de carga si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo descargar el certificado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareCertificate(CertificateModel certificate) async {
    try {
      final eventTitle = await _getEventTitle(certificate.baseEventId);
      if (!mounted) return;
      // Mostrar opciones de compartir
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Compartir certificado',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                eventTitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Opciones de compartir
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    icon: Icons.email,
                    label: 'Email',
                    onTap: () => _shareViaEmail(certificate, eventTitle),
                  ),
                  _buildShareOption(
                    icon: Icons.message,
                    label: 'WhatsApp',
                    onTap: () => _shareViaWhatsApp(certificate, eventTitle),
                  ),
                  _buildShareOption(
                    icon: Icons.link,
                    label: 'Copiar enlace',
                    onTap: () => _copyShareLink(certificate),
                  ),
                  _buildShareOption(
                    icon: Icons.more_horiz,
                    label: 'Más opciones',
                    onTap: () => _shareViaSystem(certificate, eventTitle),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo compartir el certificado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _shareViaEmail(CertificateModel certificate, String eventTitle) async {
    Navigator.of(context).pop(); // Cerrar modal

    final subject = 'Certificado de Voluntariado - $eventTitle';
    final body =
        '''
Hola,

Te comparto mi certificado de voluntariado:

📋 Programa: $eventTitle
⏰ Horas completadas: ${certificate.hoursCompleted}
📅 Fecha de emisión: ${_formatDate(certificate.dateIssued)}
🔗 Verificar certificado: https://volunupt.app/verify/${certificate.certificateId}

¡Gracias por tu interés en el voluntariado universitario!

Saludos,
${widget.user.displayName}
    ''';

    // En implementación real, aquí se abriría la app de email
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo cliente de email...'),
        action: SnackBarAction(
          label: 'Copiar texto',
          onPressed: () {
            // Copiar al portapapeles
            _copyToClipboard('$subject\n\n$body');
          },
        ),
      ),
    );
  }

  void _shareViaWhatsApp(CertificateModel certificate, String eventTitle) async {
    Navigator.of(context).pop(); // Cerrar modal

    final message =
        '''
🎓 ¡Obtuve mi certificado de voluntariado!

📋 Programa: $eventTitle
⏰ Horas completadas: ${certificate.hoursCompleted}
📅 Fecha: ${_formatDate(certificate.dateIssued)}

🔗 Verificar: https://volunupt.app/verify/${certificate.certificateId}

#VoluntariadoUPT #CertificadoVoluntariado
    ''';

    // En implementación real, aquí se abriría WhatsApp
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo WhatsApp...'),
        action: SnackBarAction(
          label: 'Copiar mensaje',
          onPressed: () {
            _copyToClipboard(message);
          },
        ),
      ),
    );
  }

  void _copyShareLink(CertificateModel certificate) async {
    Navigator.of(context).pop(); // Cerrar modal

    final link = 'https://volunupt.app/verify/${certificate.certificateId}';
    await _copyToClipboard(link);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
        content: Text('Enlace copiado al portapapeles'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareViaSystem(CertificateModel certificate, String eventTitle) async {
    Navigator.of(context).pop(); // Cerrar modal

    final text =
        '''
🎓 Certificado de Voluntariado

📋 Evento $eventTitle
⏰ ${certificate.hoursCompleted} horas
📅 ${_formatDate(certificate.dateIssued)}

🔗 Verificar: https://volunupt.app/verify/${certificate.certificateId}
    ''';

    // En implementación real, aquí se usaría el share nativo del sistema
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo opciones de compartir del sistema...'),
        action: SnackBarAction(
          label: 'Copiar',
          onPressed: () {
            _copyToClipboard(text);
          },
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    // En implementación real, aquí se copiaría al portapapeles
    // Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado al portapapeles'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
