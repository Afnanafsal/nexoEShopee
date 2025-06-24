import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Address.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:flutter/material.dart';

import 'address_details_form.dart';

class Body extends StatelessWidget {
  final String addressIdToEdit;

  const Body({required Key key, required this.addressIdToEdit}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(screenPadding)),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(height: getProportionateScreenHeight(20)),
                Text(
                  "Fill Address Details",
                  style: headingStyle,
                ),
                SizedBox(height: getProportionateScreenHeight(30)),
                addressIdToEdit == null
                    ? AddressDetailsForm(
                        key: UniqueKey(),
                        addressToEdit: null!,
                      )
                    : FutureBuilder<Address>(
                        future: UserDatabaseHelper()
                            .getAddressFromId(addressIdToEdit),
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
                              addressToEdit: null!,
                            );
                          }
                          return AddressDetailsForm(
                            key: UniqueKey(),
                            addressToEdit: null!,
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
