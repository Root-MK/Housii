import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/garden_service.dart';
import '../../data/models/garden_bed_model.dart';
import '../../data/models/garden_crop_model.dart';
import '../../data/models/garden_harvest_model.dart';

class HarvestFormSheet extends ConsumerStatefulWidget {
  final GardenBed bed;
  final GardenCrop? crop;

  const HarvestFormSheet({super.key, required this.bed, this.crop});

  @override
  ConsumerState<HarvestFormSheet> createState() => _HarvestFormSheetState();
}

class _HarvestFormSheetState extends ConsumerState<HarvestFormSheet> {
  late TextEditingController _weightController;
  late TextEditingController _countController;
  late TextEditingController _notesController;
  String _unit = 'g';
  int _quality = 3;
  GardenCrop? _selectedCrop;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCrop = widget.crop ?? (widget.bed.crops.isNotEmpty ? widget.bed.crops.first : null);
    _weightController = TextEditingController();
    _countController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCrop == null) return;

    setState(() => _isLoading = true);

    try {
      final harvest = GardenHarvest.create(
        homeId: widget.bed.homeId,
        bedId: widget.bed.id,
        cropId: _selectedCrop!.id,
        cropName: _selectedCrop!.name,
        variety: _selectedCrop!.variety,
        weight: double.tryParse(_weightController.text),
        unit: _unit,
        count: int.tryParse(_countController.text),
        quality: _quality,
        notes: _notesController.text,
      );

      await ref.read(gardenServiceProvider).addHarvest(harvest);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl ved gemning af høst: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            'Log Høst',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Crop Selection
          DropdownButtonFormField<GardenCrop>(
            value: _selectedCrop,
            decoration: const InputDecoration(
              labelText: 'Plante',
              border: OutlineInputBorder(),
            ),
            items: widget.bed.crops.map((crop) {
              return DropdownMenuItem(
                value: crop,
                child: Text(crop.variety != null ? '${crop.name} (${crop.variety})' : crop.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCrop = value),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Vægt',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Enhed',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'g', child: Text('g')),
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'stk', child: Text('stk')),
                  ],
                  onChanged: (value) => setState(() => _unit = value ?? 'g'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _countController,
            decoration: const InputDecoration(
              labelText: 'Antal (valgfrit)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          const Text('Kvalitet'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _quality ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => setState(() => _quality = index + 1),
              );
            }),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Noter',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isLoading || _selectedCrop == null ? null : _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Gem Høst'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
