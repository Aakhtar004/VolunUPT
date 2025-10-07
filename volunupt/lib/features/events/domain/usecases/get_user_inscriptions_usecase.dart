import '../entities/inscription_entity.dart';
import '../repositories/events_repository.dart';

class GetUserInscriptionsUsecase {
  final EventsRepository _repository;

  GetUserInscriptionsUsecase(this._repository);

  Future<List<InscriptionEntity>> call(String userId) async {
    return await _repository.getUserInscriptions(userId);
  }
}