import 'package:flutter/material.dart';
import 'package:nexoeshopee/screens/forgot_password/components/body.dart';
import 'package:nexoeshopee/screens/forgot_password/forgot_password_screen.dart';
import 'package:nexoeshopee/screens/sign_in/sign_in_screen.dart';
import 'package:nexoeshopee/screens/sign_up/sign_up_screen.dart';
import 'package:nexoeshopee/screens/splash/splash_screen.dart';
import 'package:nexoeshopee/wrappers/authentification_wrapper.dart';

import '../constants.dart';
import '../theme.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: theme(),
      home: SplashScreen(),
      routes: {
        '/splash': (context) => SplashScreen(),
        '/auth': (context) => AuthentificationWrapper(),
        '/sign_in': (context) => SignInScreen(),
        '/sign_up': (context) => SignUpScreen(),
        '/forgot': (context) =>
            ForgotPasswordScreen(), // Assuming you want to redirect to sign in for forgot password
      },
    );
  }
}
