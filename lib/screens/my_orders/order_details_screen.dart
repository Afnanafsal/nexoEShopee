import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fishkart/models/OrderedProduct.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderedProduct order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

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
        return Color(0xFF111827);
      case 'cancelled':
        return Color(0xFFD32F2F);
      default:
        return Color(0xFF111827);
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
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF294157)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Address?>(
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
                  final price = product != null
                      ? (product.discountPrice ?? product.originalPrice ?? 0)
                      : 0;
                  final totalPrice = product != null
                      ? (price * order.quantity)
                      : 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your order received!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF294157),
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Order ID  ',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '#${order.id}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF294157),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              order.orderDate ?? '-',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${order.quantity} items',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '₹${totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF294157),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // Products List
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Repeat the product item based on quantity
                              for (int i = 0; i < order.quantity; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(bottom: 10),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Show product image from base64
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: SizedBox(
                                                height: 44,
                                                width: 44,
                                                child:
                                                    product != null &&
                                                        product.images !=
                                                            null &&
                                                        product
                                                            .images!
                                                            .isNotEmpty
                                                    ? _buildProductImage(
                                                        product.images!.first,
                                                      )
                                                    : Container(
                                                        color: Colors.grey[200],
                                                        child: Icon(
                                                          Icons.image,
                                                          size: 20,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product?.title ?? '-',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Net weight: ${product?.variant ?? '-'}',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '₹${price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  order.quantity < 10
                                                      ? '0${order.quantity}'
                                                      : '${order.quantity}',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              SizedBox(height: 24),

                              // Order Status Section
                              Text(
                                'Order Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'We expect to deliver the order in 3 hrs',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 16),

                              // Status Label
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Color(0xFF111827),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  _statusLabel(order.status),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),

                              SizedBox(height: 24),

                              // Help Section
                              Divider(height: 1, color: Colors.grey[300]),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        backgroundColor: Colors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SizedBox(height: 18),
                                              Text(
                                                'Contact Vendor',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                              SizedBox(height: 18),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundColor: Color(
                                                        0xFF111827,
                                                      ).withOpacity(0.12),
                                                      child: Icon(
                                                        Icons.person,
                                                        color: Color(
                                                          0xFF111827,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            vendorName,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color: Color(
                                                                0xFF111827,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(height: 2),
                                                          Text(
                                                            vendorPhone,
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              color: Colors
                                                                  .grey[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              24,
                                                            ),
                                                        onTap: () async {
                                                          final phone =
                                                              vendorPhone
                                                                  .replaceAll(
                                                                    RegExp(
                                                                      r'[^0-9+]',
                                                                    ),
                                                                    '',
                                                                  );
                                                          final url =
                                                              'tel:$phone';
                                                          if (await canLaunch(
                                                            url,
                                                          )) {
                                                            await launch(url);
                                                          }
                                                        },
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(8),
                                                          decoration:
                                                              BoxDecoration(
                                                                color:
                                                                    Color(
                                                                      0xFF1B8A5A,
                                                                    ).withOpacity(
                                                                      0.12,
                                                                    ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                          child: Icon(
                                                            Icons.call,
                                                            color: Color(
                                                              0xFF1B8A5A,
                                                            ),
                                                            size: 24,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 24),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Color(
                                                      0xFF111827,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                  ),
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(),
                                                  child: Text(
                                                    'Close',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 22,
                                        color: Color(0xFF374151),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Need help?',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF111827),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Divider(height: 1, color: Colors.grey[300]),

                              GestureDetector(
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 20,
                                        color: Color(0xFF374151),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Have a question?',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF111827),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Divider(height: 1, color: Colors.grey[300]),
                            ],
                          ),
                        ),
                      ),

                      // 100% Fresh Guarantee Section at Bottom
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '100% Fresh Guarantee',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Sourced daily from trusted vendors. Hygiene checked & quality certified.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
