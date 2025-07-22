import 'package:fishkart/constants.dart';
import 'package:flutter/material.dart';
import '../../../size_config.dart';
import '../../../components/no_account_text.dart';
import 'package:fishkart/screens/sign_up/sign_up_screen.dart';
import 'package:fishkart/screens/forgot_password/forgot_password_screen.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/exceptions/firebaseauth/messeged_firebaseauth_exception.dart';
import 'package:fishkart/screens/home/home_screen.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Center(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: SizeConfig.screenHeight * 0.05),
              // FishKart logo/text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Shadows Into Light Two',
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  children: [
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
              SizedBox(height: SizeConfig.screenHeight * 0.035),
              // Card with form and social login
              Container(
                width: 340,
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: _SignInCardContent(),
              ),
              SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInCardContent extends StatefulWidget {
  @override
  State<_SignInCardContent> createState() => _SignInCardContentState();
}

class _SignInCardContentState extends State<_SignInCardContent> {
  bool keepLoggedIn = true;
  bool passwordVisible = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> handleLogin() async {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter email and password")),
        );
        return;
      }
      // Removed loading dialog as requested
      String snackbarMessage = '';
      bool signInStatus = false;
      try {
        final authService = AuthentificationService();
        signInStatus = await authService.signIn(
          email: email,
          password: password,
        );
        snackbarMessage = "Signed In Successfully";
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // Only navigate if signInStatus is true and user is not null
        if (signInStatus) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } on MessagedFirebaseAuthException catch (e) {
        snackbarMessage = e.message;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        snackbarMessage = e.toString();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
      if (!signInStatus) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF2B344F),
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: "youremail@gmail.com",
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2B344F)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2B344F)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2B344F), width: 2),
            ),
          ),
        ),
        SizedBox(height: 18),
        Text(
          "Password",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF2B344F),
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: !passwordVisible,
          decoration: InputDecoration(
            hintText: "************",
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2B344F)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2B344F)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF2B344F), width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Color(0xFF2B344F),
              ),
              onPressed: () {
                setState(() {
                  passwordVisible = !passwordVisible;
                });
              },
            ),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: keepLoggedIn,
              activeColor: Color(0xFF2B344F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (val) {
                setState(() {
                  keepLoggedIn = val ?? true;
                });
              },
            ),
            Text(
              "Keep me logged in",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: Color(0xFF2B344F),
                fontWeight: FontWeight.w400,
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => SignUpScreen()));
              },
              child: Text(
                "Sign Up",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B344F),
                  decoration: TextDecoration.underline,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 2.0),
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF2B344F),
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2B344F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            onPressed: handleLogin,
            child: Text(
              "Login",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Or",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        SizedBox(height: 16),
        // Social login buttons
        Column(
          children: [
            SizedBox(height: 12),
            _SocialButton(
              iconAsset: 'assets/icons/google-icon.png',
              text: 'Continue with Google',
              onPressed: () async {
                try {
                  final authService = AuthentificationService();
                  final result = await authService.signInWithGoogle();
                  if (result == true) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  } else if (result == 'signup') {
                    // Redirect to signup page
                    Navigator.of(context).pushReplacementNamed('/sign_up');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Google sign-in failed")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Google sign-in error: $e")),
                  );
                }
              },
            ),
            SizedBox(height: 12),
            _SocialButton(
              iconAsset: 'assets/icons/facebook.png',
              text: 'Continue with Facebook',
              onPressed: () async {
                try {
                  final authService = AuthentificationService();
                  final result = await authService.signInWithFacebook();
                  if (result) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Facebook sign-in failed")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Facebook sign-in error: $e")),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

// Social login button widget
class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final String? iconAsset;
  final String text;
  final VoidCallback onPressed;
  const _SocialButton({
    this.icon,
    this.iconAsset,
    required this.text,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2B344F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, size: 28)
            else if (iconAsset != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Image.asset(iconAsset!, fit: BoxFit.contain),
                ),
              ),
            SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B344F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
