import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/strings_da.dart';
import '../../../../shared/providers/home_provider.dart';
import '../providers/garden_providers.dart';
import '../widgets/garden_list_tab.dart';
import '../widgets/garden_visual_tab.dart';

class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});

  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends ConsumerState<GardenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // Update UI when tab changes
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.garden),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Liste', icon: Icon(Icons.list)),
            Tab(text: 'Visuel', icon: Icon(Icons.grid_view)),
          ],
        ),
        actions: [
          if (_tabController.index == 1) // Only show edit toggle in Visual mode
            IconButton(
              icon: Icon(_isEditMode ? Icons.check : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
                if (!_isEditMode) {
                  // Logic to save if needed, though we save on interaction usually
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Redigering afsluttet')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Redigeringstilotand aktiveret')),
                  );
                }
              },
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to avoid conflict with canvas
        children: [
          const GardenListTab(),
          GardenVisualTab(isEditMode: _isEditMode),
        ],
      ),
      floatingActionButton: _isEditMode && _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () {
                // Add new bed logic - handled by the visual tab via a global key or provider?
                // Or we can pass a callback/provider.
                // Simpler: Use a provider to trigger "Add Mode" or show a dialog to create basic bed first.
                 showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const CreateBedSheet(),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class CreateBedSheet extends ConsumerStatefulWidget {
  const CreateBedSheet({super.key});

  @override
  ConsumerState<CreateBedSheet> createState() => _CreateBedSheetState();
}

class _CreateBedSheetState extends ConsumerState<CreateBedSheet> {
  final _nameController = TextEditingController();
  final _widthController = TextEditingController(text: '120');
  final _heightController = TextEditingController(text: '120');

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
            onPressed: () {
              final home = homeState.value;
              if (home != null && _nameController.text.isNotEmpty) {
                ref.read(gardenControllerProvider.notifier).createBed(
                  name: _nameController.text,
                  homeId: home.id,
                  width: double.tryParse(_widthController.text) ?? 100,
                  height: double.tryParse(_heightController.text) ?? 100,
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
