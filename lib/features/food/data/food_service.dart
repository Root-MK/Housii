import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'models/meal_plan_model.dart';
import 'models/food_idea_model.dart';
import 'models/freezer_item_model.dart';
import 'models/food_emoji.dart';

/// Food Service Provider
final foodServiceProvider = Provider<FoodService>((ref) {
  return FoodService();
});

/// Service for managing food planning, ideas, and freezer items
class FoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ============ COLLECTION REFERENCES ============

  CollectionReference<Map<String, dynamic>> _mealPlansCollection(String homeId) {
    return _firestore.collection('homes').doc(homeId).collection('mealPlans');
  }

  CollectionReference<Map<String, dynamic>> _foodIdeasCollection(String homeId) {
    return _firestore.collection('homes').doc(homeId).collection('foodIdeas');
  }

  CollectionReference<Map<String, dynamic>> _freezerItemsCollection(String homeId) {
    return _firestore.collection('homes').doc(homeId).collection('freezerItems');
  }

  // ============ MEAL PLAN OPERATIONS ============

  /// Create a new meal plan entry
  Future<MealPlanModel> createMealPlan({
    required String homeId,
    required DateTime date,
    required String foodIdeaId,
    required String foodName,
    String? description,
    required FoodEmoji emoji,
    required String createdBy,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    
    final mealPlan = MealPlanModel(
      id: id,
      homeId: homeId,
      date: date,
      foodIdeaId: foodIdeaId,
      foodName: foodName,
      description: description,
      emoji: emoji,
      createdAt: now,
      createdBy: createdBy,
    );

    await _mealPlansCollection(homeId).doc(id).set(mealPlan.toFirestore());
    debugPrint('✅ Created meal plan: ${mealPlan.foodName} for ${mealPlan.date}');
    
    return mealPlan;
  }

  /// Delete a meal plan entry
  Future<void> deleteMealPlan(String homeId, String mealPlanId) async {
    await _mealPlansCollection(homeId).doc(mealPlanId).delete();
    debugPrint('🗑️ Deleted meal plan: $mealPlanId');
  }

  /// Watch meal plans for a date range (today + 7 days)
  Stream<List<MealPlanModel>> watchMealPlans(String homeId, DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    debugPrint('📡 Watching meal plans from $start to $end');

    return _mealPlansCollection(homeId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
          final plans = snapshot.docs.map((doc) => MealPlanModel.fromFirestore(doc)).toList();
          debugPrint('📦 Got ${plans.length} meal plans');
          return plans;
        });
  }

  /// Get meal plan for a specific date
  Future<MealPlanModel?> getMealPlanForDate(String homeId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));

    final snapshot = await _mealPlansCollection(homeId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateOnly))
        .where('date', isLessThan: Timestamp.fromDate(nextDay))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return MealPlanModel.fromFirestore(snapshot.docs.first);
  }

  // ============ FOOD IDEAS OPERATIONS ============

  /// Create a new food idea
  Future<FoodIdeaModel> createFoodIdea({
    required String homeId,
    required String name,
    String? description,
    required FoodEmoji emoji,
    required String createdBy,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    // Get current min position to place new item at top
    final snapshot = await _foodIdeasCollection(homeId)
        .orderBy('position')
        .limit(1)
        .get();
    
    final minPosition = snapshot.docs.isNotEmpty 
        ? (snapshot.docs.first.data()['position'] as int? ?? 0) - 1
        : 0;

    final foodIdea = FoodIdeaModel(
      id: id,
      homeId: homeId,
      name: name,
      description: description,
      emoji: emoji,
      createdAt: now,
      createdBy: createdBy,
      position: minPosition,
    );

    await _foodIdeasCollection(homeId).doc(id).set(foodIdea.toFirestore());
    debugPrint('✅ Created food idea: ${foodIdea.name}');

    return foodIdea;
  }

  /// Update a food idea
  Future<void> updateFoodIdea(FoodIdeaModel idea) async {
    await _foodIdeasCollection(idea.homeId).doc(idea.id).update(idea.toFirestore());
    debugPrint('✅ Updated food idea: ${idea.name}');
  }

  /// Delete a food idea
  Future<void> deleteFoodIdea(String homeId, String ideaId) async {
    await _foodIdeasCollection(homeId).doc(ideaId).delete();
    debugPrint('🗑️ Deleted food idea: $ideaId');
  }

  /// Mark food idea as planned (moves to bottom of list)
  Future<void> markFoodIdeaAsPlanned(String homeId, String ideaId) async {
    final now = DateTime.now();

    // Get current max position to move item to bottom
    final snapshot = await _foodIdeasCollection(homeId)
        .orderBy('position', descending: true)
        .limit(1)
        .get();
    
    final maxPosition = snapshot.docs.isNotEmpty 
        ? (snapshot.docs.first.data()['position'] as int? ?? 0) + 1
        : 1;

    await _foodIdeasCollection(homeId).doc(ideaId).update({
      'lastPlannedAt': Timestamp.fromDate(now),
      'position': maxPosition,
    });
    debugPrint('📍 Marked food idea as planned: $ideaId');
  }

  /// Watch all food ideas (ordered by position - new at top, eaten at bottom)
  Stream<List<FoodIdeaModel>> watchFoodIdeas(String homeId) {
    return _foodIdeasCollection(homeId)
        .orderBy('position')
        .snapshots()
        .map((snapshot) {
          final ideas = snapshot.docs.map((doc) => FoodIdeaModel.fromFirestore(doc)).toList();
          debugPrint('📦 Got ${ideas.length} food ideas');
          return ideas;
        });
  }

  /// Search food ideas by name (client-side fuzzy search)
  List<FoodIdeaModel> searchFoodIdeas(List<FoodIdeaModel> ideas, String query) {
    if (query.isEmpty) return ideas;
    
    final lowerQuery = query.toLowerCase();
    return ideas.where((idea) {
      final name = idea.name.toLowerCase();
      final desc = idea.description?.toLowerCase() ?? '';
      return name.contains(lowerQuery) || desc.contains(lowerQuery);
    }).toList();
  }

  // ============ FREEZER ITEMS OPERATIONS ============

  /// Create a new freezer item
  Future<FreezerItemModel> createFreezerItem({
    required String homeId,
    required String name,
    required double quantity,
    required QuantityUnit unit,
    required FoodEmoji emoji,
    required String addedBy,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final item = FreezerItemModel(
      id: id,
      homeId: homeId,
      name: name,
      quantity: quantity,
      unit: unit,
      emoji: emoji,
      addedAt: now,
      addedBy: addedBy,
      updatedAt: now,
    );

    await _freezerItemsCollection(homeId).doc(id).set(item.toFirestore());
    debugPrint('✅ Created freezer item: ${item.name}');

    return item;
  }

  /// Update a freezer item
  Future<void> updateFreezerItem(FreezerItemModel item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    await _freezerItemsCollection(item.homeId).doc(item.id).update(updated.toFirestore());
    debugPrint('✅ Updated freezer item: ${item.name}');
  }

  /// Add quantity to a freezer item
  Future<void> addQuantity(String homeId, String itemId, double amount) async {
    await _freezerItemsCollection(homeId).doc(itemId).update({
      'quantity': FieldValue.increment(amount),
      'updatedAt': Timestamp.now(),
    });
    debugPrint('➕ Added $amount to freezer item: $itemId');
  }

  /// Reduce quantity from a freezer item
  Future<void> reduceQuantity(String homeId, String itemId, double amount) async {
    // Get current quantity to ensure we don't go below 0
    final doc = await _freezerItemsCollection(homeId).doc(itemId).get();
    if (!doc.exists) return;

    final currentQuantity = (doc.data()!['quantity'] as num).toDouble();
    final newQuantity = (currentQuantity - amount).clamp(0.0, double.infinity);

    await _freezerItemsCollection(homeId).doc(itemId).update({
      'quantity': newQuantity,
      'updatedAt': Timestamp.now(),
    });
    debugPrint('➖ Reduced $amount from freezer item: $itemId (now: $newQuantity)');
  }

  /// Delete a freezer item
  Future<void> deleteFreezerItem(String homeId, String itemId) async {
    await _freezerItemsCollection(homeId).doc(itemId).delete();
    debugPrint('🗑️ Deleted freezer item: $itemId');
  }

  /// Watch all freezer items (ordered by addedAt - oldest first, empty items at bottom)
  Stream<List<FreezerItemModel>> watchFreezerItems(String homeId) {
    return _freezerItemsCollection(homeId)
        .orderBy('addedAt')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map((doc) => FreezerItemModel.fromFirestore(doc)).toList();
          
          // Sort: non-empty items by addedAt (oldest first), then empty items at bottom
          items.sort((a, b) {
            if (a.isEmpty && !b.isEmpty) return 1;
            if (!a.isEmpty && b.isEmpty) return -1;
            return a.addedAt.compareTo(b.addedAt);
          });
          
          debugPrint('📦 Got ${items.length} freezer items');
          return items;
        });
  }
}
