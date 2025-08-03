import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fishkart/models/OrderedProduct.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatelessWidget {
  Widget _buildProductImage(String imageStr) {
    final isBase64 = !imageStr.startsWith('http');
    if (isBase64) {
      try {
        final bytes = base64Decode(imageStr);
        return Image.memory(bytes, height: 150, width: 150, fit: BoxFit.cover);
      } catch (e) {
        return Container(
          height: 150,
          width: 150,
          color: Colors.red[50],
          child: const Icon(
            Icons.broken_image,
            size: 54,
            color: Colors.redAccent,
          ),
        );
      }
    } else {
      return Image.network(
        imageStr,
        height: 150,
        width: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 150,
          width: 150,
          color: Colors.red[50],
          child: const Icon(
            Icons.broken_image,
            size: 54,
            color: Colors.redAccent,
          ),
        ),
      );
    }
  }

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF294157)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Order Details',
          style: TextStyle(
            color: Color(0xFF294157),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Color(0xFFF5F6F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
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
                      return SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 32,
                                offset: Offset(0, 12),
                              ),
                            ],
                            border: Border.all(
                              color: Color(0xFFE0E3E7),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(
                                        order.status,
                                      ).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
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
                                          size: 22,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          _statusLabel(order.status),
                                          style: TextStyle(
                                            color: _statusColor(order.status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 22),
                              if (product != null) ...[
                                Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 16,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child:
                                          (product.images != null &&
                                              product.images!.isNotEmpty)
                                          ? _buildProductImage(
                                              product.images!.first,
                                            )
                                          : Container(
                                              height: 150,
                                              width: 150,
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.image,
                                                size: 54,
                                                color: Colors.grey,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 18),
                                Center(
                                  child: Text(
                                    product.title ?? '-',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: Color(0xFF294157),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                if (product.variant != null)
                                  Center(
                                    child: Container(
                                      margin: EdgeInsets.only(top: 4),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        product.variant!,
                                        style: TextStyle(
                                          color: Colors.blueGrey[700],
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                              SizedBox(height: 22),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ...removed Order ID display...
                                    SizedBox(height: 10),
                                    _infoRow(
                                      'Order Date',
                                      order.orderDate ?? '-',
                                    ),
                                    SizedBox(height: 10),
                                    _infoRow('Quantity', '${order.quantity}'),
                                    SizedBox(height: 10),
                                    _infoRow('Vendor', vendorName),
                                    SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: _infoRow(
                                            'Vendor Phone',
                                            vendorPhone,
                                            isLast: true,
                                          ),
                                        ),
                                        if (order.status.toLowerCase() ==
                                                'pending' &&
                                            vendorPhone != '-')
                                          IconButton(
                                            icon: Icon(
                                              Icons.call,
                                              color: Colors.green,
                                              size: 22,
                                            ),
                                            onPressed: () {
                                              final uri = Uri.parse(
                                                'tel:$vendorPhone',
                                              );
                                              launchUrl(uri);
                                            },
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Delivery Address',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                    ),
                                    address != null
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2.0,
                                            ),
                                            child: Text(
                                              '${address.addressLine1}, ${address.city}, ${address.state}, ${address.pincode}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Color(0xFF294157),
                                              ),
                                            ),
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2.0,
                                            ),
                                            child: Text(
                                              '-',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Color(0xFF294157),
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 28),
                              Container(
                                width: double.infinity,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[50],
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueGrey.withOpacity(0.10),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 22),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Thank you for ordering!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Color(0xFF294157),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Color(
                                          0xFF294157,
                                        ).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.local_shipping,
                                        color: Color(0xFF294157),
                                        size: 26,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 32),
                            ],
                          ),
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

  // Helper widget for info rows
  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF294157),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
