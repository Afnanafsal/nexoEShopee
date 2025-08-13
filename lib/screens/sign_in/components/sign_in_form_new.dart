import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/components/custom_suffix_icon.dart';
import 'package:fishkart/components/default_button.dart';
import 'package:fishkart/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';
import 'package:fishkart/exceptions/firebaseauth/signup_exceptions.dart';
import 'package:fishkart/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../constants.dart';
import '../../home/home_screen.dart';
import 'package:fishkart/providers/user_providers.dart' as user_providers;

class SignUpForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailFieldController = TextEditingController();
  final TextEditingController passwordFieldController = TextEditingController();
  final TextEditingController confirmPasswordFieldController =
      TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  // Standard decoration for all form fields
  InputDecoration _getStandardDecoration(String hintText, Widget? suffixIcon) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    emailFieldController.dispose();
    passwordFieldController.dispose();
    confirmPasswordFieldController.dispose();
    displayNameController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(user_providers.signUpFormProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Name",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          buildDisplayNameFormField(),
          SizedBox(height: 20),
          // Phone number
          Text(
            "Phone number",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          buildPhoneNumberFormField(),
          SizedBox(height: 20),
          // Email
          Text(
            "Email",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          buildEmailFormField(),
          SizedBox(height: 20),
          // Password
          Text(
            "Password",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          buildPasswordFormField(),
          SizedBox(height: 20),
          // Confirm Password
          Text(
            "Confirm Password",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          buildConfirmPasswordFormField(),
          SizedBox(height: 20),

          // Sign Up Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: formState.isLoading ? null : signUpButtonCallback,
              child: Text(
                "Sign Up",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDisplayNameFormField() {
    return Container(
      height: 50,
      child: TextFormField(
        controller: displayNameController,
        decoration: _getStandardDecoration(
          "your_name",
          CustomSuffixIcon(svgIcon: "assets/icons/User.svg"),
        ),
        onChanged: (value) {
          ref
              .read(user_providers.signUpFormDataProvider.notifier)
              .updateDisplayName(value);
        },
        validator: (value) {
          if (displayNameController.text.isEmpty) {
            return "Please enter your display name";
          } else if (displayNameController.text.length < 2) {
            return "Display name must be at least 2 characters";
          } else if (displayNameController.text.length > 30) {
            return "Display name must be less than 30 characters";
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget buildPhoneNumberFormField() {
    return Container(
      height: 30,
      child: TextFormField(
        controller: phoneNumberController,
        keyboardType: TextInputType.phone,
        decoration: _getStandardDecoration(
          "your_phone_number",
          CustomSuffixIcon(svgIcon: "assets/icons/Phone.svg"),
        ),
        onChanged: (value) {
          ref
              .read(user_providers.signUpFormDataProvider.notifier)
              .updatePhoneNumber(value);
        },
        validator: (value) {
          if (phoneNumberController.text.isEmpty) {
            return "Please enter your phone number";
          } else if (phoneNumberController.text.length < 10) {
            return "Phone number must be at least 10 digits";
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget buildEmailFormField() {
    return Container(
      height: 50,
      child: TextFormField(
        controller: emailFieldController,
        keyboardType: TextInputType.emailAddress,
        decoration: _getStandardDecoration(
          "youremail@gmail.com",
          CustomSuffixIcon(svgIcon: "assets/icons/Mail.svg"),
        ),
        validator: (value) {
          if (emailFieldController.text.isEmpty) {
            return kEmailNullError;
          } else if (!emailValidatorRegExp.hasMatch(
            emailFieldController.text,
          )) {
            return kInvalidEmailError;
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget buildPasswordFormField() {
    return Container(
      height: 50,
      child: StatefulBuilder(
        builder: (context, setState) {
          return TextFormField(
            controller: passwordFieldController,
            obscureText: !_passwordVisible,
            decoration: _getStandardDecoration(
              "************",
              IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
            onChanged: (value) {
              ref
                  .read(user_providers.signUpFormDataProvider.notifier)
                  .updatePassword(value);
            },
            validator: (value) {
              if (passwordFieldController.text.isEmpty) {
                return kPassNullError;
              } else if (passwordFieldController.text.length < 8) {
                return kShortPassError;
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        },
      ),
    );
  }

  Widget buildConfirmPasswordFormField() {
    return Container(
      height: 50,
      child: StatefulBuilder(
        builder: (context, setState) {
          return TextFormField(
            controller: confirmPasswordFieldController,
            obscureText: !_confirmPasswordVisible,
            decoration: _getStandardDecoration(
              "************",
              IconButton(
                icon: Icon(
                  _confirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _confirmPasswordVisible = !_confirmPasswordVisible;
                  });
                },
              ),
            ),
            onChanged: (value) {
              ref
                  .read(user_providers.signUpFormDataProvider.notifier)
                  .updateConfirmPassword(value);
            },
            validator: (value) {
              if (confirmPasswordFieldController.text.isEmpty) {
                return kPassNullError;
              } else if (confirmPasswordFieldController.text !=
                  passwordFieldController.text) {
                return kMatchPassError;
              } else if (confirmPasswordFieldController.text.length < 8) {
                return kShortPassError;
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        },
      ),
    );
  }

  Future<void> signUpButtonCallback() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authService = ref.read(user_providers.authServiceProvider);
      final formNotifier = ref.read(user_providers.signUpFormProvider.notifier);

      bool signUpStatus = false;
      String snackbarMessage = '';

      try {
        formNotifier.setLoading(true);

        final signUpFuture = authService.signUpWithCompleteProfile(
          email: emailFieldController.text,
          password: passwordFieldController.text,
          displayName: displayNameController.text,
          phoneNumber: phoneNumberController.text,
        );

        signUpFuture.then((value) => signUpStatus = value);
        signUpStatus = await showDialog(
          context: context,
          builder: (context) {
            return AsyncProgressDialog(
              signUpFuture,
              message: Text("Creating new account"),
            );
          },
        );

        if (signUpStatus == true) {
          snackbarMessage =
              "Account created successfully! Please verify your email.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackbarMessage),
              backgroundColor: Colors.green,
            ),
          );
          await Future.delayed(Duration(seconds: 2));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        } else {
          throw FirebaseSignUpAuthUnknownReasonFailureException();
        }
      } on MessagedFirebaseAuthException catch (e) {
        snackbarMessage = e.message;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      } catch (e) {
        snackbarMessage = e.toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      } finally {
        formNotifier.setLoading(false);
        Logger().i(snackbarMessage);
      }
    }
  }
}
