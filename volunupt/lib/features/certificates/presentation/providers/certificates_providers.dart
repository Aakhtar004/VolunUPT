import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_certificates_repository.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/repositories/certificates_repository.dart';
import '../../domain/usecases/get_user_certificates_usecase.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final certificatesRepositoryProvider = Provider<CertificatesRepository>((ref) {
  return FirebaseCertificatesRepository();
});

final getUserCertificatesUsecaseProvider = Provider<GetUserCertificatesUseCase>(
  (ref) {
    return GetUserCertificatesUseCase(ref.read(certificatesRepositoryProvider));
  },
);

final userCertificatesProvider = FutureProvider<List<CertificateEntity>>((
  ref,
) async {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return [];
      final usecase = ref.read(getUserCertificatesUsecaseProvider);
      return await usecase(user.id);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
