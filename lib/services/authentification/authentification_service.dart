
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fishkart/exceptions/firebaseauth/credential_actions_exceptions.dart';
import 'package:fishkart/exceptions/firebaseauth/reauth_exceptions.dart';
import 'package:fishkart/exceptions/firebaseauth/signin_exceptions.dart';
import 'package:fishkart/exceptions/firebaseauth/signup_exceptions.dart';
import 'package:fishkart/services/database/user_database_helper.dart';

class AuthentificationService {
  /// Returns sign-in methods for a given email (e.g. ['password'], ['google.com'], etc)
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    try {
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
      return methods;
    } catch (e) {
      return [];
    }
  }
  static const String USER_NOT_FOUND_EXCEPTION_CODE = "user-not-found";
  static const String WRONG_PASSWORD_EXCEPTION_CODE = "wrong-password";
  static const String TOO_MANY_REQUESTS_EXCEPTION_CODE = 'too-many-requests';
  static const String EMAIL_ALREADY_IN_USE_EXCEPTION_CODE =
      "email-already-in-use";
  static const String OPERATION_NOT_ALLOWED_EXCEPTION_CODE =
      "operation-not-allowed";
  static const String WEAK_PASSWORD_EXCEPTION_CODE = "weak-password";
  static const String USER_MISMATCH_EXCEPTION_CODE = "user-mismatch";
  static const String INVALID_CREDENTIALS_EXCEPTION_CODE = "invalid-credential";
  static const String INVALID_EMAIL_EXCEPTION_CODE = "invalid-email";
  static const String USER_DISABLED_EXCEPTION_CODE = "user-disabled";
  static const String INVALID_VERIFICATION_CODE_EXCEPTION_CODE =
      "invalid-verification-code";
  static const String INVALID_VERIFICATION_ID_EXCEPTION_CODE =
      "invalid-verification-id";
  static const String REQUIRES_RECENT_LOGIN_EXCEPTION_CODE =
      "requires-recent-login";

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthentificationService._privateConstructor();
  static final AuthentificationService _instance =
      AuthentificationService._privateConstructor();
  factory AuthentificationService() => _instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  User get currentUser => _firebaseAuth.currentUser!;

  bool get currentUserVerified {
    currentUser.reload();
    return currentUser.emailVerified;
  }

  Future<void> deleteUserAccount() async {
    await currentUser.delete();
    await signOut();
  }

  Future<void> sendVerificationEmailToCurrentUser() async {
    await currentUser.sendEmailVerification();
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      // Step 1: Try Firebase Auth sign-in
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        throw FirebaseSignInAuthUserNotVerifiedException();
      }

      // Step 2: Check Firestore users collection for userType
      final uid = userCredential.user!.uid;
      final userDoc = await UserDatabaseHelper().firestore
          .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
          .doc(uid)
          .get();
      final userType = userDoc.data()?['userType'];
      print('[DEBUG] userType for $uid: $userType');
      if (userDoc.exists && userType == 'customer') {
        return true;
      } else if (!userDoc.exists) {
        throw FirebaseSignInAuthException(message: 'No user profile found in database.');
      } else if (userType != 'customer') {
        throw FirebaseSignInAuthException(message: 'This account is not registered as a customer.');
      } else {
        throw FirebaseSignInAuthException(message: 'Unknown error during customer check.');
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case INVALID_EMAIL_EXCEPTION_CODE:
          throw FirebaseSignInAuthInvalidEmailException();
        case USER_DISABLED_EXCEPTION_CODE:
          throw FirebaseSignInAuthUserDisabledException();
        case USER_NOT_FOUND_EXCEPTION_CODE:
          throw FirebaseSignInAuthUserNotFoundException();
        case WRONG_PASSWORD_EXCEPTION_CODE:
          throw FirebaseSignInAuthWrongPasswordException();
        case TOO_MANY_REQUESTS_EXCEPTION_CODE:
          throw FirebaseTooManyRequestsException();
        default:
          throw FirebaseSignInAuthException(message: e.code);
      }
    }
  }

  Future<bool> signUp({required String email, required String password}) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
      }

      await UserDatabaseHelper().createNewUser(uid);
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case EMAIL_ALREADY_IN_USE_EXCEPTION_CODE:
          throw FirebaseSignUpAuthEmailAlreadyInUseException();
        case INVALID_EMAIL_EXCEPTION_CODE:
          throw FirebaseSignUpAuthInvalidEmailException();
        case OPERATION_NOT_ALLOWED_EXCEPTION_CODE:
          throw FirebaseSignUpAuthOperationNotAllowedException();
        case WEAK_PASSWORD_EXCEPTION_CODE:
          throw FirebaseSignUpAuthWeakPasswordException();
        default:
          throw FirebaseSignInAuthException(message: e.code);
      }
    }
  }

  // 🔵 Google Sign-In
  /// Returns true if login successful, false if user cancelled, and 'signup' if email not registered.
  Future<dynamic> signInWithGoogle() async {
    try {
      // Always prompt for account selection
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Ensure no cached account
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false; // user cancelled

      final String googleEmail = googleUser.email;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Check if user exists and is a customer, auto-login if so
      final userDoc = await UserDatabaseHelper().firestore
          .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
          .where('email', isEqualTo: googleEmail)
          .limit(1)
          .get();
      if (userDoc.docs.isEmpty) {
        return 'signup'; // Not registered, redirect to signup
      }
      final userType = userDoc.docs.first.data()['userType'];
      if (userType == 'customer') {
        // Auto-login with Google credential
        try {
          final userCredential = await FirebaseAuth.instance
              .signInWithCredential(credential);
          if (userCredential.user == null) return false;
          return true;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            return {
              'linkRequired': true,
              'email': googleEmail,
              'pendingCredential': credential,
            };
          } else if (e.code == 'user-disabled') {
            return 'disabled';
          } else {
            print("Google Sign-In error: $e");
            return false;
          }
        }
      } else {
        // Not a customer, redirect to signup
        return 'signup';
      }
    } catch (e) {
      print("Google Sign-In error: $e");
      return false;
    }
  }

  /// Call this after user enters password to link Google to existing account
  Future<bool> linkGoogleToPasswordAccount({
    required String email,
    required String password,
    required AuthCredential pendingCredential,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.linkWithCredential(pendingCredential);
      return true;
    } catch (e) {
      print("Linking Google to password account failed: $e");
      return false;
    }
  }

  // 🔵 Facebook Sign-In
  Future<bool> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) return false;

      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      if (userCredential.user == null) return false;
      // Check userType in Firestore
      final uid = userCredential.user!.uid;
      final userDoc = await UserDatabaseHelper().firestore
          .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
          .doc(uid)
          .get();
      final userType = userDoc.data()?['userType'];
      if (userType == 'customer') {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Facebook Sign-In error: $e");
      return false;
    }
  }

  Future<bool> signUpWithDisplayName({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      // Set display name immediately after user creation
      await userCredential.user!.updateDisplayName(displayName);

      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
      }

      // Create user profile in Firestore with display name
      await UserDatabaseHelper().createNewUserWithDisplayName(
        uid,
        displayName,
        email,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case EMAIL_ALREADY_IN_USE_EXCEPTION_CODE:
          throw FirebaseSignUpAuthEmailAlreadyInUseException();
        case INVALID_EMAIL_EXCEPTION_CODE:
          throw FirebaseSignUpAuthInvalidEmailException();
        case OPERATION_NOT_ALLOWED_EXCEPTION_CODE:
          throw FirebaseSignUpAuthOperationNotAllowedException();
        case WEAK_PASSWORD_EXCEPTION_CODE:
          throw FirebaseSignUpAuthWeakPasswordException();
        default:
          throw FirebaseSignInAuthException(message: e.code);
      }
    }
  }

  // New method to include phone number in signup
  Future<bool> signUpWithCompleteProfile({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber, 
  }) async {
    try {
      // Step 1: Register email in Firebase Authentication
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        return false;
      }
      final uid = user.uid;

      // Step 2: Update display name
      await user.updateDisplayName(displayName);

      // Step 3: Store user data in Firestore users collection with userType 'customer'
      await UserDatabaseHelper().firestore.collection(UserDatabaseHelper.USERS_COLLECTION_NAME).doc(uid).set({
        'displayName': displayName,
        'email': user.email ?? email,
        'phoneNumber': phoneNumber,
        'userType': 'customer',
        'favourite_products': <String>[],
        'display_picture': null,
      });

      // Step 4: Link password credential to Google account if Google sign-in
      final signInMethods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
      if (signInMethods.contains('google.com') && !signInMethods.contains('password')) {
        final passwordCredential = EmailAuthProvider.credential(email: email, password: password);
        try {
          await user.linkWithCredential(passwordCredential);
        } catch (e) {
          // Ignore if already linked or error
        }
      }

      // Step 5: Send verification email (after Firestore write)
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }

      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case EMAIL_ALREADY_IN_USE_EXCEPTION_CODE:
          // Custom error for already registered email
          throw FirebaseSignUpAuthEmailAlreadyInUseException();
        case INVALID_EMAIL_EXCEPTION_CODE:
          throw FirebaseSignUpAuthInvalidEmailException();
        case OPERATION_NOT_ALLOWED_EXCEPTION_CODE:
          throw FirebaseSignUpAuthOperationNotAllowedException();
        case WEAK_PASSWORD_EXCEPTION_CODE:
          throw FirebaseSignUpAuthWeakPasswordException();
        default:
          // Show clear error for already registered user
          if (e.code.contains('email-already-in-use')) {
            throw FirebaseSignUpAuthEmailAlreadyInUseException();
          }
          throw FirebaseSignInAuthException(message: e.code);
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPasswordForEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == USER_NOT_FOUND_EXCEPTION_CODE) {
        throw FirebaseCredentialActionAuthUserNotFoundException();
      } else {
        throw FirebaseCredentialActionAuthException(message: e.code);
      }
    }
  }

  Future<bool> changePasswordForCurrentUser({
    String? oldPassword,
    required String newPassword,
  }) async {
    try {
      bool verified = true;
      if (oldPassword != null) {
        verified = await verifyCurrentUserPassword(oldPassword);
      }

      if (verified) {
        await currentUser.updatePassword(newPassword);
        return true;
      } else {
        throw FirebaseReauthWrongPasswordException();
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case WEAK_PASSWORD_EXCEPTION_CODE:
          throw FirebaseCredentialActionAuthWeakPasswordException();
        case REQUIRES_RECENT_LOGIN_EXCEPTION_CODE:
          throw FirebaseCredentialActionAuthRequiresRecentLoginException();
        default:
          throw FirebaseCredentialActionAuthException(message: e.code);
      }
    }
  }

  Future<bool> changeEmailForCurrentUser({
    String? password,
    required String newEmail,
  }) async {
    try {
      bool verified = true;
      if (password != null) {
        verified = await verifyCurrentUserPassword(password);
      }

      if (verified) {
        await currentUser.verifyBeforeUpdateEmail(newEmail);
        return true;
      } else {
        throw FirebaseReauthWrongPasswordException();
      }
    } on FirebaseAuthException catch (e) {
      throw FirebaseCredentialActionAuthException(message: e.code);
    }
  }

  Future<bool> reauthCurrentUser(String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      await currentUser.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == WRONG_PASSWORD_EXCEPTION_CODE) {
        throw FirebaseSignInAuthWrongPasswordException();
      } else {
        throw FirebaseSignInAuthException(message: e.code);
      }
    }
  }

  Future<bool> verifyCurrentUserPassword(String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      final result = await currentUser.reauthenticateWithCredential(credential);
      return result.user != null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case USER_MISMATCH_EXCEPTION_CODE:
          throw FirebaseReauthUserMismatchException();
        case USER_NOT_FOUND_EXCEPTION_CODE:
          throw FirebaseReauthUserNotFoundException();
        case INVALID_CREDENTIALS_EXCEPTION_CODE:
          throw FirebaseReauthInvalidCredentialException();
        case INVALID_EMAIL_EXCEPTION_CODE:
          throw FirebaseReauthInvalidEmailException();
        case WRONG_PASSWORD_EXCEPTION_CODE:
          throw FirebaseReauthWrongPasswordException();
        case INVALID_VERIFICATION_CODE_EXCEPTION_CODE:
          throw FirebaseReauthInvalidVerificationCodeException();
        case INVALID_VERIFICATION_ID_EXCEPTION_CODE:
          throw FirebaseReauthInvalidVerificationIdException();
        default:
          throw FirebaseReauthException(message: e.code);
      }
    }
  }

  Future<void> updateCurrentUserDisplayName(String updatedDisplayName) async {
    await currentUser.updateDisplayName(updatedDisplayName);
  }
}
