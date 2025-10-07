import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateUserProfileUsecase {
  final ProfileRepository _repository;

  UpdateUserProfileUsecase(this._repository);

  Future<void> call(UserProfileEntity profile) async {
    final updatedProfile = profile.copyWith(
      updatedAt: DateTime.now(),
    );
    await _repository.updateUserProfile(updatedProfile);
  }
}