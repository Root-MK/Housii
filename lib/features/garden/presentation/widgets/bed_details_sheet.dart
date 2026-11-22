import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/garden_bed_model.dart';
import '../../data/models/garden_crop_model.dart';
import '../providers/garden_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import 'bed_form_sheet.dart';
import '../../data/water_index_service.dart';
import '../../data/models/water_index_config.dart';
import '../../../../shared/providers/home_provider.dart';
import 'water_status_widget.dart';
import 'watering_form_sheet.dart';
import 'water_history_chart.dart';

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
  BedWaterStatus? _waterStatus;
  bool _isLoadingWaterStatus = true;

  @override
  void initState() {
    super.initState();
    _loadWaterStatus();
  }

  Future<void> _loadWaterStatus() async {
    try {
      final home = ref.read(currentHomeProvider).value;
      if (home != null) {
        final service = ref.read(waterIndexServiceProvider);
        final status = await service.calculateBedWaterStatus(home.id, widget.bed.id);
        if (mounted) {
          setState(() {
            _waterStatus = status;
            _isLoadingWaterStatus = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading water status: $e');
      if (mounted) {
        setState(() {
          _isLoadingWaterStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(waterIndexConfigProvider);
    final config = configAsync.value ?? const WaterIndexConfig();

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
                child: Row(
                  children: [
                    if (widget.bed.icon != null) ...[
                      Text(widget.bed.icon!, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.bed.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Rediger bed detaljer',
                      onPressed: () {
                        Navigator.pop(context); // Close details
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => BedFormSheet(bed: widget.bed),
                        );
                      },
                    ),
                  ],
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
          
          if (_waterStatus != null) ...[
            const SizedBox(height: AppSpacing.md),
            WaterStatusWidget(
              status: _waterStatus!,
              config: config,
              service: ref.read(waterIndexServiceProvider),
              bedWidthCm: widget.bed.width,
              bedHeightCm: widget.bed.height,
              compact: false,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => WateringFormSheet(bed: widget.bed),
                    ).then((_) => _loadWaterStatus());
                  },
                  icon: const Icon(Icons.water_drop),
                  label: const Text('Registrer vanding'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.6,
                        minChildSize: 0.4,
                        maxChildSize: 0.9,
                        expand: false,
                        builder: (context, scrollController) => Column(
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Vandbalance Historik',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Viser vandunderskud over tid (mm)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: WaterHistoryChart(
                                  homeId: ref.read(currentHomeProvider).value!.id,
                                  bedId: widget.bed.id,
                                  wateringThreshold: config.wateringThreshold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.show_chart),
                  label: const Text('Historik'),
                ),
              ],
            ),
          ],

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
                        bed: widget.bed,
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Slet bed?'),
        content: Text('Er du sikker på, at du vil slette "${widget.bed.name}"? Dette kan ikke fortrydes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () async {
              // Capture navigator and context before any async work
              final navigator = Navigator.of(context);
              
              // Close dialog
              Navigator.pop(dialogContext);
              
              // Perform deletion
              await ref.read(gardenControllerProvider.notifier).deleteBed(
                widget.bed.homeId,
                widget.bed.id,
              );
              
              // Close sheet if we're still mounted
              if (context.mounted) {
                navigator.pop();
              }
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
        onSave: (name, variety, quantity, notes, plantDate) {
          final crop = GardenCrop.create(
            name: name,
            variety: variety,
            quantity: quantity,
            notes: notes,
            plantDate: plantDate,
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
        onSave: (name, variety, quantity, notes, plantDate) {
          final updated = crop.copyWith(
            name: name,
            variety: variety,
            quantity: quantity,
            notes: notes,
            plantDate: plantDate,
          );
          ref.read(gardenControllerProvider.notifier).updateCrop(widget.bed, updated);
        },
      ),
    );
  }

  Future<void> _handleCropAction(GardenCrop crop, String action) async {
    final title = 'Registrer gødning';
    final now = DateTime.now();
    DateTime selectedDate = now;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hvornår blev dette udført?'),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_dateFormat.format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: now,
                    locale: const Locale('da', 'DK'),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuller')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Bekræft')),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final updated = crop.copyWith(lastFertilized: selectedDate);
      ref.read(gardenControllerProvider.notifier).updateCrop(widget.bed, updated);
    }
  }
}

class _CropCard extends StatelessWidget {
  final GardenCrop crop;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onAction;
  final GardenBed bed;
  final DateFormat dateFormat;

  const _CropCard({
    required this.crop,
    required this.onEdit,
    required this.onDelete,
    required this.onAction,
    required this.bed,
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
                      Text(
                        crop.quantity > 1 ? '${crop.quantity}x ${crop.name}' : crop.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
  final Function(String name, String variety, int quantity, String notes, DateTime plantDate) onSave;

  const _EditCropSheet({this.crop, required this.onSave});

  @override
  State<_EditCropSheet> createState() => _EditCropSheetState();
}

class _EditCropSheetState extends State<_EditCropSheet> {
  late TextEditingController _nameController;
  late TextEditingController _varietyController;
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  late DateTime _plantDate;
  final _dateFormat = DateFormat('d. MMMM yyyy', 'da_DK');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.crop?.name);
    _varietyController = TextEditingController(text: widget.crop?.variety);
    _quantityController = TextEditingController(text: (widget.crop?.quantity ?? 1).toString());
    _notesController = TextEditingController(text: widget.crop?.notes);
    _plantDate = widget.crop?.plantDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _varietyController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('da', 'DK'),
    );
    if (picked != null) {
      setState(() {
        _plantDate = picked;
      });
    }
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
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Antal', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Plantet dato'),
            subtitle: Text(_dateFormat.format(_plantDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDate,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
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
                final quantity = int.tryParse(_quantityController.text) ?? 1;
                widget.onSave(_nameController.text, _varietyController.text, quantity, _notesController.text, _plantDate);
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
