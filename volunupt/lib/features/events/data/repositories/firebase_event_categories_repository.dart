import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/event_category_entity.dart';
import '../../domain/repositories/event_categories_repository.dart';

class FirebaseEventCategoriesRepository implements EventCategoriesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'event_categories';

  @override
  Future<List<EventCategoryEntity>> getCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => EventCategoryEntity.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<List<EventCategoryEntity>> getCategoriesStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventCategoryEntity.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  @override
  Future<EventCategoryEntity?> getCategoryById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      
      if (doc.exists) {
        return EventCategoryEntity.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createCategory(EventCategoryEntity category) async {
    await _firestore.collection(_collection).add(category.toMap());
  }

  @override
  Future<void> updateCategory(EventCategoryEntity category) async {
    await _firestore
        .collection(_collection)
        .doc(category.id)
        .update(category.toMap());
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}