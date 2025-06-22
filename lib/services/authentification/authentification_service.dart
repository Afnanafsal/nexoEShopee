import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nexoeshopee/exceptions/firebaseauth/credential_actions_exceptions.dart';
import 'package:nexoeshopee/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';
import 'package:nexoeshopee/exceptions/firebaseauth/reauth_exceptions.dart';
import 'package:nexoeshopee/exceptions/firebaseauth/signin_exceptions.dart';
import 'package:nexoeshopee/exceptions/firebaseauth/signup_exceptions.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';

class AuthentificationService {
  static const String USER_NOT_FOUND_EXCEPTION_CODE = "user-not-found";
  static const String WRONG_PASSWORD_EXCEPTION_CODE = "wrong-password";
  static const String TOO_MANY_REQUESTS_EXCEPTION_CODE = 'too-many-requests';
  static const String EMAIL_ALREADY_IN_USE_EXCEPTION_CODE = "email-already-in-use";
  static const String OPERATION_NOT_ALLOWED_EXCEPTION_CODE = "operation-not-allowed";
  static const String WEAK_PASSWORD_EXCEPTION_CODE = "weak-password";
  static const String USER_MISMATCH_EXCEPTION_CODE = "user-mismatch";
  static const String INVALID_CREDENTIALS_EXCEPTION_CODE = "invalid-credential";
  static const String INVALID_EMAIL_EXCEPTION_CODE = "invalid-email";
  static const String USER_DISABLED_EXCEPTION_CODE = "user-disabled";
  static const String INVALID_VERIFICATION_CODE_EXCEPTION_CODE = "invalid-verification-code";
  static const String INVALID_VERIFICATION_ID_EXCEPTION_CODE = "invalid-verification-id";
  static const String REQUIRES_RECENT_LOGIN_EXCEPTION_CODE = "requires-recent-login";

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthentificationService._privateConstructor();
  static final AuthentificationService _instance = AuthentificationService._privateConstructor();
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
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user!.emailVerified) {
        return true;
      } else {
        await userCredential.user!.sendEmailVerification();
        throw FirebaseSignInAuthUserNotVerifiedException();
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
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
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

  Future<bool> changePasswordForCurrentUser({String? oldPassword, required String newPassword}) async {
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

  Future<bool> changeEmailForCurrentUser({String? password, required String newEmail}) async {
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
