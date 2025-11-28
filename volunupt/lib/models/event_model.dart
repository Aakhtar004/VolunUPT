import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class EventModel {
  final String eventId;
  final String title;
  final String description;
  final String imageUrl;
  final String coordinatorId;
  final EventStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final SessionType sessionType;

  final int maxVolunteers;
  final int registeredCount;

  EventModel({
    required this.eventId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.coordinatorId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.sessionType,
    this.maxVolunteers = 0,
    this.registeredCount = 0,
  });

  factory EventModel.fromSnapshot(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return EventModel(
      eventId: snap.id,
      title: snapshot['title'] ?? '',
      description: snapshot['description'] ?? '',
      imageUrl: snapshot['imageUrl'] ?? '',
      coordinatorId: snapshot['coordinatorId'] ?? '',
      status: EventStatus.values.firstWhere(
        (e) => e.toString() == 'EventStatus.${snapshot['status']}',
        orElse: () => EventStatus.borrador),
      startDate: (snapshot['startDate'] as Timestamp).toDate(),
      endDate: (snapshot['endDate'] as Timestamp).toDate(),
      sessionType: SessionType.values.firstWhere(
        (e) => e.toString() == 'SessionType.${snapshot['sessionType']}',
        orElse: () => SessionType.unica),
      maxVolunteers: snapshot['maxVolunteers'] ?? 0,
      registeredCount: snapshot['registeredCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'coordinatorId': coordinatorId,
      'status': status.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'sessionType': sessionType.toString().split('.').last,
      'maxVolunteers': maxVolunteers,
      'registeredCount': registeredCount,
    };
  }

  /// Calcula si el evento está en curso basado en las fechas
  bool get isInProgress {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Calcula si el evento ha finalizado
  bool get isCompleted {
    final now = DateTime.now();
    return now.isAfter(endDate);
  }

  /// Calcula si el evento aún no ha comenzado
  bool get isPending {
    final now = DateTime.now();
    return now.isBefore(startDate);
  }
}