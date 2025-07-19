import 'package:flutter/material.dart';
// ...existing code...
import 'package:nexoeshopee/providers/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/screens/manage_addresses/manage_addresses_screen.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/size_config.dart';
// ...existing code...

// Provider to fetch address by selected ID
final selectedAddressFutureProvider = FutureProvider.autoDispose((ref) async {
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
                  addressAsync.when(
                    data: (address) {
                      String formattedAddress = selectedAddressId;
                      if (address != null) {
                        formattedAddress = [
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
