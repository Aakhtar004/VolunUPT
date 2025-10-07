import '../entities/user_profile_entity.dart';

abstract class ProfileRepository {
  Future<UserProfileEntity?> getUserProfile(String userId);
  Future<void> updateUserProfile(UserProfileEntity profile);
  Future<void> updateProfilePhoto(String userId, String photoPath);
  Future<void> deleteProfilePhoto(String userId);
  Future<void> updateBiometricSettings(String userId, bool enabled);
  Future<void> updateNotificationSettings(String userId, bool enabled);
  Stream<UserProfileEntity?> watchUserProfile(String userId);
}