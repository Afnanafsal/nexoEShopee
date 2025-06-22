import 'package:nexoeshopee/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';

class FirebaseReauthException extends MessagedFirebaseAuthException {
  FirebaseReauthException({
    String code = "reauth-error",
    String message = "An error occurred during re-authentication",
  }) : super(code, message);
}

class FirebaseReauthUserMismatchException extends FirebaseReauthException {
  FirebaseReauthUserMismatchException()
      : super(
          code: "user-mismatch",
          message: "User does not match the current user",
        );
}

class FirebaseReauthUserNotFoundException extends FirebaseReauthException {
  FirebaseReauthUserNotFoundException()
      : super(
          code: "user-not-found",
          message: "No such user exists",
        );
}

class FirebaseReauthInvalidCredentialException extends FirebaseReauthException {
  FirebaseReauthInvalidCredentialException()
      : super(
          code: "invalid-credential",
          message: "Invalid credentials provided",
        );
}

class FirebaseReauthInvalidEmailException extends FirebaseReauthException {
  FirebaseReauthInvalidEmailException()
      : super(
          code: "invalid-email",
          message: "The provided email is invalid",
        );
}

class FirebaseReauthWrongPasswordException extends FirebaseReauthException {
  FirebaseReauthWrongPasswordException()
      : super(
          code: "wrong-password",
          message: "The password is incorrect",
        );
}

class FirebaseReauthInvalidVerificationCodeException extends FirebaseReauthException {
  FirebaseReauthInvalidVerificationCodeException()
      : super(
          code: "invalid-verification-code",
          message: "The verification code is invalid",
        );
}

class FirebaseReauthInvalidVerificationIdException extends FirebaseReauthException {
  FirebaseReauthInvalidVerificationIdException()
      : super(
          code: "invalid-verification-id",
          message: "The verification ID is invalid",
        );
}

class FirebaseReauthUnknownReasonFailureException extends FirebaseReauthException {
  FirebaseReauthUnknownReasonFailureException()
      : super(
          code: "reauth-unknown-failure",
          message: "Reauthentication failed due to an unknown reason",
        );
}
