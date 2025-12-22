import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/home_model.dart';

/// Home Service Provider
final homeServiceProvider = Provider<HomeService>((ref) {
  return HomeService();
});

/// Home Service for managing homes
class HomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Characters for join code (avoiding confusing chars like 0/O, 1/l/I)
  static const String _joinCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Generate a 16-character join code
  String _generateJoinCode() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => _joinCodeChars[random.nextInt(_joinCodeChars.length)],
    ).join();
  }

  /// Create a new home
  Future<HomeModel> createHome({
    required String name,
    required String ownerId,
  }) async {
    final homeId = _uuid.v4();
    final joinCode = _generateJoinCode();
    final now = DateTime.now();

    final home = HomeModel(
      id: homeId,
      name: name,
      joinCode: joinCode,
      ownerId: ownerId,
      memberIds: [ownerId],
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.collection('homes').doc(homeId).set(home.toFirestore());

    // Update user's currentHomeId
    await _firestore.collection('users').doc(ownerId).update({
      'currentHomeId': homeId,
      'updatedAt': Timestamp.now(),
    });

    return home;
  }

  /// Join an existing home by join code
  Future<HomeModel?> joinHomeByCode({
    required String joinCode,
    required String userId,
  }) async {
    // Remove dashes if present
    final cleanCode = joinCode.replaceAll('-', '').toUpperCase();

    // Find home with this join code
    final query = await _firestore
        .collection('homes')
        .where('joinCode', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null; // Home not found
    }

    final homeDoc = query.docs.first;
    final home = HomeModel.fromFirestore(homeDoc);

    // Check if already a member
    if (home.memberIds.contains(userId)) {
      return home;
    }

    // Add user to members
    await _firestore.collection('homes').doc(home.id).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'updatedAt': Timestamp.now(),
    });

    // Update user's currentHomeId
    await _firestore.collection('users').doc(userId).update({
      'currentHomeId': home.id,
      'updatedAt': Timestamp.now(),
    });

    return home.copyWith(
      memberIds: [...home.memberIds, userId],
    );
  }

  /// Get home by ID
  Future<HomeModel?> getHome(String homeId) async {
    final doc = await _firestore.collection('homes').doc(homeId).get();
    if (!doc.exists) return null;
    return HomeModel.fromFirestore(doc);
  }

  /// Update home data
  Future<void> updateHome(HomeModel home) async {
    await _firestore.collection('homes').doc(home.id).update({
      ...home.toFirestore(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Stream of home changes
  Stream<HomeModel?> homeStream(String homeId) {
    return _firestore
        .collection('homes')
        .doc(homeId)
        .snapshots()
        .map((doc) => doc.exists ? HomeModel.fromFirestore(doc) : null);
  }

  /// Leave a home
  Future<void> leaveHome({
    required String homeId,
    required String userId,
  }) async {
    final home = await getHome(homeId);
    if (home == null) return;

    // Can't leave if you're the owner
    if (home.ownerId == userId) {
      throw Exception('Owner cannot leave the home. Delete it instead.');
    }

    // Remove user from members
    await _firestore.collection('homes').doc(homeId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'updatedAt': Timestamp.now(),
    });

    // Clear user's currentHomeId
    await _firestore.collection('users').doc(userId).update({
      'currentHomeId': null,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a home (only owner can do this)
  Future<void> deleteHome({
    required String homeId,
    required String ownerId,
  }) async {
    final home = await getHome(homeId);
    if (home == null) return;

    // Verify ownership
    if (home.ownerId != ownerId) {
      throw Exception('Only the owner can delete the home.');
    }

    // Clear currentHomeId for all members
    final batch = _firestore.batch();
    for (final memberId in home.memberIds) {
      batch.update(_firestore.collection('users').doc(memberId), {
        'currentHomeId': null,
        'updatedAt': Timestamp.now(),
      });
    }
    await batch.commit();

    // Delete the home
    await _firestore.collection('homes').doc(homeId).delete();
  }

  /// Get all members of a home as user models
  Future<List<Map<String, dynamic>>> getHomeMembers(String homeId) async {
    final home = await getHome(homeId);
    if (home == null) return [];

    final members = <Map<String, dynamic>>[];
    for (final memberId in home.memberIds) {
      final userDoc = await _firestore.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        members.add({
          'id': memberId,
          'displayName': data['displayName'] ?? '',
          'email': data['email'] ?? '',
          'photoUrl': data['photoUrl'],
          'isOwner': memberId == home.ownerId,
        });
      }
    }
    return members;
  }
}
