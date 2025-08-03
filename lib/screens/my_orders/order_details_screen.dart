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
      backgroundColor: Color(0xFFF5F6F9),
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
                  return Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 400),
                      color: Color(0xFFF5F6F9),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 18,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 16,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18.0,
                                      vertical: 18.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your order received!',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
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
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '#${order.id}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF294157),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          order.orderDate ?? '-',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                        SizedBox(height: 18),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${order.quantity} Item${order.quantity > 1 ? 's' : ''}',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '₹${totalPrice.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF294157),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        if (product != null)
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Color(0xFFF7F7F7),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  child: SizedBox(
                                                    height: 48,
                                                    width: 48,
                                                    child:
                                                        (product.images !=
                                                                null &&
                                                            product
                                                                .images!
                                                                .isNotEmpty)
                                                        ? _buildProductImage(
                                                            product
                                                                .images!
                                                                .first,
                                                          )
                                                        : Container(
                                                            color: Colors
                                                                .grey[200],
                                                            child: Icon(
                                                              Icons.image,
                                                              size: 24,
                                                              color:
                                                                  Colors.grey,
                                                            ),
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
                                                        product.title ?? '-',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                          color: Color(
                                                            0xFF294157,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        'Net weight: ${product.variant ?? '-'}',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Color(
                                                          0xFF294157,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      order.quantity < 10
                                                          ? '0${order.quantity}'
                                                          : '${order.quantity}',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        SizedBox(height: 18),
                                        Text(
                                          'Order Status',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _statusColor(
                                                  order.status,
                                                ).withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    order.status.toLowerCase() ==
                                                            'completed'
                                                        ? Icons.check_circle
                                                        : order.status
                                                                  .toLowerCase() ==
                                                              'pending'
                                                        ? Icons.hourglass_top
                                                        : order.status
                                                                  .toLowerCase() ==
                                                              'cancelled'
                                                        ? Icons.cancel
                                                        : Icons.info,
                                                    color: _statusColor(
                                                      order.status,
                                                    ),
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    _statusLabel(order.status),
                                                    style: TextStyle(
                                                      color: _statusColor(
                                                        order.status,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'We expect to deliver the order in 3 Hrs',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 18),
                                        Divider(
                                          height: 24,
                                          color: Colors.grey[300],
                                        ),
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            Icons.help_outline,
                                            color: Colors.black87,
                                          ),
                                          title: Text(
                                            'Need help?',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return Dialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          24,
                                                        ),
                                                  ),
                                                  backgroundColor: Colors.white,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          24.0,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        
                                                        SizedBox(height: 18),
                                                        Text(
                                                          'Contact Vendor',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 18,
                                                            color: Color(
                                                              0xFF294157,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(height: 18),
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .grey[100],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                                vertical: 12,
                                                              ),
                                                          child: Row(
                                                            children: [
                                                              CircleAvatar(
                                                                backgroundColor:
                                                                    Color(
                                                                      0xFF294157,
                                                                    ).withOpacity(
                                                                      0.12,
                                                                    ),
                                                                child: Icon(
                                                                  Icons.person,
                                                                  color: Color(
                                                                    0xFF294157,
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 12,
                                                              ),
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
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            16,
                                                                        color: Color(
                                                                          0xFF294157,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height: 2,
                                                                    ),
                                                                    Text(
                                                                      vendorPhone,
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            15,
                                                                        color: Colors
                                                                            .grey[700],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Material(
                                                                color: Colors
                                                                    .transparent,
                                                                child: InkWell(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        24,
                                                                      ),
                                                                  onTap: () async {
                                                                    final phone =
                                                                        vendorPhone.replaceAll(
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
                                                                      await launch(
                                                                        url,
                                                                      );
                                                                    }
                                                                  },
                                                                  child: Container(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                          8,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color: Color(
                                                                        0xFF1B8A5A,
                                                                      ).withOpacity(0.12),
                                                                      shape: BoxShape
                                                                          .circle,
                                                                    ),
                                                                    child: Icon(
                                                                      Icons
                                                                          .call,
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
                                                          width:
                                                              double.infinity,
                                                          child: ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Color(
                                                                    0xFF294157,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        14,
                                                                  ),
                                                            ),
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(),
                                                            child: Text(
                                                              'Close',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color: Colors.white
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
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Divider(
                                          height: 24,
                                          color: Colors.grey[300],
                                        ),
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            Icons.question_answer_outlined,
                                            color: Colors.black87,
                                          ),
                                          title: Text(
                                            'Have a question?',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          onTap: () {},
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Divider(
                                          height: 24,
                                          color: Colors.grey[300],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '100% Fresh Guarantee',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Sourced daily from trusted vendors. Hygiene checked & quality certified.',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

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
