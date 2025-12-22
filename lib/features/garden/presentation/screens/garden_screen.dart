import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/strings_da.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/garden_list_tab.dart';
import '../widgets/garden_visual_tab.dart';
import '../widgets/bed_form_sheet.dart';
import '../widgets/garden_settings_sheet.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const GardenSettingsSheet(),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Liste', icon: Icon(Icons.list)),
            Tab(text: 'Visuel', icon: Icon(Icons.grid_view)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to avoid conflict with canvas
        children: [
          const GardenListTab(),
          GardenVisualTab(isEditMode: _isEditMode),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (_tabController.index != 1) return null; // No FAB in List mode

    if (!_isEditMode) {
      // Standard Mode: Show Edit Button
      return FloatingActionButton(
        onPressed: () {
          setState(() {
            _isEditMode = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Redigeringstilstand aktiveret')),
          );
        },
        tooltip: 'Rediger have',
        child: const Icon(Icons.edit),
      );
    } else {
      // Edit Mode: Show Add and Done buttons
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'addBed',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const BedFormSheet(),
              );
            },
            tooltip: 'Tilføj bed',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: AppSpacing.md),
          FloatingActionButton(
            heroTag: 'doneEdit',
            onPressed: () {
              setState(() {
                _isEditMode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redigering afsluttet')),
              );
            },
            backgroundColor: Colors.green,
            tooltip: 'Færdig',
            child: const Icon(Icons.check),
          ),
        ],
      );
    }
  }
}
