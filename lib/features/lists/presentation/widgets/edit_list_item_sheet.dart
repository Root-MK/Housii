import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/models/list_item_model.dart';
import '../../data/lists_service.dart';
import '../providers/lists_providers.dart';
import 'rich_text_editor.dart';

/// Bottom sheet for editing an existing list item
class EditListItemSheet extends ConsumerStatefulWidget {
  final ListItemModel item;

  const EditListItemSheet({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<EditListItemSheet> createState() => _EditListItemSheetState();
}

class _EditListItemSheetState extends ConsumerState<EditListItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late String _details;
  late ItemImportance _importance;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _details = widget.item.details ?? '';
    _importance = widget.item.importance;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final home = ref.read(currentHomeProvider).valueOrNull;
      
      if (home == null) {
        throw Exception('Ingen aktiv bruger eller hjem');
      }

      final updatedItem = widget.item.copyWith(
        title: _titleController.text.trim(),
        details: _details.isNotEmpty ? _details : null,
        importance: _importance,
        updatedAt: DateTime.now(),
      );

      await ref.read(listsServiceProvider).updateItem(updatedItem);

      if (mounted) {
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(listByIdProvider(widget.item.listId));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rediger punkt',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (list != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                          ),
                          child: Text(
                            list.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Titel',
                      hintText: 'Indtast titel',
                      filled: true,
                      fillColor: AppColors.offWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Titel er påkrævet';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Importance selector
                  Text(
                    'Vigtighed',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ItemImportance.values.map((importance) {
                        final isSelected = importance == _importance;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(_getImportanceLabel(importance)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _importance = importance);
                              }
                            },
                            selectedColor: _getImportanceColor(importance).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected 
                                  ? _getImportanceColor(importance)
                                  : AppColors.gray,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Details field
                  Text(
                    'Detaljer (valgfrit)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RichTextEditor(
                    initialValue: _details,
                    onChanged: (value) => _details = value,
                    placeholder: 'Tilføj detaljer, noter, links...',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            ),
                          ),
                          child: const Text('Annuller'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(AppColors.white),
                                  ),
                                )
                              : const Text('Gem ændringer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getImportanceLabel(ItemImportance importance) {
    switch (importance) {
      case ItemImportance.low:
        return 'Lav';
      case ItemImportance.normal:
        return 'Normal';
      case ItemImportance.high:
        return 'Høj';
      case ItemImportance.urgent:
        return 'Urgent';
    }
  }

  Color _getImportanceColor(ItemImportance importance) {
    switch (importance) {
      case ItemImportance.low:
        return AppColors.gray;
      case ItemImportance.normal:
        return AppColors.darkGray;
      case ItemImportance.high:
        return AppColors.warning;
      case ItemImportance.urgent:
        return AppColors.error;
    }
  }
}
