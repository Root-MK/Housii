import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/garden_bed_model.dart';
import '../../data/models/garden_crop_model.dart';
import '../providers/garden_providers.dart';
import 'bed_details_sheet.dart';
import 'bed_form_sheet.dart';
import 'harvest_form_sheet.dart';
import 'watering_form_sheet.dart';

/// A lightweight popover dialog that shows key bed information.
class BedPopoverDialog extends ConsumerWidget {
  final GardenBed bed;

  const BedPopoverDialog({super.key, required this.bed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bedColor = bed.color != null ? Color(bed.color!) : AppColors.primaryPurple;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: bedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    bed.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${bed.width.toInt()} x ${bed.height.toInt()} cm',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const Divider(height: AppSpacing.lg),

            // Crops Summary
            if (bed.crops.isEmpty)
              const Text('Ingen planter endnu.', style: TextStyle(color: Colors.grey))
            else
              ...bed.crops.take(3).map((crop) => _CropSummaryRow(crop: crop)),
            
            if (bed.crops.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '+ ${bed.crops.length - 3} mere...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            // Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => BedFormSheet(bed: bed),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Rediger'),
                ),
                const SizedBox(height: AppSpacing.xs),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => HarvestFormSheet(bed: bed),
                    );
                  },
                  icon: const Icon(Icons.eco, size: 18),
                  label: const Text('Høst'),
                ),
                const SizedBox(height: AppSpacing.xs),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => WateringFormSheet(bed: bed),
                    );
                  },
                  icon: const Icon(Icons.water_drop, size: 18, color: Colors.blue),
                  label: const Text('Vand'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => BedDetailsSheet(bed: bed),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Detaljer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CropSummaryRow extends StatelessWidget {
  final GardenCrop crop;

  const _CropSummaryRow({required this.crop});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.eco, size: 14, color: Colors.green),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              crop.quantity > 1 ? '${crop.quantity}x ${crop.name}' : crop.name,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
