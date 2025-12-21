import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/garden_bed_model.dart';
import '../../data/models/garden_crop_model.dart';
import '../providers/garden_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

class BedDetailsSheet extends ConsumerStatefulWidget {
  final GardenBed bed;

  const BedDetailsSheet({
    super.key,
    required this.bed,
  });

  @override
  ConsumerState<BedDetailsSheet> createState() => _BedDetailsSheetState();
}

class _BedDetailsSheetState extends ConsumerState<BedDetailsSheet> {
  final _dateFormat = DateFormat('d. MMMM yyyy', 'da_DK');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.bed.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            '${widget.bed.width.toInt()} x ${widget.bed.height.toInt()} cm',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.gray),
          ),
          const Divider(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Planter (${widget.bed.crops.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: () => _addCrop(context),
                icon: const Icon(Icons.add),
                label: const Text('Tilføj plante'),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          Expanded(
            child: widget.bed.crops.isEmpty
                ? const Center(child: Text('Ingen planter i dette bed endnu.'))
                : ListView.builder(
                    itemCount: widget.bed.crops.length,
                    itemBuilder: (context, index) {
                      final crop = widget.bed.crops[index];
                      return _CropCard(
                        crop: crop,
                        onEdit: () => _editCrop(context, crop),
                        onDelete: () => ref.read(gardenControllerProvider.notifier).removeCrop(widget.bed, crop.id),
                        onAction: (action) => _handleCropAction(crop, action),
                        dateFormat: _dateFormat,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet bed?'),
        content: Text('Er du sikker på, at du vil slette "${widget.bed.name}"? Dette kan ikke fortrydes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuller')),
          TextButton(
            onPressed: () {
              ref.read(gardenControllerProvider.notifier).deleteBed(widget.bed.homeId, widget.bed.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
            },
            child: const Text('Slet', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addCrop(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditCropSheet(
        onSave: (name, variety, notes) {
          final crop = GardenCrop.create(
            name: name,
            variety: variety,
            notes: notes,
            plantDate: DateTime.now(),
          );
          ref.read(gardenControllerProvider.notifier).addCrop(widget.bed, crop);
        },
      ),
    );
  }

  void _editCrop(BuildContext context, GardenCrop crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditCropSheet(
        crop: crop,
        onSave: (name, variety, notes) {
          final updated = crop.copyWith(
            name: name,
            variety: variety,
            notes: notes,
          );
          ref.read(gardenControllerProvider.notifier).updateCrop(widget.bed, updated);
        },
      ),
    );
  }

  void _handleCropAction(GardenCrop crop, String action) {
    final now = DateTime.now();
    GardenCrop updated;
    if (action == 'water') {
      updated = crop.copyWith(lastWatered: now);
    } else if (action == 'fertilize') {
      updated = crop.copyWith(lastFertilized: now);
    } else {
      return;
    }
    ref.read(gardenControllerProvider.notifier).updateCrop(widget.bed, updated);
  }
}

class _CropCard extends StatelessWidget {
  final GardenCrop crop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onAction;
  final DateFormat dateFormat;

  const _CropCard({
    required this.crop,
    required this.onEdit,
    required this.onDelete,
    required this.onAction,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(crop.name, style: Theme.of(context).textTheme.titleMedium),
                      if (crop.variety != null && crop.variety!.isNotEmpty)
                        Text(crop.variety!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (crop.plantDate != null)
              _InfoRow(label: 'Plantet:', value: dateFormat.format(crop.plantDate!)),
            if (crop.lastWatered != null)
              _InfoRow(label: 'Vandet:', value: dateFormat.format(crop.lastWatered!)),
            if (crop.lastFertilized != null)
              _InfoRow(label: 'Gødet:', value: dateFormat.format(crop.lastFertilized!)),
            
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onAction('water'),
                    icon: const Icon(Icons.water_drop, size: 16),
                    label: const Text('Vand'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onAction('fertilize'),
                    icon: const Icon(Icons.science, size: 16),
                    label: const Text('Gød'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _EditCropSheet extends StatefulWidget {
  final GardenCrop? crop;
  final Function(String name, String variety, String notes) onSave;

  const _EditCropSheet({this.crop, required this.onSave});

  @override
  State<_EditCropSheet> createState() => _EditCropSheetState();
}

class _EditCropSheetState extends State<_EditCropSheet> {
  late TextEditingController _nameController;
  late TextEditingController _varietyController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.crop?.name);
    _varietyController = TextEditingController(text: widget.crop?.variety);
    _notesController = TextEditingController(text: widget.crop?.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _varietyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.crop == null ? 'Tilføj plante' : 'Rediger plante',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Hvad er det? (f.eks. Gulerødder)', border: OutlineInputBorder()),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _varietyController,
            decoration: const InputDecoration(labelText: 'Sort (f.eks. Nantes 2)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Noter', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                widget.onSave(_nameController.text, _varietyController.text, _notesController.text);
                Navigator.pop(context);
              }
            },
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Gem')),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
