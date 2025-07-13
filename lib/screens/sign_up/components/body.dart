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
              SizedBox(height: SizeConfig.screenHeight * 0.08),
              // FishKart logo/text
              Text(
                "FishKart",
                style: TextStyle(
                  fontFamily: 'Shadows Into Light Two',
                  fontSize: 36,
                  color: Color(0xFF2B344F),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: SizeConfig.screenHeight * 0.06),
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
                    Text(
                      "Email",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF2B344F),
                      ),
                    ),
                    SizedBox(height: 8),
                    // The form fields are in SignUpForm
                    SignUpForm(),
                  ],
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
