import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/list_model.dart';
import '../../data/models/list_item_model.dart';
import '../../data/lists_service.dart';
import 'rich_text_editor.dart';

/// Bottom sheet for adding a new item to a list
class AddListItemSheet extends ConsumerStatefulWidget {
  final ListModel list;

  const AddListItemSheet({
    super.key,
    required this.list,
  });

  @override
  ConsumerState<AddListItemSheet> createState() => _AddListItemSheetState();
}

class _AddListItemSheetState extends ConsumerState<AddListItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String _details = '';
  ItemImportance _importance = ItemImportance.normal;
  bool _isSubmitting = false;

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
      final user = ref.read(currentUserProvider).valueOrNull;
      
      if (home == null || user == null) {
        throw Exception('Ingen aktiv bruger eller hjem');
      }

      final listsService = ref.read(listsServiceProvider);
      
      // Get next sort order
      final sortOrder = await listsService.getNextSortOrder(home.id, widget.list.id);

      final item = ListItemModel.create(
        listId: widget.list.id,
        homeId: home.id,
        title: _titleController.text.trim(),
        details: _details.isNotEmpty ? _details : null,
        importance: _importance,
        sortOrder: sortOrder,
        createdBy: user.id,
      );

      await listsService.addItem(item);

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
                  Text(
                    'Tilføj punkt til "${widget.list.name}"',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    autofocus: true,
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
                  Row(
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
                  
                  // Submit button
                  SizedBox(
                    width: double.infinity,
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
                          : const Text('Tilføj punkt'),
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
