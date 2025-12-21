import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../data/models/shopping_item.dart';
import '../../data/shopping_service.dart';
import '../providers/shopping_providers.dart';
import 'auto_close_date_range_picker.dart';

/// Bottom sheet for editing an existing shopping item
class EditShoppingItemSheet extends ConsumerStatefulWidget {
  final ShoppingItem item;

  const EditShoppingItemSheet({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<EditShoppingItemSheet> createState() =>
      _EditShoppingItemSheetState();
}

class _EditShoppingItemSheetState extends ConsumerState<EditShoppingItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _priceController;

  late String? _selectedStoreId;
  late bool _important;
  late bool _lookoutFor;
  late DateTime? _discountStart;
  late DateTime? _discountEnd;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _amountController = TextEditingController(
      text: widget.item.amount?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.item.price?.toStringAsFixed(2).replaceAll('.', ',') ?? '',
    );
    _selectedStoreId = widget.item.storeId;
    _important = widget.item.important;
    _lookoutFor = widget.item.lookoutFor;
    _discountStart = widget.item.discountStart;
    _discountEnd = widget.item.discountEnd;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleStoreSelected(String? storeId) {
    setState(() {
      _selectedStoreId = storeId;
      if (storeId != null) {
        _lookoutFor = false;
      }
    });
  }

  void _handleLookoutForChanged(bool value) {
    setState(() {
      _lookoutFor = value;
      if (value) {
        _selectedStoreId = null;
      }
    });
  }

  Future<void> _selectDiscountDates() async {
    final now = DateTime.now();
    final result = await showAutoCloseDateRangePicker(
      context: context,
      initialStart: _discountStart,
      initialEnd: _discountEnd,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (result != null) {
      setState(() {
        _discountStart = result.start;
        _discountEnd = result.end;
      });
    }
  }

  void _clearDiscountDates() {
    setState(() {
      _discountStart = null;
      _discountEnd = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedItem = widget.item.copyWith(
        name: _nameController.text.trim(),
        storeId: _selectedStoreId,
        clearStoreId: _selectedStoreId == null && widget.item.storeId != null,
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text.replaceAll(',', '.'))
            : null,
        clearPrice: _priceController.text.isEmpty && widget.item.price != null,
        amount: _amountController.text.isNotEmpty
            ? int.tryParse(_amountController.text)
            : null,
        clearAmount:
            _amountController.text.isEmpty && widget.item.amount != null,
        important: _important,
        lookoutFor: _lookoutFor,
        discountStart: _discountStart,
        clearDiscountStart:
            _discountStart == null && widget.item.discountStart != null,
        discountEnd: _discountEnd,
        clearDiscountEnd:
            _discountEnd == null && widget.item.discountEnd != null,
      );

      await ref.read(shoppingServiceProvider).updateItem(updatedItem);

      HapticFeedback.lightImpact();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.errorGeneric)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
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
                    AppStrings.editItem,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: AppStrings.itemName,
                      hintText: AppStrings.itemNameHint,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.errorRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Amount and Price row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            labelText: AppStrings.itemAmount,
                            hintText: '1',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d,.]')),
                          ],
                          decoration: InputDecoration(
                            labelText: AppStrings.itemPrice,
                            hintText: '0,00',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Store selection
                  Text(
                    AppStrings.selectStore,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Consumer(
                    builder: (context, ref, _) {
                      final stores =
                          ref.watch(storesProvider).valueOrNull ?? [];
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _buildStoreChip(null, AppStrings.noStore, null),
                          ...stores.map((store) => _buildStoreChip(
                              store.id, store.name, store.emoji)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Discount date range
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.discountPeriod,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                      if (_discountStart != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: _clearDiscountDates,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: _selectDiscountDates,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightGray),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            color: _discountStart != null
                                ? AppColors.primaryPurple
                                : AppColors.gray,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _discountStart != null && _discountEnd != null
                                ? '${DateFormat('d/M').format(_discountStart!)} - ${DateFormat('d/M').format(_discountEnd!)}'
                                : 'Vælg datoer',
                            style: TextStyle(
                              color: _discountStart != null
                                  ? AppColors.black
                                  : AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Important and Lookout toggles
                  Row(
                    children: [
                      Expanded(
                        child: _buildToggleOption(
                          icon: Icons.priority_high_rounded,
                          label: AppStrings.markImportant,
                          value: _important,
                          onChanged: (v) => setState(() => _important = v),
                          activeColor: AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildToggleOption(
                          icon: Icons.visibility_outlined,
                          label: AppStrings.lookoutFor,
                          value: _lookoutFor,
                          onChanged: _handleLookoutForChanged,
                          activeColor: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      onPressed: _isLoading ? null : _submit,
                      isLoading: _isLoading,
                      text: AppStrings.save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreChip(String? storeId, String label, String? emoji) {
    final isSelected = _selectedStoreId == storeId;

    return GestureDetector(
      onTap: () => _handleStoreSelected(storeId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.lightGray,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: value ? activeColor.withOpacity(0.1) : AppColors.white,
          border: Border.all(
            color: value ? activeColor : AppColors.lightGray,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? activeColor : AppColors.gray,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: value ? activeColor : AppColors.gray,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              color: value ? activeColor : AppColors.lightGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
