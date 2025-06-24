import 'package:firebase_auth/firebase_auth.dart';

abstract class MessagedFirebaseAuthException extends FirebaseAuthException {
  final String _message;
  final String code;

  MessagedFirebaseAuthException(this.code, this._message)
      : super(code: code, message: _message);

  String get message => _message;

  @override
  String toString() => message;
}
