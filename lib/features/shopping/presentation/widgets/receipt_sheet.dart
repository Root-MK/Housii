import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/models/shopping_item.dart';
import '../../data/models/store.dart';
import '../../data/shopping_service.dart';
import '../providers/shopping_providers.dart';

class ReceiptSheet extends ConsumerStatefulWidget {
  const ReceiptSheet({super.key});

  @override
  ConsumerState<ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends ConsumerState<ReceiptSheet> {
  Store? _selectedStore;
  List<ShoppingItem> _items = [];
  bool _isLoading = true;
  Map<String, List<ShoppingItem>> _itemsByStore = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null) return;

    final items = await ref.read(shoppingServiceProvider).getCompletedItemsForToday(home.id);
    final stores = ref.read(storesProvider).valueOrNull ?? [];

    final grouped = <String, List<ShoppingItem>>{};
    for (final item in items) {
      final key = item.storeId ?? 'no_store';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    if (mounted) {
      setState(() {
        _itemsByStore = grouped;
        _isLoading = false;
        
        // If only one store has items, select it automatically
        if (grouped.length == 1) {
          final storeId = grouped.keys.first;
          if (storeId == 'no_store') {
            _selectedStore = null; // Represents "Valgfri butik"
          } else {
            _selectedStore = stores.firstWhere((s) => s.id == storeId, orElse: () => Store(
              id: storeId,
              name: 'Ukendt butik',
              colorHex: '#808080',
              sortOrder: 0,
              isDefault: false,
              createdAt: DateTime.now(),
            ));
          }
          _items = grouped[storeId]!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _itemsByStore.isEmpty
                  ? _buildEmptyState()
                  : _selectedStore == null && _items.isEmpty && _itemsByStore.length > 1
                      ? _buildStoreSelection()
                      : _buildReceipt(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.lightGray),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Ingen kvitteringer for i dag',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.gray),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildStoreSelection() {
    final stores = ref.read(storesProvider).valueOrNull ?? [];
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vælg butik for kvittering',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._itemsByStore.keys.map((storeId) {
          final Store? store = storeId == 'no_store' 
              ? null 
              : stores.firstWhere((s) => s.id == storeId, orElse: () => throw Exception('Store not found'));
          
          return ListTile(
            leading: Text(store?.emoji ?? '🏪', style: const TextStyle(fontSize: 24)),
            title: Text(store?.name ?? 'Valgfri butik'),
            subtitle: Text('${_itemsByStore[storeId]!.length} varer'),
            onTap: () {
              setState(() {
                _selectedStore = store;
                _items = _itemsByStore[storeId]!;
              });
            },
          );
        }),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildReceipt() {
    double totalSum = 0;
    for (final item in _items) {
      totalSum += (item.price ?? 0) * (item.amount ?? 1);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back button if multiple stores
        if (_itemsByStore.length > 1)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedStore = null;
                  _items = [];
                });
              },
            ),
          ),
        
        // The Receipt UI
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFD),
            border: Border.all(color: AppColors.lightGray),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                (_selectedStore?.name ?? 'VALGFRI BUTIK').toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Text(
                'KONTANT KVITTERING',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                '********************************',
                style: TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // Items
              ..._items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name.toUpperCase(),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                          ),
                        ),
                        Text(
                          item.price != null 
                              ? '${((item.price ?? 0) * (item.amount ?? 1)).toStringAsFixed(2)}' 
                              : '-',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        ),
                      ],
                    ),
                    if (item.price != null && (item.amount ?? 1) > 1)
                      Text(
                        '  ${item.amount} X ${item.price?.toStringAsFixed(2)}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.gray),
                      ),
                  ],
                ),
              )),
              
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '********************************',
                style: TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${totalSum.toStringAsFixed(2)} DKK',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'TAK FOR I DAG!',
                style: TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'HOUSII - DIN HJEMMEHJÆLP',
                style: TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
          child: const Text('LUK'),
        ),
      ],
    );
  }
}
