import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/app_colors.dart';
import '../../utils/ui_feedback.dart';

class CertificatesScreen extends StatefulWidget {
  final UserModel user;

  const CertificatesScreen({super.key, required this.user});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _schoolController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificados'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Disponibles'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableCertificates(),
          _buildCertificateHistory(),
        ],
      ),
    );
  }

  Widget _buildAvailableCertificates() {
    return FutureBuilder<List<EventModel>>(
      future: CertificateService.getEligibleEventsForCertificate(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.workspace_premium_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No tienes certificados disponibles',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Completa eventos con más del 85% de asistencia para obtener certificados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.check_circle_outline, color: AppColors.success),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Completado',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showGenerateDialog(event),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Generar Certificado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCertificateHistory() {
    return StreamBuilder<List<CertificateModel>>(
      stream: CertificateService.getUserCertificates(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final certificates = snapshot.data ?? [];

        if (certificates.isEmpty) {
          return const Center(
            child: Text(
              'Aún no has generado certificados',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: certificates.length,
          itemBuilder: (context, index) {
            final cert = certificates[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 32),
                title: Text(cert.eventTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Generado: ${_formatDate(cert.issueDate)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareCertificate(cert),
                ),
                onTap: () => _showCertificateDetails(cert),
              ),
            );
          },
        );
      },
    );
  }

  void _showGenerateDialog(EventModel event) {
    _schoolController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar Certificado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por favor ingresa tu Escuela o Facultad para que aparezca en el certificado:'),
            const SizedBox(height: 16),
            TextField(
              controller: _schoolController,
              decoration: const InputDecoration(
                labelText: 'Escuela / Facultad',
                border: OutlineInputBorder(),
                hintText: 'Ej. Ingeniería de Sistemas',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_schoolController.text.trim().isEmpty) {
                UiFeedback.showError(context, 'Debes ingresar tu escuela');
                return;
              }
              Navigator.pop(context);
              _generateCertificate(event, _schoolController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Generar'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateCertificate(EventModel event, String school) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Obtener horas
      final hours = await CertificateService.getUserTotalHoursForEvent(widget.user.uid, event.eventId);
      
      // Generar código único
      final code = 'CERT-${event.eventId.substring(0, 5)}-${widget.user.uid.substring(0, 5)}'.toUpperCase();

      final file = await CertificateService.generateCertificate(
        userId: widget.user.uid,
        userName: widget.user.displayName,
        school: school,
        eventId: event.eventId,
        eventTitle: event.title,
        hours: hours,
        verificationCode: code,
      );
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de carga

      // Mostrar éxito y opción de abrir
      UiFeedback.showSuccess(context, 'Certificado generado correctamente');
      
      // Compartir/Abrir archivo
      await Share.shareXFiles([XFile(file.path)], text: 'Certificado - ${event.title}');

      // Recargar la vista
      setState(() {});

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading
      UiFeedback.showError(context, 'Error al generar: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  void _showCertificateDetails(CertificateModel certificate) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              certificate.eventTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Código: ${certificate.validationCode}'),
            Text('Fecha: ${_formatDate(certificate.issueDate)}'),
            Text('Horas: ${certificate.totalHours}'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _shareCertificate(certificate);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                ),
                // Aquí podríamos agregar opción de abrir directamente si OpenFile funciona
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCertificate(CertificateModel cert) async {
    if (cert.pdfUrl.isNotEmpty) {
      final file = File(cert.pdfUrl);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(cert.pdfUrl)], text: 'Certificado - ${cert.eventTitle}');
        return;
      }
    }
    if (!mounted) return;
    UiFeedback.showInfo(context, 'El archivo no se encuentra en el dispositivo.');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
