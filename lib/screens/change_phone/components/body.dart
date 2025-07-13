import 'package:nexoeshopee/size_config.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import 'change_phone_number_form.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),

        child: Column(children: [ChangePhoneNumberForm(key: UniqueKey())]),
      ),
    );
  }
}
