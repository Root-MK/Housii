import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/garden_service.dart';
import '../../data/models/garden_harvest_model.dart';

class HarvestLogTab extends ConsumerWidget {
  const HarvestLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final harvestsAsync = ref.watch(harvestsProvider);

    return harvestsAsync.when(
      data: (harvests) {
        if (harvests.isEmpty) {
          return _buildEmptyState(context);
        }

        // Calculate stats
        final totalWeight = harvests.fold<double>(0, (sum, h) {
          if (h.unit == 'kg') return sum + (h.weight ?? 0) * 1000;
          return sum + (h.weight ?? 0);
        });

        final cropYields = <String, double>{};
        for (final h in harvests) {
          final weight = h.unit == 'kg' ? (h.weight ?? 0) * 1000 : (h.weight ?? 0);
          cropYields[h.cropName] = (cropYields[h.cropName] ?? 0) + weight;
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildStatsCard(context, totalWeight, cropYields),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Høsthistorik',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            ...harvests.map((h) => _HarvestTile(harvest: h)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Fejl: $err')),
    );
  }

  Widget _buildStatsCard(BuildContext context, double totalWeight, Map<String, double> cropYields) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sæsonens Udbytte',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.scale, color: Colors.green),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Total: ${totalWeight >= 1000 ? (totalWeight / 1000).toStringAsFixed(1) : totalWeight.toInt()} ${totalWeight >= 1000 ? 'kg' : 'g'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            ...cropYields.entries.take(3).map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key),
                  Text(
                    '${e.value >= 1000 ? (e.value / 1000).toStringAsFixed(1) : e.value.toInt()} ${e.value >= 1000 ? 'kg' : 'g'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined, size: 64, color: Colors.green.shade200),
          const SizedBox(height: AppSpacing.md),
          const Text('Ingen høst logget endnu.'),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Brug "Høst" knappen på et bed for at starte.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _HarvestTile extends ConsumerWidget {
  final GardenHarvest harvest;

  const _HarvestTile({required this.harvest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d. MMM yyyy', 'da_DK');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.eco, color: Colors.white, size: 20),
        ),
        title: Text(harvest.variety != null ? '${harvest.cropName} (${harvest.variety})' : harvest.cropName),
        subtitle: Text(dateFormat.format(harvest.date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (harvest.weight != null)
              Text(
                '${harvest.weight!.toInt()} ${harvest.unit}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) => Icon(
                index < harvest.quality ? Icons.star : Icons.star_border,
                size: 12,
                color: Colors.amber,
              )),
            ),
          ],
        ),
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Slet høst?'),
              content: const Text('Er du sikker på, at du vil slette denne høstlog?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuller')),
                TextButton(
                  onPressed: () {
                    ref.read(gardenServiceProvider).deleteHarvest(harvest.homeId, harvest.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Slet', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
