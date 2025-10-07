import '../entities/certificate_entity.dart';

abstract class CertificatesRepository {
  Future<List<CertificateEntity>> getUserCertificates(String userId);
  Future<CertificateEntity?> getCertificate(String userId, String certificateId);
  Future<void> createCertificate(String userId, CertificateEntity certificate);
  Future<void> deleteCertificate(String userId, String certificateId);
}