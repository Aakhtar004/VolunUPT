import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class EventModel {
  final String eventId;
  final String title;
  final String description;
  final String imageUrl;
  final String coordinatorId;
  final EventStatus status;
  final double totalHoursForCertificate;
  final SessionType sessionType;

  EventModel({
    required this.eventId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.coordinatorId,
    required this.status,
    required this.totalHoursForCertificate,
    required this.sessionType,
  });

  factory EventModel.fromSnapshot(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return EventModel(
      eventId: snap.id,
      title: snapshot['title'],
      description: snapshot['description'],
      imageUrl: snapshot['imageUrl'],
      coordinatorId: snapshot['coordinatorId'],
      status: EventStatus.values.firstWhere(
        (e) => e.toString() == 'EventStatus.${snapshot['status']}',
        orElse: () => EventStatus.borrador,
      ),
      totalHoursForCertificate: (snapshot['totalHoursForCertificate'] ?? 0.0).toDouble(),
      sessionType: SessionType.values.firstWhere(
        (e) => e.toString() == 'SessionType.${snapshot['sessionType']}',
        orElse: () => SessionType.multiple,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'coordinatorId': coordinatorId,
      'status': status.toString().split('.').last,
      'totalHoursForCertificate': totalHoursForCertificate,
      'sessionType': sessionType.toString().split('.').last,
    };
  }
}