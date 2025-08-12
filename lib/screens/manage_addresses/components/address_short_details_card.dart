import 'package:shimmer/shimmer.dart';
import 'package:fishkart/constants.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/size_config.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class AddressShortDetailsCard extends StatelessWidget {
  final String addressId;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AddressShortDetailsCard({
    required Key key,
    required this.addressId,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: FutureBuilder<Address>(
          future: UserDatabaseHelper().getAddressFromId(addressId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final address = snapshot.data;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          address?.title ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getAddressLine(address),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Trailing edit icon
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      Container(width: 24, height: 24, color: Colors.white),
                    ],
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              final error = snapshot.error.toString();
              Logger().e(error);
            }
            return Center(
              child: Icon(Icons.error, size: 40, color: kTextColor),
            );
          },
        ),
      ),
    );
  }

  static String _getAddressLine(Address? address) {
    if (address == null) return '';
    // Compose a single line from available fields, similar to screenshot
    final List<String> parts = [];
    if (address.addressLine1 != null && address.addressLine1!.isNotEmpty) {
      parts.add(address.addressLine1!);
    }
    if (address.addressLine2 != null && address.addressLine2!.isNotEmpty) {
      parts.add(address.addressLine2!);
    }
    if (address.city != null && address.city!.isNotEmpty) {
      parts.add(address.city!);
    }
    if (address.pincode != null && address.pincode!.isNotEmpty) {
      parts.add(address.pincode!);
    }
    return parts.join(', ');
  }
}
