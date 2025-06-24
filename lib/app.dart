import 'package:flutter/material.dart';
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
        home: AuthentificationWrapper()
        //home: AuthentificationWrapper(),
        );
  }
}
