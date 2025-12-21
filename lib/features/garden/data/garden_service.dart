import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/home_provider.dart';
import 'models/garden_bed_model.dart';

class GardenService {
  final FirebaseFirestore _firestore;

  GardenService(this._firestore);

  // Collection reference: homes/{homeId}/garden/{bedId}
  CollectionReference<Map<String, dynamic>> _getGardenCollection(String homeId) {
    return _firestore
        .collection('homes')
        .doc(homeId)
        .collection('garden');
  }

  Stream<List<GardenBed>> watchGardenBeds(String homeId) {
    return _getGardenCollection(homeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GardenBed.fromFirestore(doc))
            .toList());
  }

  Future<void> addBed(GardenBed bed) async {
    await _getGardenCollection(bed.homeId).doc(bed.id).set(bed.toFirestore());
  }

  Future<void> updateBed(GardenBed bed) async {
    await _getGardenCollection(bed.homeId).doc(bed.id).update(bed.toFirestore());
  }

  Future<void> deleteBed(String homeId, String bedId) async {
    await _getGardenCollection(homeId).doc(bedId).delete();
  }
}

final gardenServiceProvider = Provider<GardenService>((ref) {
  return GardenService(FirebaseFirestore.instance);
});

final gardenBedsProvider = StreamProvider.autoDispose<List<GardenBed>>((ref) {
  final homeState = ref.watch(currentHomeProvider);
  
  return homeState.when(
    data: (home) {
      if (home == null) return Stream.value([]);
      final service = ref.watch(gardenServiceProvider);
      return service.watchGardenBeds(home.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
