import 'package:nexoeshopee/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';

class FirebaseSignInAuthException extends MessagedFirebaseAuthException {
  FirebaseSignInAuthException({
    String code = "sign-in-error",
    String message = "An unknown sign-in error occurred",
  }) : super(code, message);
}

class FirebaseSignInAuthUserDisabledException
    extends FirebaseSignInAuthException {
  FirebaseSignInAuthUserDisabledException()
    : super(code: "user-disabled", message: "This user is disabled");
}

class FirebaseSignInAuthUserNotFoundException
    extends FirebaseSignInAuthException {
  FirebaseSignInAuthUserNotFoundException()
    : super(code: "user-not-found", message: "No such user found");
}

class FirebaseSignInAuthInvalidEmailException
    extends FirebaseSignInAuthException {
  FirebaseSignInAuthInvalidEmailException()
    : super(code: "invalid-email", message: "Email is not valid");
}

class FirebaseSignInAuthWrongPasswordException
    extends FirebaseSignInAuthException {
  FirebaseSignInAuthWrongPasswordException()
    : super(code: "wrong-password", message: "Wrong password");
}

class FirebaseTooManyRequestsException extends FirebaseSignInAuthException {
  FirebaseTooManyRequestsException()
    : super(
        code: "too-many-requests",
        message: "Server busy, please try again after some time.",
      );
}

class FirebaseSignInAuthUserNotVerifiedException
    extends FirebaseSignInAuthException {
  FirebaseSignInAuthUserNotVerifiedException()
    : super(code: "user-not-verified", message: "This user is not verified");
}

class FirebaseSignInAuthUnknownReasonFailure
    extends FirebaseSignInAuthException {
  FirebaseSignInAuthUnknownReasonFailure({required String message})
    : super(
        code: "sign-in-unknown-failure",
        message: "Sign in failed due to an unknown reason",
      );
}
