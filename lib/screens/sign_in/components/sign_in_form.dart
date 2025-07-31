import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';
import 'package:fishkart/exceptions/firebaseauth/signin_exceptions.dart';
import 'package:fishkart/screens/forgot_password/forgot_password_screen.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/providers/user_providers.dart' as user_providers;
import 'package:logger/logger.dart';

import '../../../components/custom_suffix_icon.dart';
import '../../../components/default_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../size_config.dart';

class SignInForm extends ConsumerStatefulWidget {
  @override
  _SignInFormState createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _formkey = GlobalKey<FormState>();

  final TextEditingController emailFieldController = TextEditingController();
  final TextEditingController passwordFieldController = TextEditingController();

  @override
  void dispose() {
    emailFieldController.dispose();
    passwordFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(user_providers.signInFormProvider);

    return Form(
      key: _formkey,
      child: Column(
        children: [
          buildEmailFormField(),
          SizedBox(height: getProportionateScreenHeight(30)),
          buildPasswordFormField(),
          SizedBox(height: getProportionateScreenHeight(30)),
          buildForgotPasswordWidget(context),
          SizedBox(height: getProportionateScreenHeight(30)),
          DefaultButton(
            text: "Sign in",
            press: formState.isLoading ? null : signInButtonCallback,
          ),
        ],
      ),
    );
  }

  Widget buildForgotPasswordWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
            );
          },
          child: Text(
            "Forgot Password",
            style: TextStyle(decoration: TextDecoration.underline),
          ),
        ),
      ],
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

  Future<void> signInButtonCallback() async {
    if (_formkey.currentState?.validate() ?? false) {
      _formkey.currentState?.save();

      ref.read(user_providers.signInFormProvider.notifier).setLoading(true);

      final AuthentificationService authService = AuthentificationService();
      bool signInStatus = false;
      String snackbarMessage = '';
      try {
        final signInFuture = authService.signIn(
          email: emailFieldController.text.trim(),
          password: passwordFieldController.text.trim(),
        );
        signInStatus = await showDialog(
          context: context,
          builder: (context) {
            return AsyncProgressDialog(
              signInFuture,
              message: Text("Signing in to account"),
              onError: (e) {
                snackbarMessage = e.toString();
              },
            );
          },
        );
        if (signInStatus == true) {
          snackbarMessage = "Signed In Successfully";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackbarMessage),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          if (snackbarMessage.isEmpty) {
            snackbarMessage = "Unknown sign in failure";
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackbarMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on MessagedFirebaseAuthException catch (e) {
        snackbarMessage = e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackbarMessage),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        snackbarMessage = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackbarMessage),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        ref.read(user_providers.signInFormProvider.notifier).setLoading(false);
        Logger().i(snackbarMessage);
      }
    }
  }
}
