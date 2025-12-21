import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/models/list_model.dart';
import '../../data/lists_service.dart';
import '../providers/lists_providers.dart';

/// Bottom sheet for creating a new list
class AddListSheet extends ConsumerStatefulWidget {
  const AddListSheet({super.key});

  @override
  ConsumerState<AddListSheet> createState() => _AddListSheetState();
}

class _AddListSheetState extends ConsumerState<AddListSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  ListType _type = ListType.checklist;
  ListVisibility _visibility = ListVisibility.household;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
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

      final list = ListModel.create(
        name: _nameController.text.trim(),
        type: _type,
        visibility: _visibility,
        homeId: home.id,
        createdBy: user.id,
      );

      await ref.read(listsServiceProvider).createList(list);

      // Select the new list
      ref.read(selectedListIdProvider.notifier).state = list.id;

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
                    'Opret ny liste',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Listenavn',
                      hintText: 'Indtast navn på listen',
                      filled: true,
                      fillColor: AppColors.offWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Navn er påkrævet';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // List type selector
                  Text(
                    'Listetype',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeOption(
                          icon: Icons.checklist,
                          label: 'Tjekliste',
                          description: 'Med afkrydsningsfelter',
                          isSelected: _type == ListType.checklist,
                          onTap: () => setState(() => _type = ListType.checklist),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _TypeOption(
                          icon: Icons.list,
                          label: 'Standard',
                          description: 'Simpel liste',
                          isSelected: _type == ListType.defaultList,
                          onTap: () => setState(() => _type = ListType.defaultList),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Visibility selector
                  Text(
                    'Synlighed',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeOption(
                          icon: Icons.group,
                          label: 'Husstand',
                          description: 'Alle kan se og redigere',
                          isSelected: _visibility == ListVisibility.household,
                          onTap: () => setState(() => _visibility = ListVisibility.household),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _TypeOption(
                          icon: Icons.person,
                          label: 'Personlig',
                          description: 'Kun dig selv',
                          isSelected: _visibility == ListVisibility.personal,
                          onTap: () => setState(() => _visibility = ListVisibility.personal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
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
                          : const Text('Opret liste'),
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
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurpleSubtle : AppColors.offWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.lightGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryPurple : AppColors.gray,
              size: 24,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isSelected ? AppColors.primaryPurple : AppColors.darkGray,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
