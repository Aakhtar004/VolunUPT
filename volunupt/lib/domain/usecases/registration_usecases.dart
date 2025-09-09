import 'package:volunupt/domain/entities/registration.dart';
import 'package:volunupt/domain/repositories/registration_repository.dart';

class GetStudentRegistrationsUseCase {
  final RegistrationRepository repository;

  GetStudentRegistrationsUseCase(this.repository);

  Future<List<Registration>> execute(String studentId) {
    return repository.getStudentRegistrations(studentId);
  }
}

class IsStudentRegisteredInCampaignUseCase {
  final RegistrationRepository repository;

  IsStudentRegisteredInCampaignUseCase(this.repository);

  Future<bool> execute(String studentId, String campaignId) {
    return repository.isStudentRegisteredInCampaign(studentId, campaignId);
  }
}

class RegisterStudentInCampaignUseCase {
  final RegistrationRepository repository;

  RegisterStudentInCampaignUseCase(this.repository);

  Future<void> execute(String studentId, String campaignId) {
    return repository.registerStudentInCampaign(studentId, campaignId);
  }
}

class CancelRegistrationUseCase {
  final RegistrationRepository repository;

  CancelRegistrationUseCase(this.repository);

  Future<void> execute(String registrationId) {
    return repository.cancelRegistration(registrationId);
  }
}