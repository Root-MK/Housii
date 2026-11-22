import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/models/garden_bed_model.dart';
import '../providers/garden_providers.dart';
import '../../../../core/theme/app_colors.dart';

class BedFormSheet extends ConsumerStatefulWidget {
  final GardenBed? bed; // If null, create mode. If not null, edit mode.

  const BedFormSheet({super.key, this.bed});

  @override
  ConsumerState<BedFormSheet> createState() => _BedFormSheetState();
}

class _BedFormSheetState extends ConsumerState<BedFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late int _selectedColor;

  // Constants
  static const double _minSize = 20.0;
  static const double _maxSize = 1000.0;

  final List<Color> _colorPalette = const [
    Color(0xFF8D6E63), // Brown (Wood/Soil)
    Color(0xFF4CAF50), // Green
    Color(0xFFFF7043), // Terracotta
    Color(0xFF78909C), // Blue Grey (Stone)
    Color(0xFF5D4037), // Dark Brown
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple (App Brand)
    Color(0xFFFFC107), // Amber
    Color(0xFF2196F3), // Blue
  ];

  String? _selectedIcon;

  static const List<String> _gardenIcons = [
    '🥕', '🥔', '🍅', '🌽', '🥬', '🧅', '🧄', '🥦', '🥒', '🌶️', 
    '🍓', '🌻', '🌾', '🌿', '🍎', '🍐', '🍒', '🍇', '🍆', '🥜'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bed?.name ?? '');
    _widthController = TextEditingController(text: widget.bed?.width.toInt().toString() ?? '120');
    _heightController = TextEditingController(text: widget.bed?.height.toInt().toString() ?? '120');
    _selectedColor = widget.bed?.color ?? AppColors.primaryPurple.value;
    _selectedIcon = widget.bed?.icon;
  }

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
    final isEditing = widget.bed != null;
    
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
            isEditing ? 'Rediger bed' : 'Opret nyt bed',
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
            autofocus: !isEditing,
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
          const SizedBox(height: 16),
          Text(
            'Vælg farve',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colorPalette.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final color = _colorPalette[index];
                final isSelected = color.value == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color.value;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 2)
                          : Border.all(color: Colors.grey.shade300),
                      boxShadow: isSelected
                          ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Vælg ikon (valgfrit)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _gardenIcons.length,
              itemBuilder: (context, index) {
                final icon = _gardenIcons[index];
                final isSelected = _selectedIcon == icon;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = isSelected ? null : icon;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
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

                if (isEditing) {
                  // Update
                  ref.read(gardenControllerProvider.notifier).updateBed(
                    widget.bed!.copyWith(
                      name: _nameController.text,
                      width: width,
                      height: height,
                      color: _selectedColor,
                      icon: _selectedIcon,
                    ),
                  );
                } else {
                  // Create
                  ref.read(gardenControllerProvider.notifier).createBed(
                    name: _nameController.text,
                    homeId: home.id,
                    width: width,
                    height: height,
                    x: 500, // Default position in the canvas
                    y: 500,
                    color: _selectedColor,
                    icon: _selectedIcon,
                  );
                }
                Navigator.pop(context);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(isEditing ? 'Gem ændringer' : 'Opret'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
