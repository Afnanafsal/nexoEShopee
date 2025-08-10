import 'package:fishkart/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:fishkart/screens/forgot_password/components/body.dart';
import 'package:fishkart/screens/edit_address/edit_address_screen.dart';
import 'package:fishkart/screens/forgot_password/forgot_password_screen.dart';
import 'package:fishkart/screens/sign_in/sign_in_screen.dart';
import 'package:fishkart/screens/sign_up/sign_up_screen.dart';
import 'package:fishkart/screens/splash/splash_screen.dart';
import 'package:fishkart/wrappers/authentification_wrapper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../theme.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X size, adjust as needed
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
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
            '/forgot': (context) => ForgotPasswordScreen(),
            '/add_address': (context) => EditAddressScreen(),
            '/search': (context) => SearchScreen(),
          },
        );
      },
    );
  }
}
