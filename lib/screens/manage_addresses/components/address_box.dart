import 'package:fishkart/constants.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class AddressBox extends StatelessWidget {
  const AddressBox({required Key key, required this.addressId})
    : super(key: key);

  final String addressId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: FutureBuilder<Address>(
                future: UserDatabaseHelper().getAddressFromId(addressId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final address = snapshot.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address!.title ?? 'No Title',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        if (address.receiver != null &&
                            address.receiver!.isNotEmpty)
                          Text(
                            address.receiver!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (address.addressLine1 != null &&
                            address.addressLine1!.isNotEmpty)
                          Text(
                            address.addressLine1!,
                            style: TextStyle(fontSize: 16),
                          ),
                        if (address.addressLine2 != null &&
                            address.addressLine2!.isNotEmpty)
                          Text(
                            address.addressLine2!,
                            style: TextStyle(fontSize: 16),
                          ),
                        if (address.city != null && address.city!.isNotEmpty)
                          Text(
                            "City: ${address.city}",
                            style: TextStyle(fontSize: 16),
                          ),
                        if (address.district != null &&
                            address.district!.isNotEmpty)
                          Text(
                            "District: ${address.district}",
                            style: TextStyle(fontSize: 16),
                          ),
                        if (address.state != null && address.state!.isNotEmpty)
                          Text(
                            "State: ${address.state}",
                            style: TextStyle(fontSize: 16),
                          ),
                        if (address.landmark != null &&
                            address.landmark!.isNotEmpty)
                          Text(
                            "Landmark: ${address.landmark}",
                            style: TextStyle(fontSize: 16),
                          ),
                        if (address.pincode != null &&
                            address.pincode!.isNotEmpty)
                          Text(
                            "PIN: ${address.pincode}",
                            style: TextStyle(fontSize: 16),
                          ),
                        if (address.phone != null && address.phone!.isNotEmpty)
                          Text(
                            "Phone: ${address.phone}",
                            style: TextStyle(fontSize: 16),
                          ),
                      ],
                    );
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            kPrimaryColor,
                          ),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    final error = snapshot.error.toString();
                    Logger().e(error);
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Failed to load address",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Please try again later",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, color: kTextColor, size: 48),
                        SizedBox(height: 8),
                        Text(
                          "Address not found",
                          style: TextStyle(
                            color: kTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
