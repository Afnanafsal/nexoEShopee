
import 'package:nexoeshopee/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';

class FirebaseSignUpAuthException extends MessagedFirebaseAuthException {
  FirebaseSignUpAuthException({
    String code = "sign-up-error",
    String message = "An error occurred during sign up",
  }) : super(code, message);
}

class FirebaseSignUpAuthEmailAlreadyInUseException extends FirebaseSignUpAuthException {
  FirebaseSignUpAuthEmailAlreadyInUseException()
      : super(
          code: "email-already-in-use",
          message: "Email already in use",
        );
}

class FirebaseSignUpAuthInvalidEmailException extends FirebaseSignUpAuthException {
  FirebaseSignUpAuthInvalidEmailException()
      : super(
          code: "invalid-email",
          message: "Email is not valid",
        );
}

class FirebaseSignUpAuthOperationNotAllowedException extends FirebaseSignUpAuthException {
  FirebaseSignUpAuthOperationNotAllowedException()
      : super(
          code: "operation-not-allowed",
          message: "Sign up is restricted for this user",
        );
}

class FirebaseSignUpAuthWeakPasswordException extends FirebaseSignUpAuthException {
  FirebaseSignUpAuthWeakPasswordException()
      : super(
          code: "weak-password",
          message: "Weak password, try something better",
        );
}

class FirebaseSignUpAuthUnknownReasonFailureException extends FirebaseSignUpAuthException {
  FirebaseSignUpAuthUnknownReasonFailureException()
      : super(
          code: "sign-up-unknown-failure",
          message: "Can't register due to unknown reason",
        );
}
