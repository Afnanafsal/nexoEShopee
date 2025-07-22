import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/components/custom_suffix_icon.dart';
import 'package:fishkart/components/default_button.dart';
import 'package:fishkart/constants.dart';
import 'package:fishkart/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';
import 'package:fishkart/exceptions/firebaseauth/credential_actions_exceptions.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/size_config.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ChangePasswordForm extends StatefulWidget {
  @override
  _ChangePasswordFormState createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController =
      TextEditingController();

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
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
                        "Current Password",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          hintText: 'Enter current password',
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
                        autovalidateMode: AutovalidateMode.disabled,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "New Password",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          hintText: 'Enter new password',
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
                          if (newPasswordController.text.isEmpty) {
                            return "Password cannot be empty";
                          } else if (newPasswordController.text.length < 8) {
                            return "Password too short";
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Confirm New Password",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: confirmNewPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          hintText: 'Confirm new password',
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
                          if (confirmNewPasswordController.text !=
                              newPasswordController.text) {
                            return "Not matching with Password";
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
                              final updateFuture =
                                  changePasswordButtonCallback();
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AsyncProgressDialog(
                                    updateFuture,
                                    message: const Text("Updating Password"),
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

  Widget buildConfirmNewPasswordFormField() {
    return TextFormField(
      controller: confirmNewPasswordController,
      obscureText: true,
      decoration: InputDecoration(
        hintText: "Confirm New Password",
        labelText: "Confirm New Password",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Lock.svg"),
      ),
      validator: (value) {
        if (confirmNewPasswordController.text != newPasswordController.text) {
          return "Not matching with Password";
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildCurrentPasswordFormField() {
    return TextFormField(
      controller: currentPasswordController,
      obscureText: true,
      decoration: InputDecoration(
        hintText: "Enter Current Password",
        labelText: "Current Password",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Lock.svg"),
      ),
      validator: (value) {
        return null;
      },
      autovalidateMode: AutovalidateMode.disabled,
    );
  }

  Widget buildNewPasswordFormField() {
    return TextFormField(
      controller: newPasswordController,
      obscureText: true,
      decoration: InputDecoration(
        hintText: "Enter New password",
        labelText: "New Password",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Lock.svg"),
      ),
      validator: (value) {
        if (newPasswordController.text.isEmpty) {
          return "Password cannot be empty";
        } else if (newPasswordController.text.length < 8) {
          return "Password too short";
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Future<void> changePasswordButtonCallback() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final AuthentificationService authService = AuthentificationService();
      bool currentPasswordValidation = await authService
          .verifyCurrentUserPassword(currentPasswordController.text);
      if (currentPasswordValidation == false) {
        print("Current password provided is wrong");
      } else {
        bool updationStatus = false;
        String snackbarMessage = "An error occurred";
        try {
          updationStatus = await authService.changePasswordForCurrentUser(
            newPassword: newPasswordController.text,
          );
          if (updationStatus == true) {
            snackbarMessage = "Password changed successfully";
          } else {
            throw FirebaseCredentialActionAuthUnknownReasonFailureException(
              message: "Failed to change password, due to some unknown reason",
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
