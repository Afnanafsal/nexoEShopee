import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart/screens/home/home_screen.dart';
import 'package:fishkart/screens/sign_in/sign_in_screen.dart';
import 'package:fishkart/providers/user_providers.dart';

class AuthentificationWrapper extends ConsumerWidget {
  static const String routeName = "/authentification_wrapper";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // Check userType in Firestore
          return FutureBuilder(
            future: ref
                .read(userDatabaseHelperProvider)
                .firestore
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(child: Text('Error: ${snapshot.error}')),
                );
              }
              final userType = snapshot.data?.data()?['userType'];
              print('[DEBUG] userType for ${user.uid}: $userType');
              if (userType == 'customer') {
                return HomeScreen();
              } else {
                // Sign out and show sign-in screen WITHOUT snackbar
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await ref.read(authServiceProvider).signOut();
                });
                return SignInScreen();
              }
            },
          );
        } else {
          return SignInScreen();
        }
      },
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking authentication...'),
            ],
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }
}