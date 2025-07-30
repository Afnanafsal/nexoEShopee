import 'package:flutter/material.dart';
import 'package:fishkart/models/OrderedProduct.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatelessWidget {
  Future<Product?> _fetchProduct() async {
    if (order.productUid != null) {
      try {
        return await ProductDatabaseHelper().getProductWithID(
          order.productUid!,
        );
      } catch (_) {}
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchVendor(String? vendorId) async {
    if (vendorId != null) {
      try {
        final doc = await UserDatabaseHelper().firestore
            .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
            .doc(vendorId)
            .get();
        return doc.data();
      } catch (_) {}
    }
    return null;
  }

  final OrderedProduct order;
  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  Future<Address?> _fetchAddress() async {
    if (order.addressId != null) {
      try {
        return await UserDatabaseHelper().getAddressFromId(order.addressId!);
      } catch (_) {}
    }
    return null;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Color(0xFF1B8A5A);
      case 'pending':
        return Color(0xFFE6A100);
      case 'cancelled':
        return Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      backgroundColor: Color(0xFFF5F6F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Address?>(
            future: _fetchAddress(),
            builder: (context, addressSnapshot) {
              final address = addressSnapshot.data;
              return FutureBuilder<Product?>(
                future: _fetchProduct(),
                builder: (context, productSnapshot) {
                  final product = productSnapshot.data;
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _fetchVendor(order.vendorId),
                    builder: (context, vendorSnapshot) {
                      final vendor = vendorSnapshot.data;
                      final vendorName = vendor?['display_name'] ?? '-';
                      final vendorPhone = vendor?['phone'] ?? '-';
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      order.status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        order.status.toLowerCase() ==
                                                'completed'
                                            ? Icons.check_circle
                                            : order.status.toLowerCase() ==
                                                  'pending'
                                            ? Icons.hourglass_bottom
                                            : Icons.cancel,
                                        color: _statusColor(order.status),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _statusLabel(order.status),
                                        style: TextStyle(
                                          color: _statusColor(order.status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 18),
                            if (product != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child:
                                    product.images != null &&
                                        product.images!.isNotEmpty
                                    ? Image.network(
                                        product.images!.first,
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 120,
                                        width: 120,
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.image,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                product.title ?? '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              if (product.variant != null)
                                Text(
                                  product.variant!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 15,
                                  ),
                                ),
                            ],
                            SizedBox(height: 18),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ...removed Order ID display...
                                  SizedBox(height: 12),
                                  Text(
                                    'Order Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    order.orderDate ?? '-',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Quantity',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${order.quantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Vendor',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    vendorName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Vendor Phone',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        vendorPhone,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (order.status.toLowerCase() ==
                                              'pending' &&
                                          vendorPhone != '-')
                                        IconButton(
                                          icon: Icon(
                                            Icons.call,
                                            color: Colors.green,
                                          ),
                                          onPressed: () {
                                            final uri = Uri.parse(
                                              'tel:$vendorPhone',
                                            );
                                            // ignore: deprecated_member_use
                                            launchUrl(uri);
                                          },
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Delivery Address',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  address != null
                                      ? Text(
                                          '${address.addressLine1}, ${address.city}, ${address.state}, ${address.pincode}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        )
                                      : Text(
                                          '-',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Thank you for ordering!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF294157),
                                    ),
                                  ),
                                  Icon(
                                    Icons.local_shipping,
                                    color: Color(0xFF294157),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
