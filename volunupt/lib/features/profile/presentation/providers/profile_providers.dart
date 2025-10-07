import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/update_user_profile_usecase.dart';
import '../../data/repositories/firebase_profile_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirebaseProfileRepository(
    ref.read(firestoreProvider),
    ref.read(firebaseStorageProvider),
  );
});

final getUserProfileUsecaseProvider = Provider<GetUserProfileUsecase>((ref) {
  return GetUserProfileUsecase(ref.read(profileRepositoryProvider));
});

final updateUserProfileUsecaseProvider = Provider<UpdateUserProfileUsecase>((ref) {
  return UpdateUserProfileUsecase(ref.read(profileRepositoryProvider));
});

final userProfileProvider = FutureProvider<UserProfileEntity?>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return null;
  
  final usecase = ref.read(getUserProfileUsecaseProvider);
  return await usecase(currentUser.id);
});

final userProfileStreamProvider = StreamProvider<UserProfileEntity?>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value(null);
  
  final repository = ref.read(profileRepositoryProvider);
  return repository.watchUserProfile(currentUser.id);
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfileEntity?>> {
  final ProfileRepository _repository;
  final UpdateUserProfileUsecase _updateUsecase;

  ProfileNotifier(this._repository, this._updateUsecase) : super(const AsyncValue.loading());

  Future<void> loadProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getUserProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProfile(UserProfileEntity profile) async {
    state = const AsyncValue.loading();
    try {
      await _updateUsecase(profile);
      state = AsyncValue.data(profile);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProfilePhoto(String userId, String photoPath) async {
    try {
      await _repository.updateProfilePhoto(userId, photoPath);
      await loadProfile(userId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteProfilePhoto(String userId) async {
    try {
      await _repository.deleteProfilePhoto(userId);
      await loadProfile(userId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateBiometricSettings(String userId, bool enabled) async {
    try {
      await _repository.updateBiometricSettings(userId, enabled);
      await loadProfile(userId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateNotificationSettings(String userId, bool enabled) async {
    try {
      await _repository.updateNotificationSettings(userId, enabled);
      await loadProfile(userId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfileEntity?>>((ref) {
  return ProfileNotifier(
    ref.read(profileRepositoryProvider),
    ref.read(updateUserProfileUsecaseProvider),
  );
});