import 'dart:convert';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:flutter/material.dart';
import 'package:fishkart/models/OrderedProduct.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatelessWidget {
  String _normalizeStatus(String? status) {
    if (status == null || status.trim().isEmpty) return 'Pending';
    final s = status.trim().toLowerCase();
    if (s == 'completed') return 'Completed';
    if (s == 'pending') return 'Pending';
    if (s == 'cancelled' || s == 'rejected') return 'Cancelled';
    if (s == 'shipped') return 'Shipped';
    if (s == 'accepted') return 'Accepted';
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatOrderDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    DateTime? date;
    try {
      date = DateTime.tryParse(dateStr);
    } catch (_) {}
    if (date == null) return dateStr;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(date.year, date.month, date.day);
    final diff = orderDay.difference(today).inDays;
    String dayLabel;
    if (diff == 0) {
      dayLabel = 'Today';
    } else if (diff == -1) {
      dayLabel = 'Yesterday';
    } else if (diff == 1) {
      dayLabel = 'Tomorrow';
    } else {
      dayLabel =
          '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    }
    String hour = (date.hour % 12 == 0 ? 12 : date.hour % 12).toString();
    String minute = date.minute.toString().padLeft(2, '0');
    String ampm = date.hour < 12 ? 'AM' : 'PM';
    return '$dayLabel $hour:$minute $ampm';
  }

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

  Future<Map<String, dynamic>> _fetchOrderStatus(String orderId) async {
    final user = await AuthentificationService().currentUser;
    final doc = await UserDatabaseHelper().firestore
        .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
        .doc(user.uid)
        .collection(UserDatabaseHelper.ORDERED_PRODUCTS_COLLECTION_NAME)
        .doc(orderId)
        .get();
    return doc.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF1F5),
      body: FutureBuilder<Address?>(
        future: _fetchAddress(),
        builder: (context, addressSnapshot) {
          final address = addressSnapshot.data;
          return FutureBuilder<Product?>(
            future: _fetchProduct(),
            builder: (context, productSnapshot) {
              final product = productSnapshot.data;
              // Fetch order status from Firestore
              return FutureBuilder<Map<String, dynamic>>(
                future: _fetchOrderStatus(order.id),
                builder: (context, statusSnapshot) {
                  final statusData = statusSnapshot.data;
                  String status = order.status;
                  if (statusData != null && statusData['status'] != null) {
                    status = statusData['status'] as String;
                  }
                  String normalizedStatus = _normalizeStatus(status);
                  Color statusBgColor;
                  Color statusTextColor;
                  switch (normalizedStatus) {
                    case 'Completed':
                      statusBgColor = const Color(0xFFE6F9F0);
                      statusTextColor = const Color(0xFF1B8A5A);
                      break;
                    case 'Pending':
                      statusBgColor = const Color(0xFFFFF8E1);
                      statusTextColor = const Color(0xFFE6A100);
                      break;
                    case 'Cancelled':
                      statusBgColor = const Color(0xFFFFEBEE);
                      statusTextColor = const Color(0xFFD32F2F);
                      break;
                    case 'Accepted':
                      statusBgColor = const Color(0xFFE3F0FF);
                      statusTextColor = const Color(0xFF1976D2);
                      break;
                    case 'Shipped':
                      statusBgColor = const Color(0xFFEDE7F6);
                      statusTextColor = const Color(0xFF6C3FC7);
                      break;
                    default:
                      statusBgColor = Colors.grey.shade200;
                      statusTextColor = Colors.black54;
                  }
                  final price = product != null
                      ? (product.discountPrice ?? product.originalPrice ?? 0)
                      : 0;
                  final totalPrice = product != null
                      ? (price * order.quantity)
                      : 0.0;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40.h),
                        Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: Color(0xFF000000),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 18.w,
                            right: 24.w,
                            top: 5.h,
                            bottom: 20.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your order received!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Row(
                                children: [
                                  Text(
                                    'Order ID',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '#${order.id}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatOrderDate(order.orderDate),
                                style: TextStyle(
                                  color: Color(0xFF646161),
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${order.quantity} Items',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    '₹${totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 10),

                        // Products List
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < order.quantity; i++)
                                Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          height: 44,
                                          width: 44,
                                          child:
                                              product != null &&
                                                  product.images != null &&
                                                  product.images!.isNotEmpty
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
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    (product?.title ?? '-')
                                                        .split('/')[0]
                                                        .trim(),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 16,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Center(
                                                    child: Text(
                                                      '₹${price.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 16,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    (i + 1).toString().padLeft(
                                                      2,
                                                      '0',
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            SizedBox(height: 4),
                                            Text(
                                              'Net weight: ${product?.variant ?? '-'}',
                                              style: TextStyle(
                                                color: Color(0xFF646161),
                                                fontSize: 12,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              SizedBox(height: 18),

                              Text(
                                'Order Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'We expect to deliver \nthe order in 3 Hrs',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF646161),
                                        fontWeight: FontWeight.normal,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusBgColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: statusTextColor,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        normalizedStatus,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: statusTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 28.h),

                              // Help Section
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 28.h),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 22.sp,
                                      color: Color(0xFF374151),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Need help?',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 20.sp,
                                      color: Color(0xFF374151),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Have a question?',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Spacer(),

                        // 100% Fresh Guarantee Section at Bottom
                        Padding(
                          padding: EdgeInsets.only(
                            left: 24.w,
                            right: 24.w,
                            bottom: 18.h,
                            top: 8.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '100% Fresh Guarantee',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: 16.sp,
                                ),
                              ),
                              Text(
                                'Sourced daily from trusted vendors. Hygiene checked & quality certified.',
                                style: TextStyle(
                                  color: Color(0xFF646161),
                                  fontWeight: FontWeight.normal,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}
