import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:nexoeshopee/components/custom_suffix_icon.dart';
import 'package:nexoeshopee/components/default_button.dart';
import 'package:nexoeshopee/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';
import 'package:nexoeshopee/exceptions/firebaseauth/signup_exceptions.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../constants.dart';
import '../../home/home_screen.dart';
import 'package:nexoeshopee/providers/user_providers.dart' as user_providers;

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
              color: Color(0xFF2B344F),
            ),
          ),
          SizedBox(height: 3),
          buildDisplayNameFormField(),
          SizedBox(height: 8),
          // Phone number
          Text(
            "Phone number",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF2B344F),
            ),
          ),
          SizedBox(height: 3),
          buildPhoneNumberFormField(),
          SizedBox(height: 8),
          // Email
          Text(
            "Email",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF2B344F),
            ),
          ),
          SizedBox(height: 3),
          buildEmailFormField(),
          SizedBox(height: 8),
          // Password
          Text(
            "Password",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF2B344F),
            ),
          ),
          SizedBox(height: 3),
          buildPasswordFormField(),
          SizedBox(height: 8),
          // Confirm Password
          Text(
            "Confirm Password",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF2B344F),
            ),
          ),
          SizedBox(height: 3),
          buildConfirmPasswordFormField(),
          SizedBox(height: 8),

          // Name
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2B344F),
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
                  fontWeight: FontWeight.w700,
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
    return TextFormField(
      controller: displayNameController,
      decoration: InputDecoration(
        hintText: "your_name",
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/User.svg"),

        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2B344F), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2B344F), width: 2),
        ),
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
    );
  }

  Widget buildPhoneNumberFormField() {
    return TextFormField(
      controller: phoneNumberController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: "your_phone_number",
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Phone.svg"),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2B344F), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2B344F), width: 2),
        ),
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
    );
  }

  Widget buildConfirmPasswordFormField() {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: confirmPasswordFieldController,
          obscureText: !_confirmPasswordVisible,
          decoration: InputDecoration(
            hintText: "************",
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2B344F), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2B344F), width: 2),
            ),
            suffixIcon: IconButton(
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
    );
  }

  Widget buildEmailFormField() {
    return TextFormField(
      controller: emailFieldController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: "youremail@gmail.com",
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Mail.svg"),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2B344F), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2B344F), width: 2),
        ),
      ),
      validator: (value) {
        if (emailFieldController.text.isEmpty) {
          return kEmailNullError;
        } else if (!emailValidatorRegExp.hasMatch(emailFieldController.text)) {
          return kInvalidEmailError;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildPasswordFormField() {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: passwordFieldController,
          obscureText: !_passwordVisible,
          decoration: InputDecoration(
            hintText: "************",
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2B344F), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2B344F), width: 2),
            ),
            suffixIcon: IconButton(
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
          // Navigate directly to home screen
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
