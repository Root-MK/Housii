import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_model.dart';
import '../services/home_service.dart';
import 'auth_provider.dart';

/// Current home provider - streams home model based on user's currentHomeId
final currentHomeProvider = StreamProvider<HomeModel?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final homeService = ref.watch(homeServiceProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null || user.currentHomeId == null) {
        return Stream.value(null);
      }
      return homeService.homeStream(user.currentHomeId!);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Home members provider
final homeMembersProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, homeId) async {
  final homeService = ref.watch(homeServiceProvider);
  return homeService.getHomeMembers(homeId);
});

/// Home actions provider
final homeActionsProvider = Provider<HomeActions>((ref) {
  final homeService = ref.watch(homeServiceProvider);
  return HomeActions(homeService);
});

/// Home actions class
class HomeActions {
  final HomeService _homeService;
  
  HomeActions(this._homeService);

  Future<HomeModel> createHome({
    required String name,
    required String ownerId,
  }) async {
    return _homeService.createHome(name: name, ownerId: ownerId);
  }

  Future<HomeModel?> joinHomeByCode({
    required String joinCode,
    required String userId,
  }) async {
    return _homeService.joinHomeByCode(joinCode: joinCode, userId: userId);
  }

  Future<void> leaveHome({
    required String homeId,
    required String userId,
  }) async {
    await _homeService.leaveHome(homeId: homeId, userId: userId);
  }

  Future<void> deleteHome({
    required String homeId,
    required String ownerId,
  }) async {
    await _homeService.deleteHome(homeId: homeId, ownerId: ownerId);
  }
}
