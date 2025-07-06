import 'package:flutter/material.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/screens/manage_addresses/manage_addresses_screen.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:logger/logger.dart';

class DeliveryAddressBar extends StatelessWidget {
  const DeliveryAddressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                FutureBuilder<String>(
                  future: _getDeliveryAddress(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    } else if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Text(
                        "Loading...",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[400],
                        ),
                      );
                    } else {
                      return Text(
                        "Add delivery address",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryColor,
                        ),
                      );
                    }
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

  Future<String> _getDeliveryAddress() async {
    try {
      final addressIds = await UserDatabaseHelper().addressesList;
      if (addressIds.isEmpty) {
        return "Add delivery address";
      }

      // Get the first address as default delivery address
      final address = await UserDatabaseHelper().getAddressFromId(
        addressIds.first,
      );

      // Format the address for display
      String formattedAddress = "";

      if (address.addressLine1 != null && address.addressLine1!.isNotEmpty) {
        formattedAddress += address.addressLine1!;
      }

      if (address.city != null && address.city!.isNotEmpty) {
        if (formattedAddress.isNotEmpty) formattedAddress += ", ";
        formattedAddress += address.city!;
      }

      if (address.state != null && address.state!.isNotEmpty) {
        if (formattedAddress.isNotEmpty) formattedAddress += ", ";
        formattedAddress += address.state!;
      }

      if (address.pincode != null && address.pincode!.isNotEmpty) {
        if (formattedAddress.isNotEmpty) formattedAddress += " - ";
        formattedAddress += address.pincode!;
      }

      return formattedAddress.isNotEmpty
          ? formattedAddress
          : "Address not available";
    } catch (e) {
      Logger().e("Error fetching delivery address: $e");
      return "Add delivery address";
    }
  }
}
