import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/garden_service.dart';
import '../../data/models/garden_bed_model.dart';
import '../../data/models/garden_crop_model.dart';

part 'garden_providers.g.dart';

@riverpod
class GardenController extends _$GardenController {
  @override
  FutureOr<void> build() {
    // No initial state needed beyond what's handled by other providers, 
    // but this controller handles user actions.
  }

  Future<void> createBed({
    required String name,
    required String homeId,
    double x = 0,
    double y = 0,
    double width = 100,
    double height = 100,
  }) async {
    final service = ref.read(gardenServiceProvider);
    final bed = GardenBed.create(
      name: name,
      homeId: homeId,
      x: x,
      y: y,
      width: width,
      height: height,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => service.addBed(bed));
  }

  Future<void> updateBed(GardenBed bed) async {
    final service = ref.read(gardenServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => service.updateBed(bed));
  }

  Future<void> deleteBed(String homeId, String bedId) async {
    final service = ref.read(gardenServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => service.deleteBed(homeId, bedId));
  }
  
  Future<void> addCrop(GardenBed bed, GardenCrop crop) async {
    final updatedCrops = [...bed.crops, crop];
    final updatedBed = bed.copyWith(crops: updatedCrops);
    await updateBed(updatedBed);
  }

  Future<void> removeCrop(GardenBed bed, String cropId) async {
    final updatedCrops = bed.crops.where((c) => c.id != cropId).toList();
    final updatedBed = bed.copyWith(crops: updatedCrops);
    await updateBed(updatedBed);
  }

  Future<void> updateCrop(GardenBed bed, GardenCrop crop) async {
    final updatedCrops = bed.crops.map((c) => c.id == crop.id ? crop : c).toList();
    final updatedBed = bed.copyWith(crops: updatedCrops);
    await updateBed(updatedBed);
  }
}
