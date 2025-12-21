import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/list_model.dart';
import '../../data/models/list_item_model.dart';
import '../providers/lists_providers.dart';
import '../widgets/list_filter_bar.dart';
import '../widgets/list_tabs.dart';
import '../widgets/list_item_card.dart';
import '../widgets/add_list_item_sheet.dart';
import '../widgets/add_list_sheet.dart';
import '../widgets/edit_list_item_sheet.dart';
import '../../data/lists_service.dart';

/// Main lists screen
class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final lists = ref.read(orderedListsProvider);
    if (index >= 0 && index < lists.length) {
      ref.read(selectedListIdProvider.notifier).state = lists[index].id;
      setState(() {
        _currentPageIndex = index;
      });
    }
  }

  void _onTabSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showAddListSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => const AddListSheet(),
    );
  }

  void _showEditItemSheet(ListItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => EditListItemSheet(item: item),
    );
  }

  void _showItemContextMenu(BuildContext context, Offset position, ListItemModel item) {
    final selectedList = ref.read(selectedListProvider);
    final isChecklist = selectedList?.isChecklist ?? false;
    
    HapticFeedback.mediumImpact();

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      color: AppColors.white,
      elevation: 8,
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: AppSpacing.sm),
              const Text('Rediger'),
            ],
          ),
        ),
        if (isChecklist)
          PopupMenuItem(
            value: 'toggle_complete',
            child: Row(
              children: [
                Icon(
                  item.isChecked ? Icons.radio_button_unchecked : Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(item.isChecked ? 'Marker som ikke fuldført' : 'Marker som fuldført'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'move_top',
          child: Row(
            children: [
              Icon(Icons.vertical_align_top, color: AppColors.gray, size: 20),
              const SizedBox(width: AppSpacing.sm),
              const Text('Flyt til top'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'move_bottom',
          child: Row(
            children: [
              Icon(Icons.vertical_align_bottom, color: AppColors.gray, size: 20),
              const SizedBox(width: AppSpacing.sm),
              const Text('Flyt til bund'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive_outlined, color: AppColors.warning, size: 20),
              const SizedBox(width: AppSpacing.sm),
              const Text('Arkiver'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('Slet', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    ).then((value) => _handleContextMenuAction(value, item));
  }

  Future<void> _handleContextMenuAction(String? action, ListItemModel item) async {
    if (action == null) return;
    
    final home = ref.read(currentHomeProvider).valueOrNull;
    final user = ref.read(currentUserProvider).valueOrNull;
    final selectedList = ref.read(selectedListProvider);
    
    if (home == null || user == null || selectedList == null) return;
    
    final listsService = ref.read(listsServiceProvider);
    
    try {
      switch (action) {
        case 'edit':
          _showEditItemSheet(item);
          break;
        case 'toggle_complete':
          await listsService.toggleItemChecked(
            home.id,
            selectedList.id,
            item.id,
            !item.isChecked,
          );
          HapticFeedback.lightImpact();
          break;
        case 'move_top':
          await listsService.moveItemToTop(home.id, item.id);
          HapticFeedback.lightImpact();
          break;
        case 'move_bottom':
          await listsService.moveItemToBottom(home.id, selectedList.id, item.id);
          HapticFeedback.lightImpact();
          break;
        case 'archive':
          await listsService.archiveItem(home.id, selectedList.id, item.id, user.id, item.isChecked);
          HapticFeedback.mediumImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Punkt arkiveret'),
                action: SnackBarAction(
                  label: 'Fortryd',
                  onPressed: () async {
                    await listsService.unarchiveItem(home.id, selectedList.id, item.id, item.isChecked);
                  },
                ),
              ),
            );
          }
          break;
        case 'delete':
          _showDeleteConfirmation(item);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(ListItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet punkt'),
        content: const Text('Er du sikker på at du vil slette dette punkt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final home = ref.read(currentHomeProvider).valueOrNull;
              final selectedList = ref.read(selectedListProvider);
              if (home == null || selectedList == null) return;
              
              await ref.read(listsServiceProvider).deleteItem(
                home.id,
                selectedList.id,
                item.id,
                item.isChecked,
              );
              HapticFeedback.mediumImpact();
            },
            child: Text('Slet', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleItemReorder(int oldIndex, int newIndex, List<ListItemModel> items) async {
    if (oldIndex == newIndex) return;
    
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null) return;
    
    // Calculate new sort orders
    final sortOrders = <String, int>{};
    final reorderedItems = List<ListItemModel>.from(items);
    final item = reorderedItems.removeAt(oldIndex);
    reorderedItems.insert(newIndex, item);
    
    for (var i = 0; i < reorderedItems.length; i++) {
      sortOrders[reorderedItems[i].id] = (i + 1) * 1000;
    }
    
    try {
      await ref.read(listsServiceProvider).batchUpdateSortOrders(home.id, sortOrders);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kunne ikke ændre rækkefølge: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(activeListsProvider);
    final orderedLists = ref.watch(orderedListsProvider);
    final selectedList = ref.watch(selectedListProvider);
    final sortedItems = ref.watch(sortedListItemsProvider);
    
    // Update page controller when lists change
    if (selectedList != null) {
      final selectedIndex = orderedLists.indexWhere((l) => l.id == selectedList.id);
      if (selectedIndex >= 0 && selectedIndex != _currentPageIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(selectedIndex);
          }
        });
      }
    }

    return Column(
      children: [
        // Filter bar at the very top
        const ListFilterBar(),
        
        // Tab bar for lists
        if (orderedLists.isNotEmpty)
          ListTabs(
            lists: orderedLists,
            selectedIndex: _currentPageIndex,
            onTabSelected: _onTabSelected,
          ),
        
        // Content
        Expanded(
          child: listsAsync.when(
            data: (lists) {
              if (orderedLists.isEmpty) {
                return _buildEmptyState();
              }
              
              return PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: orderedLists.length,
                itemBuilder: (context, index) {
                  final list = orderedLists[index];
                  final isSelected = selectedList?.id == list.id;
                  
                  if (!isSelected) {
                    // Return placeholder for non-selected pages
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return _buildListContent(list, sortedItems);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text('Fejl: $e'),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(activeListsProvider),
                    child: const Text('Prøv igen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.list_alt_outlined,
                size: 48,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Ingen lister',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tryk + for at oprette din første liste',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.gray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(ListModel list, SortedListItems sortedItems) {
    if (sortedItems.isEmpty) {
      return _buildEmptyListState(list);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentListItemsProvider);
      },
      child: CustomScrollView(
        slivers: [
          // Unchecked items (draggable)
          if (sortedItems.unchecked.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverReorderableList(
                itemCount: sortedItems.unchecked.length,
                itemBuilder: (context, index) {
                  final item = sortedItems.unchecked[index];
                  return ReorderableDragStartListener(
                    key: Key(item.id),
                    index: index,
                    child: ListItemCard(
                      item: item,
                      isChecklist: list.isChecklist,
                      onTap: () => _showEditItemSheet(item),
                      onLongPress: (position) => _showItemContextMenu(context, position, item),
                      onCheck: list.isChecklist
                          ? () => _handleContextMenuAction('toggle_complete', item)
                          : null,
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  _handleItemReorder(oldIndex, newIndex, sortedItems.unchecked);
                },
              ),
            ),
          
          // Checked items section (for checklists)
          if (list.isChecklist && sortedItems.checked.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: AppColors.gray),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Fuldført (${sortedItems.checked.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = sortedItems.checked[index];
                    return ListItemCard(
                      item: item,
                      isChecklist: true,
                      onTap: () => _showEditItemSheet(item),
                      onLongPress: (position) => _showItemContextMenu(context, position, item),
                      onCheck: () => _handleContextMenuAction('toggle_complete', item),
                    );
                  },
                  childCount: sortedItems.checked.length,
                ),
              ),
            ),
          ],
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyListState(ListModel list) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              list.isChecklist ? Icons.checklist : Icons.list,
              size: 64,
              color: AppColors.lightGray,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Listen er tom',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.gray,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tryk + for at tilføje et punkt',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
