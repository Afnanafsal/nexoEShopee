import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/screens/sign_up/components/sign_up_form.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:flutter/material.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF5F6F8FF), // light background
      body: Center(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: SizeConfig.screenHeight * 0.03),
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
              SizedBox(height: SizeConfig.screenHeight * 0.03),
              // Card with form
              Container(
                width: 370,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The form fields and labels are handled in SignUpForm
                    SignUpForm(),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/sign_in');
                              },
                                child: Text(
                                "Already have an account?",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2B344F),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Navigate to forgot password screen
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
