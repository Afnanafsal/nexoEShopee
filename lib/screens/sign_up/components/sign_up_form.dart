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
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(screenPadding),
        ),
        child: Column(
          children: [
            SizedBox(height: getProportionateScreenHeight(10)),
            buildDisplayNameFormField(),
            SizedBox(height: getProportionateScreenHeight(30)),
            buildEmailFormField(),
            SizedBox(height: getProportionateScreenHeight(30)),
            buildPhoneNumberFormField(),
            SizedBox(height: getProportionateScreenHeight(30)),
            buildPasswordFormField(),
            SizedBox(height: getProportionateScreenHeight(30)),
            buildConfirmPasswordFormField(),
            SizedBox(height: getProportionateScreenHeight(40)),
            DefaultButton(
              text: "Sign up",
              press: formState.isLoading ? null : signUpButtonCallback,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDisplayNameFormField() {
    return TextFormField(
      controller: displayNameController,
      decoration: InputDecoration(
        hintText: "Enter your display name",
        labelText: "Display Name",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/User.svg"),
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
        hintText: "Enter your phone number",
        labelText: "Phone Number",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Phone.svg"),
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
    return TextFormField(
      controller: confirmPasswordFieldController,
      obscureText: true,
      decoration: InputDecoration(
        hintText: "Re-enter your password",
        labelText: "Confirm Password",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Lock.svg"),
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
  }

  Widget buildEmailFormField() {
    return TextFormField(
      controller: emailFieldController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: "Enter your email",
        labelText: "Email",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Mail.svg"),
      ),
      onChanged: (value) {
        ref
            .read(user_providers.signUpFormDataProvider.notifier)
            .updateEmail(value);
      },
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
    return TextFormField(
      controller: passwordFieldController,
      obscureText: true,
      decoration: InputDecoration(
        hintText: "Enter your password",
        labelText: "Password",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Lock.svg"),
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
