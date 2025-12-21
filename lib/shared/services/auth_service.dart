import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/user_model.dart';

/// The secret passcode for new user registration
const String _registrationPasscode = 'Qt56vvdew4!';

/// Firebase Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Result of checking if a user can sign up
class SignUpCheckResult {
  final bool userExists;
  final bool isBlocked;
  final String? email;
  final String? errorMessage;

  SignUpCheckResult({
    required this.userExists,
    required this.isBlocked,
    this.email,
    this.errorMessage,
  });
}

/// Auth Service for Firebase Authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Check if an email is blocked from registration
  Future<bool> isEmailBlocked(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    final doc = await _firestore
        .collection('blocked_signups')
        .doc(normalizedEmail)
        .get();
    return doc.exists && (doc.data()?['blocked'] == true);
  }

  /// Check if registration is currently open (controlled from Firebase Console)
  /// Go to Firestore > app_config > settings > set registration_open = true/false
  Future<bool> isRegistrationOpen() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('settings')
          .get();
      
      if (!doc.exists) {
        // If document doesn't exist, default to OPEN for simplicity
        // Admin approval (admin_accepted) still protects data access
        debugPrint('⚠️ app_config/settings not found - registration open by default');
        return true;
      }
      
      final isOpen = doc.data()?['registration_open'] == true;
      debugPrint('📝 Registration open: $isOpen');
      return isOpen;
    } catch (e) {
      debugPrint('❌ Error checking registration status: $e');
      return true; // Default to open on error (admin approval still required)
    }
  }

  /// Get failed attempts count for an email
  Future<int> getFailedAttempts(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    final doc = await _firestore
        .collection('blocked_signups')
        .doc(normalizedEmail)
        .get();
    if (!doc.exists) return 0;
    return doc.data()?['failedAttempts'] ?? 0;
  }

  /// Record a failed passcode attempt
  Future<bool> recordFailedAttempt(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    final docRef =
        _firestore.collection('blocked_signups').doc(normalizedEmail);

    final doc = await docRef.get();
    final currentAttempts =
        doc.exists ? (doc.data()?['failedAttempts'] ?? 0) : 0;
    final newAttempts = currentAttempts + 1;
    final shouldBlock = newAttempts >= 3;

    await docRef.set({
      'email': normalizedEmail,
      'failedAttempts': newAttempts,
      'blocked': shouldBlock,
      'lastAttempt': Timestamp.now(),
      'blockedAt': shouldBlock ? Timestamp.now() : null,
    }, SetOptions(merge: true));

    debugPrint(
        '🔒 Failed attempt #$newAttempts for $normalizedEmail, blocked: $shouldBlock');
    return shouldBlock;
  }

  /// Verify the registration passcode
  bool verifyPasscode(String passcode) {
    return passcode == _registrationPasscode;
  }

  /// Check if user exists in Firestore (without signing them in)
  Future<bool> checkUserExists(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  /// Pre-check before Google Sign-In: get email and check status
  /// Returns the email and whether user exists/is blocked
  Future<SignUpCheckResult> preCheckGoogleSignIn() async {
    try {
      String? email;

      if (kIsWeb) {
        // On web, we need to initiate OAuth to get the email
        // We'll use a temporary sign-in and then sign out if needed
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final userCredential = await _auth.signInWithPopup(googleProvider);
        email = userCredential.user?.email;

        if (email == null) {
          await _auth.signOut();
          return SignUpCheckResult(
            userExists: false,
            isBlocked: false,
            errorMessage: 'Kunne ikke hente email fra Google',
          );
        }

        // Check if user already exists in our users collection
        final userExists = await checkUserExists(email);

        if (userExists) {
          // User exists, complete the sign-in
          await _createOrUpdateUser(userCredential.user!);
          return SignUpCheckResult(
            userExists: true,
            isBlocked: false,
            email: email,
          );
        }

        // New user - check if registration is open
        final registrationOpen = await isRegistrationOpen();
        if (!registrationOpen) {
          // Sign out the temporary auth
          await _auth.signOut();
          return SignUpCheckResult(
            userExists: false,
            isBlocked: false,
            email: email,
            errorMessage: 'Registrering er lukket. Kontakt administrator.',
          );
        }

        // New user, registration open - complete registration (no passcode needed)
        // User will need admin approval (admin_accepted) to access data
        await _createOrUpdateUser(userCredential.user!);
        return SignUpCheckResult(
          userExists: true,
          isBlocked: false,
          email: email,
        );
      } else {
        // Native: Use Google Sign-In to get email without Firebase auth
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return SignUpCheckResult(
            userExists: false,
            isBlocked: false,
            errorMessage: 'Login annulleret',
          );
        }

        email = googleUser.email;

        // Check if user exists
        final userExists = await checkUserExists(email);

        if (userExists) {
          // Complete the sign-in for existing user
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          final userCredential = await _auth.signInWithCredential(credential);
          await _createOrUpdateUser(userCredential.user!);
          return SignUpCheckResult(
            userExists: true,
            isBlocked: false,
            email: email,
          );
        }

        // New user - check if registration is open
        final registrationOpen = await isRegistrationOpen();
        if (!registrationOpen) {
          await _googleSignIn.signOut();
          return SignUpCheckResult(
            userExists: false,
            isBlocked: false,
            email: email,
            errorMessage: 'Registrering er lukket. Kontakt administrator.',
          );
        }

        // New user, registration open - complete registration (no passcode needed)
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await _auth.signInWithCredential(credential);
        await _createOrUpdateUser(userCredential.user!);
        return SignUpCheckResult(
          userExists: true,
          isBlocked: false,
          email: email,
        );
      }
    } catch (e) {
      debugPrint('❌ preCheckGoogleSignIn error: $e');
      return SignUpCheckResult(
        userExists: false,
        isBlocked: false,
        errorMessage: 'Login fejlede: $e',
      );
    }
  }

  /// Complete registration after passcode verification (for new users)
  /// Note: Passcode check removed - users just need admin approval now
  Future<UserCredential?> completeNewUserRegistration() async {
    try {
      if (kIsWeb) {
        return await _signInWithGoogleWeb();
      } else {
        return await _signInWithGoogleNative();
      }
    } catch (e) {
      debugPrint('❌ completeNewUserRegistration error: $e');
      rethrow;
    }
  }

  /// Sign in with Google (legacy - now used internally)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return await _signInWithGoogleWeb();
      } else {
        return await _signInWithGoogleNative();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Google on Web using Firebase Auth directly
  Future<UserCredential?> _signInWithGoogleWeb() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    // Use signInWithPopup for web
    final userCredential = await _auth.signInWithPopup(googleProvider);

    // Create or update user document in Firestore
    if (userCredential.user != null) {
      await _createOrUpdateUser(userCredential.user!);
    }

    return userCredential;
  }

  /// Sign in with Google on Native (iOS/Android)
  Future<UserCredential?> _signInWithGoogleNative() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      return null; // User cancelled
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    final userCredential = await _auth.signInWithCredential(credential);

    // Create or update user document in Firestore
    await _createOrUpdateUser(userCredential.user!);

    return userCredential;
  }

  /// Create or update user document in Firestore
  Future<void> _createOrUpdateUser(User firebaseUser) async {
    debugPrint('🔥 _createOrUpdateUser called for: ${firebaseUser.email}');
    debugPrint('🔥 User UID: ${firebaseUser.uid}');
    
    try {
      final userRef = _firestore.collection('users').doc(firebaseUser.uid);
      
      // First try to get existing doc to preserve admin_accepted
      DocumentSnapshot? existingDoc;
      try {
        existingDoc = await userRef.get();
        debugPrint('🔥 Existing doc found: ${existingDoc.exists}');
      } catch (e) {
        debugPrint('⚠️ Could not read existing doc (expected for new users): $e');
      }

      if (existingDoc != null && existingDoc.exists) {
        // Update existing user (preserve admin_accepted)
        debugPrint('🔥 Updating existing user document...');
        await userRef.update({
          'displayName': firebaseUser.displayName ?? '',
          'photoUrl': firebaseUser.photoURL,
          'updatedAt': Timestamp.now(),
        });
        debugPrint('✅ User document updated successfully!');
      } else {
        // Create new user - use set (not update)
        debugPrint('🔥 Creating new user document...');
        final userData = {
          'id': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'displayName': firebaseUser.displayName ?? '',
          'photoUrl': firebaseUser.photoURL,
          'admin_accepted': false,
          'currentHomeId': null,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };
        debugPrint('🔥 User data: $userData');
        await userRef.set(userData);
        debugPrint('✅ User document created successfully!');
      }
    } catch (e, stack) {
      debugPrint('❌ Error in _createOrUpdateUser: $e');
      debugPrint('❌ Stack: $stack');
      // Don't rethrow - let the user continue even if Firestore write fails
      // They'll just see pending approval screen
    }
  }

  /// Get user model from Firestore
  Future<UserModel?> getUserModel(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Stream of user model changes
  Stream<UserModel?> userModelStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// Update user's current home
  Future<void> updateCurrentHome(String userId, String? homeId) async {
    await _firestore.collection('users').doc(userId).update({
      'currentHomeId': homeId,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
