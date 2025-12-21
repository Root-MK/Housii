import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../shared/providers/auth_provider.dart';

/// Screen shown when user is logged in but not yet approved by admin
class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _isCreatingUser = false;
  String? _statusMessage;
  bool _userExistsInFirestore = false;

  @override
  void initState() {
    super.initState();
    _checkAndCreateUser();
  }

  Future<void> _checkAndCreateUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isCreatingUser = true;
      _statusMessage = 'Tjekker bruger status...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);
      
      // Check if user document exists
      final doc = await userRef.get();
      
      if (doc.exists) {
        setState(() {
          _userExistsInFirestore = true;
          _statusMessage = 'Venter på admin godkendelse...';
          _isCreatingUser = false;
        });
        return;
      }

      // User doesn't exist - create them
      setState(() => _statusMessage = 'Opretter bruger profil...');
      
      final userData = {
        'id': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL,
        'admin_accepted': false,
        'currentHomeId': null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };
      
      await userRef.set(userData);
      
      setState(() {
        _userExistsInFirestore = true;
        _statusMessage = 'Bruger oprettet! Venter på admin godkendelse...';
        _isCreatingUser = false;
      });
      
      debugPrint('✅ User created from pending approval screen');
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
      setState(() {
        _statusMessage = 'Fejl: $e';
        _isCreatingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              
              // Waiting icon and message
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _userExistsInFirestore 
                          ? AppColors.primaryPurpleSubtle 
                          : AppColors.lightGray,
                      shape: BoxShape.circle,
                    ),
                    child: _isCreatingUser
                        ? const CircularProgressIndicator()
                        : Icon(
                            _userExistsInFirestore 
                                ? Icons.hourglass_top_rounded
                                : Icons.error_outline,
                            size: 56,
                            color: _userExistsInFirestore 
                                ? AppColors.primaryPurple
                                : AppColors.error,
                          ),
                  )
                      .animate(
                        onPlay: (controller) => controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 1500.ms,
                      ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  Text(
                    _userExistsInFirestore 
                        ? AppStrings.pendingApproval
                        : 'Opretter profil...',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  if (_statusMessage != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: _statusMessage!.contains('Fejl') 
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.primaryPurpleSubtle,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _statusMessage!.contains('Fejl') 
                              ? AppColors.error
                              : AppColors.primaryPurple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  if (_userExistsInFirestore) ...[
                    Text(
                      AppStrings.pendingApprovalDesc,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.gray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    Text(
                      AppStrings.pendingApprovalHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              )
                  .animate()
                  .fadeIn(duration: 500.ms),
              
              const Spacer(),
              
              // Retry button if user creation failed
              if (!_userExistsInFirestore && !_isCreatingUser)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: PrimaryButton(
                    text: 'Prøv igen',
                    icon: Icons.refresh,
                    width: double.infinity,
                    onPressed: _checkAndCreateUser,
                  ),
                ),
              
              // Logout button
              SecondaryButton(
                text: AppStrings.logout,
                icon: Icons.logout,
                width: double.infinity,
                onPressed: () async {
                  final authActions = ref.read(authActionsProvider);
                  await authActions.signOut();
                },
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
