import 'package:flutter/material.dart';
import 'package:volunupt/infraestructure/datasources/local_data_service.dart';
import 'package:volunupt/domain/entities/campaign.dart';

class InscripcionesScreen extends StatelessWidget {
  const InscripcionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFD3DBE7),
        body: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF253A6B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Mis Inscripciones',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(text: 'Próximas'),
                      Tab(text: 'Pasadas'),
                      Tab(text: 'Lista de espera'),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildProximasTab(),
                  _buildPasadasTab(),
                  _buildListaEsperaTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProximasTab() {
    final registrations = LocalDataService.getStudentRegistrations()
        .where((c) => c.status == 'Confirmado')
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: registrations.length,
      itemBuilder: (context, index) {
        final campaign = registrations[index];
        return _buildInscripcionCard(context, campaign, true);
      },
    );
  }

  Widget _buildPasadasTab() {
    final completed = LocalDataService.getCampaignsForStudent()
        .where((c) => c.status == 'Completada')
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completed.length,
      itemBuilder: (context, index) {
        final campaign = completed[index];
        return _buildInscripcionCard(context, campaign, false);
      },
    );
  }

  Widget _buildListaEsperaTab() {
    final waiting = LocalDataService.getCampaignsForStudent()
        .where((c) => c.status == 'Lista de espera')
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: waiting.length,
      itemBuilder: (context, index) {
        final campaign = waiting[index];
        return _buildInscripcionCard(context, campaign, false);
      },
    );
  }

  Widget _buildInscripcionCard(
    BuildContext context,
    Campaign campaign,
    bool isActive,
  ) {
    Color statusColor;
    String buttonText;

    switch (campaign.status) {
      case 'Confirmado':
        statusColor = Colors.green;
        buttonText = 'Confirmado';
        break;
      case 'Pendiente':
        statusColor = Colors.orange;
        buttonText = 'Pendiente';
        break;
      case 'Lista de espera':
        statusColor = Colors.blue;
        buttonText = 'Lista de espera';
        break;
      case 'Completada':
        statusColor = Colors.grey;
        buttonText = 'Completada';
        break;
      default:
        statusColor = Colors.grey;
        buttonText = campaign.status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.volunteer_activism,
                  color: statusColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF253A6B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign.date,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recuerda que puedes cancelar hasta 24 horas antes del evento.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/detalle',
                      arguments: campaign,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Ver detalles'),
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showCancelDialog(context, campaign);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar inscripción'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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
                    backgroundColor: Colors.green,
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
