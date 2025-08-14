import 'package:flutter/material.dart';
import 'package:fishkart/size_config.dart';

const String appName = "Fishkart";

const kPrimaryColor = Color.fromARGB(255, 0, 0, 0);
const kPrimaryLightColor = Color.fromARGB(255, 255, 255, 255);
const kPrimaryGradientColor = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color.fromARGB(255, 8, 7, 6), Color.fromARGB(255, 233, 222, 218)],
);
const kSecondaryColor = Color.fromARGB(255, 174, 174, 174);
const kTextColor = Color.fromARGB(255, 89, 89, 89);

const kAnimationDuration = Duration(milliseconds: 200);

const double screenPadding = 10;

final headingStyle = TextStyle(
  fontSize: getProportionateScreenWidth(28),
  fontWeight: FontWeight.w600,
  color: Colors.black,
  height: 1.5,
);

const defaultDuration = Duration(milliseconds: 250);

final RegExp emailValidatorRegExp = RegExp(
  r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
);
const String kEmailNullError = "Please Enter your email";
const String kInvalidEmailError = "Please Enter Valid Email";
const String kPassNullError = "Please Enter your password";
const String kShortPassError = "Password is too short";
const String kMatchPassError = "Passwords don't match";
const String kNamelNullError = "Please Enter your name";
const String kPhoneNumberNullError = "Please Enter your phone number";
const String kAddressNullError = "Please Enter your address";
const String FIELD_REQUIRED_MSG = "This field is required";
const String kDisplayNameNullError = "Please enter your display name";
const String kShortDisplayNameError =
    "Display name must be at least 2 characters";
const String kLongDisplayNameError =
    "Display name must be less than 30 characters";

final otpInputDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(
    vertical: getProportionateScreenWidth(15),
  ),
  border: outlineInputBorder(),
  focusedBorder: outlineInputBorder(),
  enabledBorder: outlineInputBorder(),
);

OutlineInputBorder outlineInputBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(getProportionateScreenWidth(15)),
    borderSide: BorderSide(color: kTextColor),
  );
}
