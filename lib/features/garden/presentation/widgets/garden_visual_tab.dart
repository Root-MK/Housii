import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/home_provider.dart';
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
    final homeState = ref.watch(currentHomeProvider);

    return bedsAsync.when(
      data: (beds) {
        final settings = homeState.value?.gardenSettings ?? {};
        final gardenWidth = (settings['width'] as num?)?.toDouble() ?? 1000.0;
        final gardenHeight = (settings['height'] as num?)?.toDouble() ?? 1000.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            // Margin logic to ensure we don't lose the garden
            final marginX = constraints.maxWidth > 0 ? constraints.maxWidth * 0.9 : 500.0;
            final marginY = constraints.maxHeight > 0 ? constraints.maxHeight * 0.9 : 500.0;

            return InteractiveViewer(
              boundaryMargin: EdgeInsets.symmetric(
                horizontal: marginX,
                vertical: marginY,
              ),
              minScale: 0.1,
              maxScale: 4.0,
              constrained: false, // Infinite canvas
              child: SizedBox(
                width: gardenWidth,
                height: gardenHeight,
                child: Stack(
                  clipBehavior: Clip.none, // Allow dragging handles slightly outside if needed
                  children: [
                    // Grid Background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GardenGridPainter(
                          width: gardenWidth,
                          height: gardenHeight,
                        ),
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
