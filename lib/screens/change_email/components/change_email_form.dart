import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/components/custom_suffix_icon.dart';
import 'package:fishkart/components/default_button.dart';
import 'package:fishkart/exceptions/firebaseauth/credential_actions_exceptions.dart';
import 'package:fishkart/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';

import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/size_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../../constants.dart';

class ChangeEmailForm extends StatefulWidget {
  @override
  _ChangeEmailFormState createState() => _ChangeEmailFormState();
}

class _ChangeEmailFormState extends State<ChangeEmailForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController currentEmailController = TextEditingController();
  final TextEditingController newEmailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    currentEmailController.dispose();
    newEmailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        color: const Color(0xFFF7F8FA),
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Logo
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Shadows Into Light Two',
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
                children: const [
                  TextSpan(
                    text: 'Fish',
                    style: TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text: 'Kart',
                    style: TextStyle(color: Color(0xFF29465B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
            Center(
              child: Container(
                width: 380,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Current Email",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Current email (no masking)
                      StreamBuilder<User?>(
                        stream: AuthentificationService().userChanges,
                        builder: (context, snapshot) {
                          String currentEmail = '';
                          if (snapshot.hasData && snapshot.data != null) {
                            currentEmail = snapshot.data!.email ?? '';
                          }
                          return Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              currentEmail.isNotEmpty
                                  ? currentEmail
                                  : "No email available",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "New Email",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: newEmailController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          hintText: 'Enter new email',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                          suffixIcon: Icon(Icons.mail),
                        ),
                        style: const TextStyle(fontSize: 16),
                        validator: (value) {
                          if (newEmailController.text.isEmpty) {
                            return kEmailNullError;
                          } else if (!emailValidatorRegExp.hasMatch(
                            newEmailController.text,
                          )) {
                            return kInvalidEmailError;
                          } else if (newEmailController.text ==
                              currentEmailController.text) {
                            return "Email is already linked to account";
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Password",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          hintText: 'Enter password',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                          suffixIcon: Icon(Icons.lock),
                        ),
                        style: const TextStyle(fontSize: 16),
                        validator: (value) {
                          if (passwordController.text.isEmpty) {
                            return "Password cannot be empty";
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 220,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34495E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final updateFuture = changeEmailButtonCallback();
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AsyncProgressDialog(
                                    updateFuture,
                                    message: const Text("Updating Email"),
                                  );
                                },
                              );
                            },
                            child: const Text(
                              "Update",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPasswordFormField() {
    return TextFormField(
      controller: passwordController,
      obscureText: true,
      decoration: InputDecoration(
        hintText: "Password",
        labelText: "Enter Password",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Lock.svg"),
      ),
      validator: (value) {
        if (passwordController.text.isEmpty) {
          return "Password cannot be empty";
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildCurrentEmailFormField() {
    return StreamBuilder<User?>(
      stream: AuthentificationService().userChanges,
      builder: (context, snapshot) {
        String currentEmail = '';
        if (snapshot.hasData && snapshot.data != null)
          currentEmail = snapshot.data!.email ?? '';
        final textField = TextFormField(
          controller: currentEmailController,
          decoration: InputDecoration(
            hintText: "CurrentEmail",
            labelText: "Current Email",
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Mail.svg"),
          ),
          readOnly: true,
        );
        currentEmailController.text = currentEmail;
        return textField;
      },
    );
  }

  Widget buildNewEmailFormField() {
    return TextFormField(
      controller: newEmailController,
      decoration: InputDecoration(
        hintText: "Enter New Email",
        labelText: "New Email",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Mail.svg"),
      ),
      validator: (value) {
        if (newEmailController.text.isEmpty) {
          return kEmailNullError;
        } else if (!emailValidatorRegExp.hasMatch(newEmailController.text)) {
          return kInvalidEmailError;
        } else if (newEmailController.text == currentEmailController.text) {
          return "Email is already linked to account";
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Future<void> changeEmailButtonCallback() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final AuthentificationService authService = AuthentificationService();
      bool passwordValidation = await authService.verifyCurrentUserPassword(
        passwordController.text,
      );
      if (passwordValidation) {
        bool updationStatus = false;
        String snackbarMessage = '';
        try {
          updationStatus = await authService.changeEmailForCurrentUser(
            newEmail: newEmailController.text,
          );
          if (updationStatus == true) {
            snackbarMessage =
                "Verification email sent. Please verify your new email";
          } else {
            throw FirebaseCredentialActionAuthUnknownReasonFailureException(
              message:
                  "Couldn't process your request now. Please try again later",
            );
          }
        } on MessagedFirebaseAuthException catch (e) {
          snackbarMessage = e.message;
        } catch (e) {
          snackbarMessage = e.toString();
        } finally {
          Logger().i(snackbarMessage);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
        }
      }
    }
  }
}
