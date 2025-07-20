import 'package:flutter/material.dart';
// ...existing code...
import 'package:nexoeshopee/providers/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/screens/manage_addresses/manage_addresses_screen.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/size_config.dart';

final selectedAddressFutureProvider = FutureProvider((ref) async {
  final selectedAddressId = ref.watch(selectedAddressIdProvider);
  if (selectedAddressId == null) return null;
  return await UserDatabaseHelper().getAddressFromId(selectedAddressId);
});

class DeliveryAddressBar extends ConsumerWidget {
  const DeliveryAddressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAddressId = ref.watch(selectedAddressIdProvider);
    final addressAsync = ref.watch(selectedAddressFutureProvider);
    return Container(
      padding: EdgeInsets.only(
        right: getProportionateScreenWidth(10),
        top: getProportionateScreenHeight(8),
        bottom: getProportionateScreenHeight(8),
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
                addressAsync.when(
                  data: (address) {
                    String title = "Address";
                    if (address != null &&
                        address.title != null &&
                        address.title!.isNotEmpty) {
                      title = address.title!;
                    }
                    return Text(
                        "${title[0].toUpperCase()}${title.substring(1)}",
                      style: TextStyle(
                      fontSize: 16,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                  loading: () => Text(
                    "Loading...",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  error: (err, stack) => Text(
                    "Error loading address",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (selectedAddressId == null)
                  Text(
                    "Add delivery address",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  )
                else
                  addressAsync.when(
                    data: (address) {
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
                    loading: () => Text(
                      "Loading...",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[400],
                      ),
                    ),
                    error: (err, stack) => Text(
                      "Error loading address",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
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
            child: Icon(
              Icons.keyboard_arrow_down,
              color: kPrimaryColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
