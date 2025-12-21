import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth state provider - streams Firebase auth state
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current user provider - streams user model from Firestore
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final authService = ref.watch(authServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return authService.userModelStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Auth actions provider
final authActionsProvider = Provider<AuthActions>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthActions(authService);
});

/// Result of sign-in attempt
enum SignInResultType {
  success,
  cancelled,
  blocked,
  error,
}

class SignInResult {
  final SignInResultType type;
  final String? email;
  final String? errorMessage;

  SignInResult({
    required this.type,
    this.email,
    this.errorMessage,
  });
}

/// Auth actions class for login/logout
class AuthActions {
  final AuthService _authService;

  AuthActions(this._authService);

  /// Initiate Google Sign-In - new users are registered automatically
  /// but need admin approval (admin_accepted) to access data
  Future<SignInResult> initiateGoogleSignIn() async {
    try {
      final checkResult = await _authService.preCheckGoogleSignIn();

      if (checkResult.errorMessage != null && !checkResult.userExists) {
        return SignInResult(
          type: checkResult.isBlocked
              ? SignInResultType.blocked
              : SignInResultType.error,
          email: checkResult.email,
          errorMessage: checkResult.errorMessage,
        );
      }

      if (checkResult.userExists) {
        // User signed in successfully (existing or newly registered)
        return SignInResult(
          type: SignInResultType.success,
          email: checkResult.email,
        );
      }

      if (checkResult.isBlocked) {
        return SignInResult(
          type: SignInResultType.blocked,
          email: checkResult.email,
          errorMessage: 'Denne email er blokeret fra registrering',
        );
      }

      // Should not reach here with new flow
      return SignInResult(
        type: SignInResultType.error,
        email: checkResult.email,
        errorMessage: 'Uventet fejl ved login',
      );
    } catch (e) {
      debugPrint('❌ initiateGoogleSignIn error: $e');
      return SignInResult(
        type: SignInResultType.error,
        errorMessage: 'Login fejlede: $e',
      );
    }
  }

  /// Legacy sign in (for backwards compatibility)
  Future<bool> signInWithGoogle() async {
    try {
      final result = await _authService.signInWithGoogle();
      return result != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
