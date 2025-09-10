import 'package:flutter/material.dart';

class CertificadosScreen extends StatelessWidget {
  const CertificadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3DBE7),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Column(
              children: [
                Text(
                  'Certificados',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF253A6B),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Descarga tus certificados de participación',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Lista de certificados
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 2, // Certificados hardcodeados
              itemBuilder: (context, index) {
                return _buildCertificadoCard(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificadoCard(BuildContext context, int index) {
    final certificados = [
      {
        'title': 'Voluntariado en Hospital Infantil',
        'date': '05 de agosto 2024',
        'hours': '5 horas RSU',
        'status': 'Disponible',
      },
      {
        'title': 'Campaña de Reciclaje de Papel',
        'date': '20 de julio 2024',
        'hours': '4 horas RSU',
        'status': 'Disponible',
      },
    ];

    final cert = certificados[index];

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
              const Icon(Icons.verified, color: Colors.green, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF253A6B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cert['date']!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      cert['hours']!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Certificado descargado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Descargar Certificado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF253A6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
