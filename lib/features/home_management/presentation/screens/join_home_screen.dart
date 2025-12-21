import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/home_provider.dart';

/// Screen for joining an existing home
class JoinHomeScreen extends ConsumerStatefulWidget {
  const JoinHomeScreen({super.key});

  @override
  ConsumerState<JoinHomeScreen> createState() => _JoinHomeScreenState();
}

class _JoinHomeScreenState extends ConsumerState<JoinHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinHome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('User not found');

      final homeActions = ref.read(homeActionsProvider);
      final home = await homeActions.joinHomeByCode(
        joinCode: _codeController.text.trim(),
        userId: user.id,
      );

      if (home == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.invalidJoinCode)),
          );
        }
      }
      // Navigation will be handled by router redirect
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.error}: $e')),
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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  AppStrings.joinHome,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Indtast koden du har fået fra hjemmets ejer.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.gray,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Code input
                Text(
                  AppStrings.joinCode,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: AppStrings.joinCodeHint,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.errorRequired;
                    }
                    // Remove dashes and check length
                    final cleanCode = value.replaceAll('-', '');
                    if (cleanCode.length != 16) {
                      return AppStrings.invalidJoinCode;
                    }
                    return null;
                  },
                ),
                
                const Spacer(),
                
                // Join button
                PrimaryButton(
                  text: AppStrings.join,
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _joinHome,
                ),
                
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
