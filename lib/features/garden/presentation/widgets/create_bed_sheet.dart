import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/home_provider.dart';
import '../providers/garden_providers.dart';

class CreateBedSheet extends ConsumerStatefulWidget {
  const CreateBedSheet({super.key});

  @override
  ConsumerState<CreateBedSheet> createState() => _CreateBedSheetState();
}

class _CreateBedSheetState extends ConsumerState<CreateBedSheet> {
  final _nameController = TextEditingController();
  final _widthController = TextEditingController(text: '120');
  final _heightController = TextEditingController(text: '120');

  // Constants
  static const double _minSize = 20.0;
  static const double _maxSize = 1000.0; // 10 meters

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(currentHomeProvider);
    
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
            'Opret nyt bed',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Navn (f.eks. Højbed 1)',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
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
                    helperText: 'Max 1000 cm',
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
                    helperText: 'Max 1000 cm',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final home = homeState.value;
              if (home != null && _nameController.text.isNotEmpty) {
                final width = double.tryParse(_widthController.text) ?? 100;
                final height = double.tryParse(_heightController.text) ?? 100;

                // Validate
                if (width < _minSize || width > _maxSize || height < _minSize || height > _maxSize) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mål skal være mellem $_minSize og $_maxSize cm')),
                  );
                  return;
                }

                ref.read(gardenControllerProvider.notifier).createBed(
                  name: _nameController.text,
                  homeId: home.id,
                  width: width,
                  height: height,
                  x: 500, // Default position in the canvas
                  y: 500,
                );
                Navigator.pop(context);
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Opret'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
