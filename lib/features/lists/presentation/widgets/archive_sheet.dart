import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/models/list_model.dart';
import '../../data/models/list_item_model.dart';
import '../../data/lists_service.dart';
import '../providers/lists_providers.dart';

/// Bottom sheet for viewing archived lists and items
class ArchiveSheet extends ConsumerStatefulWidget {
  const ArchiveSheet({super.key});

  @override
  ConsumerState<ArchiveSheet> createState() => _ArchiveSheetState();
}

class _ArchiveSheetState extends ConsumerState<ArchiveSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archivedLists = ref.watch(archivedListsProvider);
    final archivedItems = ref.watch(filteredArchivedItemsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXLarge),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, color: AppColors.primaryPurple),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Arkiv',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Søg i arkiv...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.offWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(archiveSearchQueryProvider.notifier).state = value;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Tab bar
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryPurple,
                unselectedLabelColor: AppColors.gray,
                indicatorColor: AppColors.primaryPurple,
                tabs: const [
                  Tab(text: 'Lister'),
                  Tab(text: 'Punkter'),
                ],
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Archived lists
                    archivedLists.when(
                      data: (lists) {
                        if (lists.isEmpty) {
                          return _buildEmptyState('Ingen arkiverede lister');
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: lists.length,
                          itemBuilder: (context, index) {
                            return _ArchivedListCard(list: lists[index]);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Fejl: $e')),
                    ),
                    
                    // Archived items
                    archivedItems.isEmpty
                        ? _buildEmptyState('Ingen arkiverede punkter')
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: archivedItems.length,
                            itemBuilder: (context, index) {
                              return _ArchivedItemCard(item: archivedItems[index]);
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.lightGray),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedListCard extends ConsumerWidget {
  final ListModel list;

  const _ArchivedListCard({required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(
          list.isChecklist ? Icons.checklist : Icons.list,
          color: AppColors.gray,
        ),
        title: Text(list.name),
        subtitle: Text(
          '${list.itemCount} punkter • ${list.isPersonal ? "Personlig" : "Husstand"}',
          style: TextStyle(color: AppColors.gray),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(context, ref, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'unarchive',
              child: Row(
                children: [
                  Icon(Icons.unarchive, size: 20),
                  SizedBox(width: 8),
                  Text('Gendan'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Slet permanent', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null) return;

    final listsService = ref.read(listsServiceProvider);

    try {
      switch (action) {
        case 'unarchive':
          await listsService.unarchiveList(home.id, list.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Liste genoprettet')),
            );
          }
          break;
        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Slet permanent'),
              content: const Text('Er du sikker? Dette kan ikke fortrydes.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuller'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Slet', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await listsService.deleteList(home.id, list.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Liste slettet permanent')),
              );
            }
          }
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _ArchivedItemCard extends ConsumerWidget {
  final ListItemModel item;

  const _ArchivedItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(listByIdProvider(item.listId));

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: item.isChecked
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : const Icon(Icons.circle_outlined, color: AppColors.gray),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          list?.name ?? 'Ukendt liste',
          style: TextStyle(color: AppColors.gray),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(context, ref, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'unarchive',
              child: Row(
                children: [
                  Icon(Icons.unarchive, size: 20),
                  SizedBox(width: 8),
                  Text('Gendan'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Slet permanent', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null) return;

    final listsService = ref.read(listsServiceProvider);

    try {
      switch (action) {
        case 'unarchive':
          await listsService.unarchiveItem(home.id, item.listId, item.id, item.isChecked);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Punkt genoprettet')),
            );
          }
          break;
        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Slet permanent'),
              content: const Text('Er du sikker? Dette kan ikke fortrydes.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuller'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Slet', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await listsService.deleteItem(home.id, item.listId, item.id, item.isChecked);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Punkt slettet permanent')),
              );
            }
          }
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
