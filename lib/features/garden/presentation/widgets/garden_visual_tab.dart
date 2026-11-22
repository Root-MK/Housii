import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/garden_service.dart';
import '../../data/models/garden_bed_model.dart';
import 'garden_bed_widget.dart';
import 'garden_grid_painter.dart';
import 'bed_form_sheet.dart';

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

        // Empty State
        if (beds.isEmpty) {
          return _buildEmptyState(context);
        }

        return Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final marginX = constraints.maxWidth > 0 ? constraints.maxWidth * 0.9 : 500.0;
                final marginY = constraints.maxHeight > 0 ? constraints.maxHeight * 0.9 : 500.0;

                return InteractiveViewer(
                  boundaryMargin: EdgeInsets.symmetric(
                    horizontal: marginX,
                    vertical: marginY,
                  ),
                  minScale: 0.1,
                  maxScale: 4.0,
                  constrained: false,
                  child: SizedBox(
                    width: gardenWidth,
                    height: gardenHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GardenGridPainter(
                              width: gardenWidth,
                              height: gardenHeight,
                            ),
                          ),
                        ),
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
            ),
            // Inline Add Bed button when in edit mode
            if (isEditMode)
              Positioned(
                bottom: AppSpacing.lg,
                right: AppSpacing.lg,
                child: FloatingActionButton(
                  heroTag: 'addBedInline',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const BedFormSheet(),
                    );
                  },
                  tooltip: 'Tilføj bed',
                  backgroundColor: AppColors.primaryPurple,
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Fejl: $err')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 80,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Din have er tom!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tryk på + knappen for at tilføje dit første bed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Arrow pointing down
            Icon(
              Icons.arrow_downward,
              size: 48,
              color: AppColors.primaryPurple.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

