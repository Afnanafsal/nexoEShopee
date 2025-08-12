import 'package:fishkart/constants.dart';
import 'package:fishkart/screens/sign_up/components/sign_up_form.dart';
import 'package:fishkart/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xEFF1F5FF), // light background
      body: Center(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 32.h),
              // FishKart logo/text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Shadows Into Light Two',
                    fontSize: 36.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5.w,
                  ),
                  children: [
                    TextSpan(
                      text: 'Fish',
                      style: TextStyle(color: Color(0xFF29465B)),
                    ),
                    TextSpan(
                      text: 'Kart',
                      style: TextStyle(color: Color(0xFF000000)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              // Card with form
              Container(
                width: 370.w,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 24.r,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The form fields and labels are handled in SignUpForm
                    SignUpForm(),
                    SizedBox(height: 24.h),
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
                                  color: Colors.black,
                                  fontSize: 14.sp,
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
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
