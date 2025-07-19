import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/providers/user_providers.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/screens/manage_addresses/manage_addresses_screen.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:logger/logger.dart';

class DeliveryAddressBar extends ConsumerWidget {
  const DeliveryAddressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAddressId = ref.watch(selectedAddressIdProvider);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
        vertical: getProportionateScreenHeight(8),
      ),
      decoration: BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Icon(Icons.location_on, color: kPrimaryColor, size: 20),
          SizedBox(width: getProportionateScreenWidth(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fresh Meat Delivery to",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (selectedAddressId == null)
                  Text(
                    "Add delivery address",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  )
                else
                  FutureBuilder(
                    future: UserDatabaseHelper().getAddressFromId(
                      selectedAddressId,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Text(
                          "Loading...",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[400],
                          ),
                        );
                      }
                      final address = snapshot.data;
                      String formattedAddress = selectedAddressId;
                      if (address != null) {
                        formattedAddress =
                            [
                                  address.addressLine1,
                                  address.city,
                                  address.state,
                                  address.pincode,
                                ]
                                .whereType<String>()
                                .where((e) => e.isNotEmpty)
                                .join(', ');
                      }
                      return Text(
                        formattedAddress,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageAddressesScreen(),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: kPrimaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
