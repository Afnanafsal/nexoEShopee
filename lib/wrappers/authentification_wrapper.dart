import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/screens/home/home_screen.dart';
import 'package:nexoeshopee/screens/sign_in/sign_in_screen.dart';
import 'package:nexoeshopee/providers/user_providers.dart';

class AuthentificationWrapper extends ConsumerWidget {
  static const String routeName = "/authentification_wrapper";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return HomeScreen();
        } else {
          return SignInScreen();
        }
      },
      loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
