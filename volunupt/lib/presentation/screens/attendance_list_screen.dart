import 'package:flutter/material.dart';
import 'package:volunupt/domain/entities/campaign.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  // Lista hardcodeada de estudiantes inscritos
  final List<Map<String, dynamic>> _students = [
    {
      'id': '1',
      'name': 'Carlos Mendoza',
      'career': 'Ingeniería de Sistemas',
      'isPresent': false,
    },
    {
      'id': '2',
      'name': 'Sofia Ramirez',
      'career': 'Ingeniería de Sistemas',
      'isPresent': false,
    },
    {
      'id': '3',
      'name': 'Diego Vargas',
      'career': 'Ingeniería de Sistemas',
      'isPresent': false,
    },
    {
      'id': '4',
      'name': 'Isabella Torres',
      'career': 'Ingeniería de Sistemas',
      'isPresent': false,
    },
    {
      'id': '5',
      'name': 'Andrés Silva',
      'career': 'Ingeniería de Sistemas',
      'isPresent': false,
    },
  ];

  int get presentCount => _students.where((s) => s['isPresent'] == true).length;

  @override
  Widget build(BuildContext context) {
    final Campaign campaign =
        ModalRoute.of(context)!.settings.arguments as Campaign;

    return Scaffold(
      backgroundColor: const Color(0xFFD3DBE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF253A6B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Asistencia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.pushNamed(context, '/qr_attendance');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header de información
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF253A6B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Asistentes ($presentCount)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF253A6B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Seleccionar todos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de estudiantes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return _buildStudentCard(student, index);
              },
            ),
          ),
          // Botones de acción
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showFinishEventDialog(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF253A6B),
                      side: const BorderSide(color: Color(0xFF253A6B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Finalizar evento'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showRegisterAttendanceDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Registrar asistencia'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF253A6B),
            child: Text(
              student['name'][0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Información del estudiante
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF253A6B),
                  ),
                ),
                Text(
                  student['career'],
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Checkbox de asistencia
          Checkbox(
            value: student['isPresent'],
            onChanged: (bool? value) {
              setState(() {
                _students[index]['isPresent'] = value ?? false;
              });
            },
            activeColor: const Color(0xFF253A6B),
          ),
        ],
      ),
    );
  }

  void _showFinishEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Finalizar Evento'),
          content: const Text(
            '¿Estás seguro de que deseas finalizar este evento?',
          ),
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
                    content: Text('Evento finalizado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Finalizar'),
            ),
          ],
        );
      },
    );
  }

  void _showRegisterAttendanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registrar Asistencia'),
          content: Text(
            'Se registrará la asistencia de $presentCount estudiantes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Asistencia registrada para $presentCount estudiantes',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );
  }
}
