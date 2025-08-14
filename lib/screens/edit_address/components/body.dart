import 'package:fishkart/constants.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                // Back icon directly above heading
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black,
                    size: 22.sp,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Fill Address Details",
                  style: headingStyle.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 30.h),
                addressIdToEdit == null
                    ? AddressDetailsForm(addressToEdit: null)
                    : FutureBuilder<Address>(
                        future: UserDatabaseHelper().getAddressFromId(
                          addressIdToEdit!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return AddressDetailsForm(
                              addressToEdit: snapshot.data!,
                            );
                          } else if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return AddressDetailsForm(addressToEdit: null);
                          }
                          return AddressDetailsForm(addressToEdit: null);
                        },
                      ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
