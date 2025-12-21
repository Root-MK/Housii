import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/list_model.dart';
import '../../data/lists_service.dart';
import '../providers/lists_providers.dart';

/// Bottom sheet for managing lists (ordering, renaming, archiving)
class ListManagementSheet extends ConsumerStatefulWidget {
  const ListManagementSheet({super.key});

  @override
  ConsumerState<ListManagementSheet> createState() => _ListManagementSheetState();
}

class _ListManagementSheetState extends ConsumerState<ListManagementSheet> {
  List<ListModel>? _reorderedLists;

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(orderedListsProvider);
    final lists = _reorderedLists ?? listsAsync;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                    Icon(Icons.reorder, color: AppColors.primaryPurple),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Administrer lister',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (_reorderedLists != null)
                      TextButton(
                        onPressed: _saveOrder,
                        child: const Text('Gem'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // Instructions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Træk for at ændre rækkefølge. Tryk for at redigere.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gray,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              
              // List
              Expanded(
                child: lists.isEmpty
                    ? Center(
                        child: Text(
                          'Ingen lister',
                          style: TextStyle(color: AppColors.gray),
                        ),
                      )
                    : ReorderableListView.builder(
                        scrollController: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: lists.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          setState(() {
                            final reordered = List<ListModel>.from(lists);
                            final item = reordered.removeAt(oldIndex);
                            reordered.insert(newIndex, item);
                            _reorderedLists = reordered;
                          });
                          HapticFeedback.lightImpact();
                        },
                        itemBuilder: (context, index) {
                          final list = lists[index];
                          return _ListManagementCard(
                            key: Key(list.id),
                            list: list,
                            onRename: () => _showRenameDialog(list),
                            onArchive: () => _archiveList(list),
                            onDelete: () => _showDeleteDialog(list),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveOrder() async {
    if (_reorderedLists == null) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (user == null || home == null) return;

    try {
      final listOrder = _reorderedLists!.map((l) => l.id).toList();
      await ref.read(listsServiceProvider).saveListOrder(
        user.id,
        home.id,
        listOrder,
      );
      
      setState(() {
        _reorderedLists = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rækkefølge gemt')),
        );
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

  void _showRenameDialog(ListModel list) {
    final controller = TextEditingController(text: list.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Omdøb liste'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nyt navn',
          ),
          onSubmitted: (_) => Navigator.pop(context, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Gem'),
          ),
        ],
      ),
    ).then((newName) async {
      if (newName != null && newName.trim().isNotEmpty && newName != list.name) {
        final home = ref.read(currentHomeProvider).valueOrNull;
        if (home == null) return;
        
        try {
          await ref.read(listsServiceProvider).renameList(
            home.id,
            list.id,
            newName.trim(),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Liste omdøbt')),
            );
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
    });
  }

  Future<void> _archiveList(ListModel list) async {
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null) return;

    try {
      await ref.read(listsServiceProvider).archiveList(home.id, list.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Liste arkiveret'),
            action: SnackBarAction(
              label: 'Fortryd',
              onPressed: () async {
                await ref.read(listsServiceProvider).unarchiveList(home.id, list.id);
              },
            ),
          ),
        );
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

  void _showDeleteDialog(ListModel list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet liste'),
        content: Text(
          'Er du sikker på at du vil slette "${list.name}" og alle punkter? Dette kan ikke fortrydes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final home = ref.read(currentHomeProvider).valueOrNull;
              if (home == null) return;
              
              try {
                await ref.read(listsServiceProvider).deleteList(home.id, list.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Liste slettet')),
                  );
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
            },
            child: Text('Slet', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ListManagementCard extends StatelessWidget {
  final ListModel list;
  final VoidCallback onRename;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _ListManagementCard({
    super.key,
    required this.list,
    required this.onRename,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle, color: AppColors.lightGray),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              list.isChecklist ? Icons.checklist : Icons.list,
              color: AppColors.primaryPurple,
            ),
          ],
        ),
        title: Text(list.name),
        subtitle: Row(
          children: [
            Icon(
              list.isPersonal ? Icons.person : Icons.group,
              size: 14,
              color: AppColors.gray,
            ),
            const SizedBox(width: 4),
            Text(
              list.isPersonal ? 'Personlig' : 'Husstand',
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${list.itemCount} punkter',
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'rename':
                onRename();
                break;
              case 'archive':
                onArchive();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Omdøb'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Arkiver'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Slet', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
