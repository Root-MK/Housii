import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/models/store.dart';
import '../../data/store_service.dart';
import '../providers/shopping_providers.dart';

/// Bottom sheet for managing stores in a household
class ManageStoresSheet extends ConsumerStatefulWidget {
  const ManageStoresSheet({super.key});

  @override
  ConsumerState<ManageStoresSheet> createState() => _ManageStoresSheetState();
}

class _ManageStoresSheetState extends ConsumerState<ManageStoresSheet> {
  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    'Administrer butikker',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showAddStoreDialog(context),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primaryPurple,
                  ),
                ],
              ),
            ),
            
            // Hint for drag to reorder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Hold og træk for at ændre rækkefølge',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gray,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Store list
            Flexible(
              child: storesAsync.when(
                data: (stores) {
                  if (stores.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text('Ingen butikker endnu'),
                    );
                  }

                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: stores.length,
                    onReorder: (oldIndex, newIndex) => _onReorder(stores, oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return _buildStoreItem(store, key: ValueKey(store.id));
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text('Fejl: $e'),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _onReorder(List<Store> stores, int oldIndex, int newIndex) async {
    // Adjust newIndex for removal
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // Create a new list with reordered stores
    final reorderedStores = List<Store>.from(stores);
    final item = reorderedStores.removeAt(oldIndex);
    reorderedStores.insert(newIndex, item);
    
    // Update in Firestore
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null) return;
    
    try {
      await ref.read(storeServiceProvider).updateStoreOrder(home.id, reorderedStores);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunne ikke ændre rækkefølge: $e')),
        );
      }
    }
  }

  Widget _buildStoreItem(Store store, {Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: 0, // Will be set by ReorderableListView
            child: Icon(
              Icons.drag_handle,
              color: AppColors.gray,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          
          // Color indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: store.color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Emoji
          if (store.emoji != null) ...[
            Text(
              store.emoji!,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],

          // Name
          Expanded(
            child: Text(
              store.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),

          // Edit button
          IconButton(
            onPressed: () => _showEditStoreDialog(context, store),
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.gray,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Delete button (disabled for default store)
          IconButton(
            onPressed: store.isDefault ? null : () => _confirmDelete(store),
            icon: const Icon(Icons.delete_outline, size: 20),
            color: store.isDefault ? AppColors.lightGray : AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddStoreDialog(BuildContext context) async {
    final result = await showDialog<Store>(
      context: context,
      builder: (context) => const _StoreFormDialog(),
    );

    if (result != null && mounted) {
      final home = ref.read(currentHomeProvider).valueOrNull;
      if (home == null) return;

      try {
        await ref.read(storeServiceProvider).addStore(
              home.id,
              name: result.name,
              colorHex: result.colorHex,
              emoji: result.emoji ?? '🏪',
            );
        HapticFeedback.lightImpact();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kunne ikke tilføje butik: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditStoreDialog(BuildContext context, Store store) async {
    final result = await showDialog<Store>(
      context: context,
      builder: (context) => _StoreFormDialog(existingStore: store),
    );

    if (result != null && mounted) {
      final home = ref.read(currentHomeProvider).valueOrNull;
      if (home == null) return;

      try {
        await ref.read(storeServiceProvider).updateStore(home.id, result);
        HapticFeedback.lightImpact();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kunne ikke opdatere butik: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(Store store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet butik'),
        content: Text('Er du sikker på, at du vil slette "${store.name}"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final home = ref.read(currentHomeProvider).valueOrNull;
      if (home == null) return;

      try {
        await ref.read(storeServiceProvider).deleteStore(home.id, store.id);
        HapticFeedback.mediumImpact();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kunne ikke slette butik: $e')),
          );
        }
      }
    }
  }
}

/// Dialog for adding/editing a store
class _StoreFormDialog extends StatefulWidget {
  final Store? existingStore;

  const _StoreFormDialog({this.existingStore});

  @override
  State<_StoreFormDialog> createState() => _StoreFormDialogState();
}

class _StoreFormDialogState extends State<_StoreFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedColorHex;
  late String _selectedEmoji;

  // Predefined colors
  static const List<String> _colors = [
    '#1E3A8A', // Dark blue
    '#16A34A', // Green
    '#DC2626', // Red
    '#EAB308', // Yellow
    '#F97316', // Orange
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#6B7280', // Gray
    '#000000', // Black
  ];

  // Predefined emojis
  static const List<String> _emojis = [
    '🔵',
    '🟢',
    '🔴',
    '🟡',
    '🟠',
    '🟣',
    '💛',
    '🏪',
    '🛒',
    '🛍️',
    '🍎',
    '🥕',
    '🥛',
    '🍞',
    '🧀',
    '🥩',
    '🐟',
    '🍫',
    '☕',
    '🧃',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingStore?.name ?? '',
    );
    _selectedColorHex = widget.existingStore?.colorHex ?? _colors.first;
    _selectedEmoji = widget.existingStore?.emoji ?? _emojis.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingStore != null;

    return AlertDialog(
      title: Text(isEditing ? 'Rediger butik' : 'Tilføj butik'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Butik navn',
                  hintText: 'f.eks. Netto',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Indtast et navn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Emoji selection
              Text(
                'Vælg emoji',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gray,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _emojis.map((emoji) {
                  final isSelected = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedEmoji = emoji);
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryPurple.withOpacity(0.1)
                            : AppColors.offWhite,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryPurple
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Color selection
              Text(
                'Vælg farve',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gray,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _colors.map((colorHex) {
                  final color = Color(
                    int.parse('FF${colorHex.replaceFirst('#', '')}', radix: 16),
                  );
                  final isSelected = _selectedColorHex == colorHex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColorHex = colorHex);
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color:
                              isSelected ? AppColors.black : Colors.transparent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(isEditing ? AppStrings.save : AppStrings.add),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final store = widget.existingStore != null
        ? widget.existingStore!.copyWith(
            name: _nameController.text.trim(),
            colorHex: _selectedColorHex,
            emoji: _selectedEmoji,
          )
        : Store.create(
            name: _nameController.text.trim(),
            colorHex: _selectedColorHex,
            emoji: _selectedEmoji,
            sortOrder: 100, // Will be placed after default stores
          );

    Navigator.pop(context, store);
  }
}

/// Show the manage stores sheet
Future<void> showManageStoresSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => const ManageStoresSheet(),
    ),
  );
}
