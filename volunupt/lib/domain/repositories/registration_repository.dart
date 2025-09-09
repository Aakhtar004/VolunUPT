import 'package:volunupt/domain/entities/registration.dart';

abstract class RegistrationRepository {
  Future<List<Registration>> getStudentRegistrations(String studentId);
  Future<bool> isStudentRegisteredInCampaign(String studentId, String campaignId);
  Future<void> registerStudentInCampaign(String studentId, String campaignId);
  Future<void> cancelRegistration(String registrationId);
}