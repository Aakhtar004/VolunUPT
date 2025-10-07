import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetUserProfileUsecase {
  final ProfileRepository _repository;

  GetUserProfileUsecase(this._repository);

  Future<UserProfileEntity?> call(String userId) async {
    return await _repository.getUserProfile(userId);
  }
}