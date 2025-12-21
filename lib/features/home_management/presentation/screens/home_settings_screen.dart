import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/home_provider.dart';

/// Home settings screen
class HomeSettingsScreen extends ConsumerWidget {
  const HomeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(currentHomeProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(AppStrings.homeSettings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: homeAsync.when(
        data: (home) {
          if (home == null) {
            return const Center(child: Text(AppStrings.homeNotFound));
          }

          final user = userAsync.value;
          final isOwner = user != null && home.isOwner(user.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Home name
                Text(
                  AppStrings.homeName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  home.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Join code (only for owner)
                if (isOwner) ...[
                  Text(
                    AppStrings.joinCode,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            home.formattedJoinCode,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.primaryPurple),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: home.formattedJoinCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppStrings.codeCopied)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                ],
                
                // Members
                Text(
                  AppStrings.members,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // Members list
                ref.watch(homeMembersProvider(home.id)).when(
                  data: (members) => Column(
                    children: members.map((member) => _MemberTile(
                      name: member['displayName'] ?? '',
                      email: member['email'] ?? '',
                      isOwner: member['isOwner'] ?? false,
                      photoUrl: member['photoUrl'],
                    )).toList(),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text(AppStrings.errorGeneric),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Actions
                if (!isOwner)
                  SecondaryButton(
                    text: AppStrings.leaveHome,
                    icon: Icons.exit_to_app,
                    width: double.infinity,
                    onPressed: () => _showLeaveDialog(context, ref, home.id, user!.id),
                  ),
                
                if (isOwner && home.memberIds.length == 1)
                  SecondaryButton(
                    text: AppStrings.deleteHome,
                    icon: Icons.delete_outline,
                    width: double.infinity,
                    onPressed: () => _showDeleteDialog(context, ref, home.id, user.id),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text(AppStrings.errorGeneric)),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref, String homeId, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.leaveHome),
        content: const Text(AppStrings.leaveHomeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final homeActions = ref.read(homeActionsProvider);
              await homeActions.leaveHome(homeId: homeId, userId: userId);
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String homeId, String ownerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteHome),
        content: const Text(AppStrings.deleteHomeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final homeActions = ref.read(homeActionsProvider);
              await homeActions.deleteHome(homeId: homeId, ownerId: ownerId);
            },
            child: Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String name;
  final String email;
  final bool isOwner;
  final String? photoUrl;

  const _MemberTile({
    required this.name,
    required this.email,
    required this.isOwner,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryPurpleSubtle,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleSubtle,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                AppStrings.owner,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
