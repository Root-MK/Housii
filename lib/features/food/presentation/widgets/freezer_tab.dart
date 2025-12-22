import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/food_service.dart';
import '../../data/models/freezer_item_model.dart';
import '../../data/models/food_emoji.dart';
import '../providers/food_providers.dart';

/// Tab 3: Freezer Status - list of freezer items
class FreezerTab extends ConsumerWidget {
  const FreezerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(freezerItemsProvider);

    return itemsAsync.when(
      data: (items) {
        final totalQuantity = items.fold(0.0, (sum, item) => sum + item.quantity);
        final activeItemsCount = items.where((item) => item.quantity > 0).length;
        
        final formattedTotal = totalQuantity.toStringAsFixed(
            totalQuantity.truncateToDouble() == totalQuantity ? 0 : 1);

        return Column(
          children: [
            // Stats Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total mængde',
                      value: formattedTotal,
                      icon: Icons.scale,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      label: 'Varer på lager',
                      value: activeItemsCount.toString(),
                      icon: Icons.inventory_2,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.kitchen,
                            size: 64,
                            color: AppColors.lightGray,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Ingen varer i fryseren',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Tryk + for at tilføje en vare',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _FreezerItemCard(item: item);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fejl: $e')),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreezerItemCard extends ConsumerWidget {
  final FreezerItemModel item;

  const _FreezerItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEmpty = item.isEmpty;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context, ref),
      child: Opacity(
        opacity: isEmpty ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: isEmpty ? AppColors.lightGray : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.lightGray,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isEmpty
                      ? AppColors.lightGray
                      : AppColors.primaryPurpleSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item.emoji.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isEmpty ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tilføjet ${_formatDate(item.addedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isEmpty
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.accentGreenSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.formattedQuantity,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isEmpty ? AppColors.error : AppColors.accentGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'i dag';
    if (diff == 1) return 'i går';
    if (diff < 7) return 'for $diff dage siden';
    if (diff < 30) return 'for ${diff ~/ 7} uger siden';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FreezerContextMenu(item: item),
    );
  }
}

class _FreezerContextMenu extends ConsumerStatefulWidget {
  final FreezerItemModel item;

  const _FreezerContextMenu({required this.item});

  @override
  ConsumerState<_FreezerContextMenu> createState() => _FreezerContextMenuState();
}

class _FreezerContextMenuState extends ConsumerState<_FreezerContextMenu> {
  double _quantityChange = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Text(
                  widget.item.emoji.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Beholdning: ${widget.item.formattedQuantity}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Quantity change slider
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antal: ${_quantityChange.toStringAsFixed(_quantityChange.truncateToDouble() == _quantityChange ? 0 : 1)} ${widget.item.unit.abbreviation}',
                  style: theme.textTheme.titleSmall,
                ),
                Slider(
                  value: _quantityChange,
                  min: 0.5,
                  max: 10,
                  divisions: 19,
                  onChanged: (value) => setState(() => _quantityChange = value),
                  activeColor: AppColors.primaryPurple,
                ),
              ],
            ),
          ),
          // Actions - Reduce first, then add, then others
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.remove, color: AppColors.warning),
            ),
            title: const Text('Reducer mængde'),
            subtitle: Text('Fjern $_formattedQuantityChange fra beholdning'),
            onTap: () => _reduceQuantity(context),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: AppColors.accentGreen),
            ),
            title: const Text('Tilføj mængde'),
            subtitle: Text('Tilføj $_formattedQuantityChange til beholdning'),
            onTap: () => _addQuantity(context),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit, color: AppColors.primaryPurple),
            ),
            title: const Text('Rediger'),
            onTap: () => _editItem(context),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete, color: AppColors.error),
            ),
            title: const Text('Slet'),
            onTap: () => _deleteItem(context),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }

  String get _formattedQuantityChange =>
      '${_quantityChange.toStringAsFixed(_quantityChange.truncateToDouble() == _quantityChange ? 0 : 1)} ${widget.item.unit.abbreviation}';

  Future<void> _reduceQuantity(BuildContext context) async {
    final home = ref.read(currentHomeProvider).value;
    if (home == null) return;

    await ref.read(foodServiceProvider).reduceQuantity(
      home.id,
      widget.item.id,
      _quantityChange,
    );

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reduceret $_formattedQuantityChange fra ${widget.item.name}'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _addQuantity(BuildContext context) async {
    final home = ref.read(currentHomeProvider).value;
    if (home == null) return;

    await ref.read(foodServiceProvider).addQuantity(
      home.id,
      widget.item.id,
      _quantityChange,
    );

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tilføjet $_formattedQuantityChange til ${widget.item.name}'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }

  void _editItem(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditFreezerItemSheet(item: widget.item),
    );
  }

  Future<void> _deleteItem(BuildContext context) async {
    Navigator.pop(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet vare'),
        content: Text('Vil du slette "${widget.item.name}" fra fryseren?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Slet',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final home = ref.read(currentHomeProvider).value;
      if (home != null) {
        await ref.read(foodServiceProvider).deleteFreezerItem(home.id, widget.item.id);
      }
    }
  }
}

class _EditFreezerItemSheet extends ConsumerStatefulWidget {
  final FreezerItemModel item;

  const _EditFreezerItemSheet({required this.item});

  @override
  ConsumerState<_EditFreezerItemSheet> createState() => _EditFreezerItemSheetState();
}

class _EditFreezerItemSheetState extends ConsumerState<_EditFreezerItemSheet> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late FoodEmoji _selectedEmoji;
  late QuantityUnit _selectedUnit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(
      text: widget.item.quantity.toStringAsFixed(
        widget.item.quantity.truncateToDouble() == widget.item.quantity ? 0 : 1,
      ),
    );
    _selectedEmoji = widget.item.emoji;
    _selectedUnit = widget.item.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
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
            Text(
              'Rediger fryservare',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Navn',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Quantity and unit row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Mængde',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<QuantityUnit>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Enhed',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: QuantityUnit.values.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedUnit = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Emoji selector
            Text(
              'Ikon',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: FoodEmoji.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final emoji = FoodEmoji.values[index];
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryPurple
                            : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.primaryPurple, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          emoji.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Gem ændringer'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final quantity = double.tryParse(_quantityController.text) ?? widget.item.quantity;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Navn er påkrævet'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final home = ref.read(currentHomeProvider).value;
    if (home == null) return;

    final updated = widget.item.copyWith(
      name: name,
      quantity: quantity,
      unit: _selectedUnit,
      emoji: _selectedEmoji,
    );

    await ref.read(foodServiceProvider).updateFreezerItem(updated);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name opdateret'),
          backgroundColor: AppColors.primaryPurple,
        ),
      );
    }
  }
}
