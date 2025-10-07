import '../entities/certificate_entity.dart';
import '../repositories/certificates_repository.dart';

class GetUserCertificatesUseCase {
  final CertificatesRepository repository;

  const GetUserCertificatesUseCase(this.repository);

  Future<List<CertificateEntity>> call(String userId) {
    return repository.getUserCertificates(userId);
  }
}