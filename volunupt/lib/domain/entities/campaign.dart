import 'package:equatable/equatable.dart';

class Campaign extends Equatable {
  final String id;
  final String title;
  final String description;
  final String date;
  final String location;
  final String imageAsset;
  final String status;
  final String coordinatorName;
  final String coordinatorEmail;
  final int availableSpots;
  final int totalSpots;
  final List<String> requirements;
  final int rsuHours;

  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.imageAsset,
    required this.status,
    required this.coordinatorName,
    required this.coordinatorEmail,
    required this.availableSpots,
    required this.totalSpots,
    required this.requirements,
    required this.rsuHours,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    date,
    location,
    imageAsset,
    status,
    coordinatorName,
    coordinatorEmail,
    availableSpots,
    totalSpots,
    requirements,
    rsuHours,
  ];
}
