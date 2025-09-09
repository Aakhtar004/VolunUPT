import 'package:flutter/material.dart';
import 'package:volunupt/domain/entities/campaign.dart';
import 'package:volunupt/domain/entities/qr_data.dart';
import 'package:volunupt/infraestructure/repositories/auth_repository_impl_local.dart';
import 'package:volunupt/infraestructure/datasources/auth_datasource_local.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DetalleCampaignScreen extends StatefulWidget {
  const DetalleCampaignScreen({super.key});

  @override
  State<DetalleCampaignScreen> createState() => _DetalleCampaignScreenState();
}

class _DetalleCampaignScreenState extends State<DetalleCampaignScreen> {
  String? userRole;
  bool isFromInscripciones = false;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtener argumentos para saber el contexto
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      isFromInscripciones = arguments['fromInscripciones'] ?? false;
    }
  }

  Future<void> _getUserRole() async {
    final authRepository = AuthRepositoryImplLocal(AuthDatasourceLocal());
    final role = await authRepository.getUserRole();
    setState(() {
      userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    late Campaign campaign;

    if (arguments is Map) {
      campaign = arguments['campaign'] as Campaign;
      isFromInscripciones = arguments['fromInscripciones'] ?? false;
    } else {
      campaign = arguments as Campaign;
      isFromInscripciones = false;
    }

    if (userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFD3DBE7),
      body: CustomScrollView(
        slivers: [
          // Header con imagen
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF253A6B),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isFromInscripciones ? 'Mi Inscripción' : 'Detalles de la Campaña',
              style: const TextStyle(color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF7CB342), Color(0xFF4CAF50)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.eco, size: 80, color: Colors.white),
                ),
              ),
            ),
          ),
          // Contenido
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    campaign.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF253A6B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    campaign.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR CODE SOLO PARA ESTUDIANTE INSCRITO (desde inscripciones)
                  if (userRole == 'student' && isFromInscripciones) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Tu Código QR de Asistencia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF253A6B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: _generateStudentQR(campaign.id),
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Muestra este código al ingeniero para registrar tu asistencia',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Información de la fecha y ubicación
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        campaign.date,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        campaign.location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Requisitos
                  const Text(
                    'Requisitos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF253A6B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...campaign.requirements
                      .map(
                        (req) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  req,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  const SizedBox(height: 24),

                  // Horas RSU
                  const Text(
                    'Horas RSU',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF253A6B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${campaign.rsuHours} horas',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Coordinador
                  const Text(
                    'Coordinador',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF253A6B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF253A6B),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            campaign.coordinatorName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            campaign.coordinatorEmail,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Botones SOLO desde catálogo para estudiantes
                  if (userRole == 'student' &&
                      !isFromInscripciones &&
                      campaign.status != 'Completada') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: campaign.availableSpots > 0
                            ? () => _showInscripcionDialog(context, campaign)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          campaign.availableSpots > 0
                              ? 'Inscribirme'
                              : 'Sin cupos disponibles',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Botón de cancelar SOLO desde inscripciones
                  if (userRole == 'student' &&
                      isFromInscripciones &&
                      campaign.status == 'Confirmado') ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showCancelDialog(context, campaign),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar inscripción',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
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

  String _generateStudentQR(String courseId) {
    final qrData = QRData(
      engineerId: '2', // ID del ingeniero (hardcodeado)
      courseId: courseId,
      studentId: '1', // ID del alumno1 (hardcodeado)
      timestamp: DateTime.now(),
    );
    return qrData.generateHash();
  }

  void _showInscripcionDialog(BuildContext context, Campaign campaign) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Inscripción'),
          content: Text('¿Deseas inscribirte a "${campaign.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '¡Inscripción exitosa! Ahora puedes ver tu QR en "Mis Inscripciones"',
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
                // Opcional: navegar automáticamente a inscripciones
                // Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Inscribirme'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, Campaign campaign) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Inscripción'),
          content: Text(
            '¿Estás seguro de que deseas cancelar tu inscripción a "${campaign.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inscripción cancelada exitosamente'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );
  }
}
