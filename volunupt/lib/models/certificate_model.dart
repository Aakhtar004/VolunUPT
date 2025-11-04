import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateModel {
  final String certificateId;
  final String userId;
  final String baseEventId;
  final String pdfUrl;
  final DateTime dateIssued;
  final double hoursCompleted;

  CertificateModel({
    required this.certificateId,
    required this.userId,
    required this.baseEventId,
    required this.pdfUrl,
    required this.dateIssued,
    required this.hoursCompleted,
  });

  factory CertificateModel.fromSnapshot(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return CertificateModel(
      certificateId: snap.id,
      userId: snapshot['userId'],
      baseEventId: snapshot['baseEventId'],
      pdfUrl: snapshot['pdfUrl'],
      dateIssued: (snapshot['dateIssued'] as Timestamp).toDate(),
      hoursCompleted: (snapshot['hoursCompleted'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'baseEventId': baseEventId,
      'pdfUrl': pdfUrl,
      'dateIssued': Timestamp.fromDate(dateIssued),
      'hoursCompleted': hoursCompleted,
    };
  }
}