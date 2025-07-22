import 'package:fishkart/constants.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/size_config.dart';
import 'package:flutter/material.dart';

import 'address_details_form.dart';

class Body extends StatelessWidget {
  final String? addressIdToEdit;

  const Body({Key? key, this.addressIdToEdit}) : super(key: key);
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(screenPadding),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(height: getProportionateScreenHeight(20)),
                Text("Fill Address Details", style: headingStyle),
                SizedBox(height: getProportionateScreenHeight(30)),
                addressIdToEdit == null
                    ? AddressDetailsForm(key: UniqueKey(), addressToEdit: null)
                    : FutureBuilder<Address>(
                        future: UserDatabaseHelper().getAddressFromId(
                          addressIdToEdit!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return AddressDetailsForm(
                              key: UniqueKey(),
                              addressToEdit: snapshot.data!,
                            );
                          } else if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return AddressDetailsForm(
                              key: UniqueKey(),
                              addressToEdit: null,
                            );
                          }
                          return AddressDetailsForm(
                            key: UniqueKey(),
                            addressToEdit: null,
                          );
                        },
                      ),
                SizedBox(height: getProportionateScreenHeight(40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
