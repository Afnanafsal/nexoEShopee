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
                // Sign out and show sign-in screen with message
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await ref.read(authServiceProvider).signOut();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'This account is not registered as a customer (userType: $userType). Please sign up as a customer.',
                      ),
                    ),
                  );
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
              SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Shadows Into Light Two',
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  children: const [
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
            ],
          ),
        ),
      ),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
