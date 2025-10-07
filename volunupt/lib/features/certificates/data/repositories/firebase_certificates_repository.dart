import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/repositories/certificates_repository.dart';

class FirebaseCertificatesRepository implements CertificatesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<CertificateEntity>> getUserCertificates(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('certificates')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CertificateEntity(
          id: doc.id,
          eventId: data['eventId'] ?? '',
          eventName: data['eventName'] ?? '',
          issuedAt: (data['issued_at'] as Timestamp).toDate(),
          fileUrl: data['file_url'] ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener certificados: $e');
    }
  }

  @override
  Future<CertificateEntity?> getCertificate(String userId, String certificateId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('certificates')
          .doc(certificateId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return CertificateEntity(
        id: doc.id,
        eventId: data['eventId'] ?? '',
        eventName: data['eventName'] ?? '',
        issuedAt: (data['issued_at'] as Timestamp).toDate(),
        fileUrl: data['file_url'] ?? '',
      );
    } catch (e) {
      throw Exception('Error al obtener certificado: $e');
    }
  }

  @override
  Future<void> createCertificate(String userId, CertificateEntity certificate) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('certificates')
          .doc(certificate.id)
          .set({
        'eventId': certificate.eventId,
        'eventName': certificate.eventName,
        'issued_at': Timestamp.fromDate(certificate.issuedAt),
        'file_url': certificate.fileUrl,
      });
    } catch (e) {
      throw Exception('Error al crear certificado: $e');
    }
  }

  @override
  Future<void> deleteCertificate(String userId, String certificateId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('certificates')
          .doc(certificateId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar certificado: $e');
    }
  }
}