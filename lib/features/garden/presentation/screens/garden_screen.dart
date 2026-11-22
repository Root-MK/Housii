import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/strings_da.dart';
import '../widgets/garden_list_tab.dart';
import '../widgets/garden_visual_tab.dart';
import '../widgets/harvest_log_tab.dart';
import '../widgets/water_index_tab.dart';
import '../providers/garden_view_provider.dart';

class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});

  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends ConsumerState<GardenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      // Sync tab index to provider
      ref.read(gardenViewProvider.notifier).setTabIndex(_tabController.index);
      // Exit edit mode when switching away from Visual tab
      if (_tabController.index != 1) {
        ref.read(gardenViewProvider.notifier).exitEditMode();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gardenViewState = ref.watch(gardenViewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.garden),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Liste', icon: Icon(Icons.list)),
            Tab(text: 'Visuel', icon: Icon(Icons.grid_view)),
            Tab(text: 'Høst', icon: Icon(Icons.eco)),
            Tab(text: 'Vand', icon: Icon(Icons.water_drop)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to avoid conflict with canvas
        children: [
          const GardenListTab(),
          GardenVisualTab(isEditMode: gardenViewState.isEditMode),
          const HarvestLogTab(),
          const WaterIndexTab(),
        ],
      ),
    );
  }
}
