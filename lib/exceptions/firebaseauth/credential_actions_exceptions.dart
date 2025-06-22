import 'package:nexoeshopee/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';

class FirebaseCredentialActionAuthException
    extends MessagedFirebaseAuthException {
  FirebaseCredentialActionAuthException({
    String code = "credential-action-error",
    String message =
        "An authentication error occurred during the credential action",
  }) : super(code, message);
}

class FirebaseCredentialActionAuthUserNotFoundException
    extends FirebaseCredentialActionAuthException {
  FirebaseCredentialActionAuthUserNotFoundException()
    : super(code: "user-not-found", message: "No such user exists");
}

class FirebaseCredentialActionAuthWeakPasswordException
    extends FirebaseCredentialActionAuthException {
  FirebaseCredentialActionAuthWeakPasswordException()
    : super(
        code: "weak-password",
        message: "The password is too weak. Please use a stronger password",
      );
}

class FirebaseCredentialActionAuthRequiresRecentLoginException
    extends FirebaseCredentialActionAuthException {
  FirebaseCredentialActionAuthRequiresRecentLoginException()
    : super(
        code: "requires-recent-login",
        message: "This action requires a recent login. Please sign in again",
      );
}

class FirebaseCredentialActionAuthUnknownReasonFailureException
    extends FirebaseCredentialActionAuthException {
  FirebaseCredentialActionAuthUnknownReasonFailureException({required String message})
    : super(
        code: "unknown-reason",
        message: "The action couldn't be completed due to an unknown reason",
      );
}
