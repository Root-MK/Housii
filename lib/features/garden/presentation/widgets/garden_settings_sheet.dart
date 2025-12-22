import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../../../shared/services/home_service.dart';

class GardenSettingsSheet extends ConsumerStatefulWidget {
  const GardenSettingsSheet({super.key});

  @override
  ConsumerState<GardenSettingsSheet> createState() => _GardenSettingsSheetState();
}

class _GardenSettingsSheetState extends ConsumerState<GardenSettingsSheet> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final home = ref.read(currentHomeProvider).value;
    final settings = home?.gardenSettings ?? {};
    
    _widthController = TextEditingController(
      text: (settings['width'] as num?)?.toString() ?? '1000',
    );
    _heightController = TextEditingController(
      text: (settings['height'] as num?)?.toString() ?? '1000',
    );
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final width = double.tryParse(_widthController.text);
    final height = double.tryParse(_heightController.text);

    if (width == null || height == null || width <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indtast venligst gyldige mål')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final homeService = ref.read(homeServiceProvider);
      final home = ref.read(currentHomeProvider).value;
      
      if (home != null) {
        final updatedSettings = Map<String, dynamic>.from(home.gardenSettings);
        updatedSettings['width'] = width;
        updatedSettings['height'] = height;

        await homeService.updateHome(home.copyWith(gardenSettings: updatedSettings));
        
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl ved gemning: $e')),
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
            'Haveindstillinger',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Angiv havens størrelse for at begrænse tegneområdet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _widthController,
                  decoration: const InputDecoration(
                    labelText: 'Bredde (cm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Højde (cm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Gem indstillinger'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
