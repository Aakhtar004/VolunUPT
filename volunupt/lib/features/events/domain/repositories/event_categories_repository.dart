import '../entities/event_category_entity.dart';

abstract class EventCategoriesRepository {
  Future<List<EventCategoryEntity>> getCategories();
  Stream<List<EventCategoryEntity>> getCategoriesStream();
  Future<EventCategoryEntity?> getCategoryById(String id);
  Future<void> createCategory(EventCategoryEntity category);
  Future<void> updateCategory(EventCategoryEntity category);
  Future<void> deleteCategory(String id);
}