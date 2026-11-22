import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/garden_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import 'bed_details_sheet.dart';

class GardenListTab extends ConsumerWidget {
  const GardenListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bedsAsync = ref.watch(gardenBedsProvider);

    return bedsAsync.when(
      data: (beds) {
        if (beds.isEmpty) {
          return const Center(child: Text('Ingen bede endnu. Skift til visuel visning for at oprette.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: beds.length,
          itemBuilder: (context, index) {
            final bed = beds[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    bed.icon ?? '🌱',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                title: Text(bed.name),
                subtitle: Text('${bed.crops.length} planter • ${bed.width.toInt()}x${bed.height.toInt()} cm'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => BedDetailsSheet(bed: bed),
                  );
                },
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
