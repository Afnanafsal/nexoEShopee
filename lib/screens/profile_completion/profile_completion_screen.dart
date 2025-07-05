import 'package:flutter/material.dart';
import 'package:nexoeshopee/components/default_button.dart';
import 'package:nexoeshopee/screens/profile_completion/profile_completion_form.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:nexoeshopee/constants.dart';

class ProfileCompletionScreen extends StatelessWidget {
  static String routeName = "/profile_completion";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Complete Your Profile"), centerTitle: true),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: SizeConfig.screenHeight * 0.03),
                  Text("Complete Profile", style: headingStyle),
                  Text(
                    "Complete your details to get started",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: SizeConfig.screenHeight * 0.06),
                  ProfileCompletionForm(),
                  SizedBox(height: getProportionateScreenHeight(30)),
                  Text(
                    "By continuing you confirm that you agree \nwith our Terms and Conditions",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
