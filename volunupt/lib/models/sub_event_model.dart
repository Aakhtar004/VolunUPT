import 'package:cloud_firestore/cloud_firestore.dart';

class SubEventModel {
  final String subEventId;
  final String baseEventId;
  final String title;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final int maxVolunteers;
  final int registeredCount;
  final String qrCodeData;

  SubEventModel({
    required this.subEventId,
    required this.baseEventId,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.maxVolunteers,
    this.registeredCount = 0,
    required this.qrCodeData,
  });

  factory SubEventModel.fromSnapshot(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return SubEventModel(
      subEventId: snap.id,
      baseEventId: snapshot['baseEventId'],
      title: snapshot['title'],
      date: (snapshot['date'] as Timestamp).toDate(),
      startTime: (snapshot['startTime'] as Timestamp).toDate(),
      endTime: (snapshot['endTime'] as Timestamp).toDate(),
      location: snapshot['location'],
      maxVolunteers: snapshot['maxVolunteers'],
      registeredCount: snapshot['registeredCount'] ?? 0,
      qrCodeData: snapshot['qrCodeData'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baseEventId': baseEventId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'maxVolunteers': maxVolunteers,
      'registeredCount': registeredCount,
      'qrCodeData': qrCodeData,
    };
  }
}