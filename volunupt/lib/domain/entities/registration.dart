import 'package:equatable/equatable.dart';

class Registration extends Equatable {
  final String id;
  final String campaignId;
  final String studentId;
  final DateTime registrationDate;
  final String status; // 'Confirmado', 'Pendiente', 'Cancelado', 'Lista de espera'

  const Registration({
    required this.id,
    required this.campaignId,
    required this.studentId,
    required this.registrationDate,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        campaignId,
        studentId,
        registrationDate,
        status,
      ];
}