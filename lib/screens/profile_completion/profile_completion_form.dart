import 'package:flutter/material.dart';
import 'package:fishkart/components/custom_suffix_icon.dart';
import 'package:fishkart/components/default_button.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/size_config.dart';
import 'package:fishkart/screens/home/home_screen.dart';

class ProfileCompletionForm extends StatefulWidget {
  @override
  _ProfileCompletionFormState createState() => _ProfileCompletionFormState();
}

class _ProfileCompletionFormState extends State<ProfileCompletionForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void dispose() {
    phoneNumberController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          buildPhoneNumberFormField(),
          SizedBox(height: getProportionateScreenHeight(30)),
          buildAddressFormField(),
          SizedBox(height: getProportionateScreenHeight(40)),
          DefaultButton(
            text: "Continue",
            press: () async {
              if (_formKey.currentState?.validate() ?? false) {
                try {
                  final uid = AuthentificationService().currentUser.uid;

                  // Update user profile in Firestore
                  await UserDatabaseHelper().updateUser(uid, {
                    UserDatabaseHelper.PHONE_KEY: phoneNumberController.text,
                    "address": addressController.text,
                  });

                  // Navigate to home screen using MaterialPageRoute
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error updating profile: ${e.toString()}"),
                    ),
                  );
                }
              }
            },
          ),
          SizedBox(height: getProportionateScreenHeight(20)),
          TextButton(
            onPressed: () {
              // Skip profile completion and go to home using MaterialPageRoute
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              );
            },
            child: Text("Skip for now"),
          ),
        ],
      ),
    );
  }

  TextFormField buildPhoneNumberFormField() {
    return TextFormField(
      controller: phoneNumberController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: "Enter your phone number",
        labelText: "Phone Number",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(svgIcon: "assets/icons/Phone.svg"),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your phone number";
        }
        return null;
      },
    );
  }

  TextFormField buildAddressFormField() {
    return TextFormField(
      controller: addressController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: "Enter your address",
        labelText: "Address",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: CustomSuffixIcon(
          svgIcon: "assets/icons/Location point.svg",
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your address";
        }
        return null;
      },
    );
  }
}
