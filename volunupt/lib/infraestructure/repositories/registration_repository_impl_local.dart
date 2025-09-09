import 'package:volunupt/domain/entities/registration.dart';
import 'package:volunupt/domain/repositories/registration_repository.dart';
import 'package:volunupt/infraestructure/datasources/local_data_service.dart';

class RegistrationRepositoryImplLocal implements RegistrationRepository {
  @override
  Future<List<Registration>> getStudentRegistrations(String studentId) async {
    // En una implementación real, esto se conectaría a una base de datos
    // Por ahora, simulamos con el servicio local
    return Future.value(LocalDataService.registrations
        .where((r) => r.studentId == studentId)
        .toList());
  }

  @override
  Future<bool> isStudentRegisteredInCampaign(
      String studentId, String campaignId) async {
    // Utilizamos el método existente en LocalDataService
    return Future.value(
        LocalDataService.isStudentRegisteredInCampaign(studentId, campaignId));
  }

  @override
  Future<void> registerStudentInCampaign(
      String studentId, String campaignId) async {
    // En una implementación real, esto crearía un nuevo registro en la base de datos
    // Por ahora, solo simulamos la operación
    // Nota: Esta implementación es solo para demostración y no modifica realmente los datos
    return Future.value();
  }

  @override
  Future<void> cancelRegistration(String registrationId) async {
    // En una implementación real, esto actualizaría el estado en la base de datos
    // Por ahora, solo simulamos la operación
    // Nota: Esta implementación es solo para demostración y no modifica realmente los datos
    return Future.value();
  }
}