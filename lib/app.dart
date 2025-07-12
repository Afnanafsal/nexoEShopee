import 'package:flutter/material.dart';
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
      },
    );
  }
}
