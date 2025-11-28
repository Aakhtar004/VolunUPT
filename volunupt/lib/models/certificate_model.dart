import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateModel {
  final String certificateId;
  final String userId;
  final String baseEventId;
  final String eventTitle;
  final String pdfUrl;
  final DateTime dateIssued;
  final double hoursCompleted;
  final String validationCode;

  // Alias para compatibilidad si se usa totalHours
  double get totalHours => hoursCompleted;
  // Alias para compatibilidad si se usa issueDate
  DateTime get issueDate => dateIssued;

  CertificateModel({
    required this.certificateId,
    required this.userId,
    required this.baseEventId,
    required this.eventTitle,
    required this.pdfUrl,
    required this.dateIssued,
    required this.hoursCompleted,
    required this.validationCode,
  });

  factory CertificateModel.fromSnapshot(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return CertificateModel(
      certificateId: snap.id,
      userId: snapshot['userId'] ?? '',
      baseEventId: snapshot['baseEventId'] ?? '',
      eventTitle: snapshot['eventTitle'] ?? 'Evento',
      pdfUrl: snapshot['pdfUrl'] ?? '',
      dateIssued: (snapshot['dateIssued'] as Timestamp).toDate(),
      hoursCompleted: (snapshot['hoursCompleted'] ?? 0.0).toDouble(),
      validationCode: snapshot['validationCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'baseEventId': baseEventId,
      'eventTitle': eventTitle,
      'pdfUrl': pdfUrl,
      'dateIssued': Timestamp.fromDate(dateIssued),
      'hoursCompleted': hoursCompleted,
      'validationCode': validationCode,
    };
  }
}