import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/garden_service.dart';
import '../../data/models/garden_bed_model.dart';
import 'garden_bed_widget.dart';
import 'garden_grid_painter.dart';

class GardenVisualTab extends ConsumerWidget {
  final bool isEditMode;

  const GardenVisualTab({
    super.key,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bedsAsync = ref.watch(gardenBedsProvider);

    return bedsAsync.when(
      data: (beds) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Using InteractiveViewer for pan/zoom
            // The canvas size is large (e.g. 50m x 50m = 5000x5000 units)
            // Center the view initially?
            return InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.1,
              maxScale: 4.0,
              constrained: false, // Infinite canvas
              child: SizedBox(
                width: 5000,
                height: 5000,
                child: Stack(
                  children: [
                    // Grid Background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GardenGridPainter(),
                      ),
                    ),
                    
                    // Beds
                    ...beds.map((bed) => GardenBedWidget(
                      key: ValueKey(bed.id),
                      bed: bed,
                      isEditMode: isEditMode,
                    )),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Fejl: $err')),
    );
  }
}
