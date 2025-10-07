import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_event_categories_repository.dart';
import '../../domain/entities/event_category_entity.dart';
import '../../domain/repositories/event_categories_repository.dart';

final eventCategoriesRepositoryProvider = Provider<EventCategoriesRepository>((ref) {
  return FirebaseEventCategoriesRepository();
});

final eventCategoriesProvider = FutureProvider<List<EventCategoryEntity>>((ref) async {
  final repository = ref.read(eventCategoriesRepositoryProvider);
  return repository.getCategories();
});

final eventCategoriesStreamProvider = StreamProvider<List<EventCategoryEntity>>((ref) {
  final repository = ref.read(eventCategoriesRepositoryProvider);
  return repository.getCategoriesStream();
});