import 'package:volunupt/domain/entities/campaign.dart';

class LocalDataService {
  // Datos hardcodeados de campañas
  static const List<Campaign> campaigns = [
    Campaign(
      id: '1',
      title: 'Reforestación en el Parque Ecológico',
      description:
          'Participa en nuestra jornada de reforestación para contribuir a la conservación del medio ambiente. Plantaremos árboles nativos y aprenderemos sobre la importancia de los ecosistemas locales.',
      date: '15 de julio 2024',
      location: 'Parque Ecológico',
      imageAsset: 'assets/images/reforestacion.png',
      status: 'Confirmado',
      coordinatorName: 'Carlos Rodríguez',
      coordinatorEmail: 'carlos.rodriguez@upt.edu.pe',
      availableSpots: 15,
      totalSpots: 20,
      requirements: [
        'Estudiantes de la EPIS',
        'Disponibilidad el sábado 15 de julio',
        'Ropa cómoda y guantes',
      ],
      rsuHours: 8,
    ),
    Campaign(
      id: '2',
      title: 'Taller de Robótica para Niños',
      description:
          'Enseña conceptos básicos de programación y robótica a niños de 8-12 años en un ambiente divertido y educativo.',
      date: '22 de julio 2024',
      location: 'Laboratorio de Robótica',
      imageAsset: 'assets/images/robotica.png',
      status: 'Pendiente',
      coordinatorName: 'Ana García',
      coordinatorEmail: 'ana.garcia@upt.edu.pe',
      availableSpots: 8,
      totalSpots: 12,
      requirements: [
        'Estudiantes de Ingeniería',
        'Conocimientos básicos de programación',
        'Paciencia para trabajar con niños',
      ],
      rsuHours: 6,
    ),
    Campaign(
      id: '3',
      title: 'Maratón de Programación',
      description:
          'Organiza y participa en un evento de programación competitiva para estudiantes universitarios.',
      date: '30 de julio 2024',
      location: 'Aula de Cómputo',
      imageAsset: 'assets/images/programacion.png',
      status: 'Lista de espera',
      coordinatorName: 'Miguel Torres',
      coordinatorEmail: 'miguel.torres@upt.edu.pe',
      availableSpots: 0,
      totalSpots: 25,
      requirements: [
        'Estudiantes de todas las carreras',
        'Laptop personal',
        'Conocimientos de algoritmos',
      ],
      rsuHours: 12,
    ),
    Campaign(
      id: '4',
      title: 'Voluntariado en Hospital Infantil',
      description:
          'Acompaña y brinda apoyo emocional a niños hospitalizados a través de actividades recreativas.',
      date: '05 de agosto 2024',
      location: 'Hospital Infantil',
      imageAsset: 'assets/images/hospital.png',
      status: 'Completada',
      coordinatorName: 'Laura Mendoza',
      coordinatorEmail: 'laura.mendoza@upt.edu.pe',
      availableSpots: 0,
      totalSpots: 15,
      requirements: [
        'Estudiantes de cualquier carrera',
        'Certificado médico actualizado',
        'Sensibilidad para trabajar con niños enfermos',
      ],
      rsuHours: 5,
    ),
  ];

  // Obtener campañas para alumno
  static List<Campaign> getCampaignsForStudent() {
    return campaigns;
  }

  // Obtener campaña específica para ingeniero (curso)
  static Campaign getCourseForEngineer() {
    return campaigns.first; // Solo una campaña/curso para el ingeniero
  }

  // Obtener inscripciones del alumno1
  static List<Campaign> getStudentRegistrations() {
    return campaigns
        .where((c) => c.status == 'Confirmado' || c.status == 'Pendiente')
        .toList();
  }
}
