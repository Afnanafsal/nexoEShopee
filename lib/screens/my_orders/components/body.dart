import 'package:fishkart/components/nothingtoshow_container.dart';
import 'package:fishkart/components/product_short_detail_card.dart';
import 'package:fishkart/constants.dart';
import 'package:fishkart/models/OrderedProduct.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/models/Review.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/screens/my_orders/order_details_screen.dart';
import 'package:fishkart/screens/my_orders/components/product_review_dialog.dart';
import 'package:fishkart/screens/product_details/product_details_screen.dart';
import '../order_details_screen.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/services/cache/hive_service.dart';
import 'package:fishkart/size_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  int _selectedTabIndex = 0;
  final List<String> _orderTabs = ['Completed', 'Pending', 'Cancelled'];
  List<String> _addresses = [];
  String? _selectedAddressId;
  late final String currentUserUid;
  final HiveService _hiveService = HiveService.instance;

  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  final List<OrderedProduct> _allOrders = [];

  // Cache for base64 images
  final Map<String, String> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _fetchAddresses();
  }

  void _initializeUser() {
    final user = AuthentificationService().currentUser;
    currentUserUid = user.uid;
  }

  Future<void> _fetchAddresses() async {
    try {
      final addresses = await UserDatabaseHelper().addressesList;
      setState(() {
        _addresses = addresses;
        if (_addresses.isNotEmpty) {
          _selectedAddressId = _addresses.first;
        }
      });
    } catch (e) {
      Logger().e('Error fetching addresses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F5),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFEFF1F5),
            padding: const EdgeInsets.only(
              top: 32,
              left: 0,
              right: 0,
              bottom: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                          size: 22,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 0),
                  child: Text(
                    'Your Orders',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  color: const Color(0xFFEFF1F5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _orderTabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final isSelected = _selectedTabIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedTabIndex = index),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tab,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: isSelected
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (isSelected)
                                  Container(
                                    height: 2,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshPage,
              child: buildOrderedProductsList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> refreshPage() async {
    setState(() {
      _allOrders.clear();
      _lastDocument = null;
    });
    await _loadMoreOrders();
  }

  Future<List<OrderedProduct>> _loadMoreOrders() async {
    if (_isLoadingMore) return [];

    _isLoadingMore = true;
    try {
      Query query = FirebaseFirestore.instance
          .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
          .doc(currentUserUid)
          .collection(UserDatabaseHelper.ORDERED_PRODUCTS_COLLECTION_NAME)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();

      Logger().i('_loadMoreOrders: Found ${querySnapshot.docs.length} orders');

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        final newOrders = querySnapshot.docs.map((doc) {
          return OrderedProduct.fromMap(
            doc.data() as Map<String, dynamic>,
            id: doc.id,
          );
        }).toList();

        _allOrders.addAll(newOrders);
        return newOrders;
      }
    } catch (e) {
      Logger().e('Error loading more orders: $e');
    } finally {
      _isLoadingMore = false;
    }
    return [];
  }

  Widget buildOrderedProductsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
          .doc(currentUserUid)
          .collection(UserDatabaseHelper.ORDERED_PRODUCTS_COLLECTION_NAME)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var orderedProductsDocs = snapshot.data!.docs;
          // Show all orders regardless of address

          String normalizeStatus(String? status) {
            if (status == null || status.trim().isEmpty) return 'Pending';
            final s = status.trim().toLowerCase();
            if (s == 'completed') return 'Completed';
            if (s == 'pending') return 'Pending';
            if (s == 'cancelled' || s == 'rejected') return 'Cancelled';
            if (s == 'shipped') return 'Shipped';
            if (s == 'accepted') return 'Accepted';
            return s[0].toUpperCase() + s.substring(1);
          }

          // Filter by tab
          if (_selectedTabIndex == 0) {
            orderedProductsDocs = orderedProductsDocs
                .where(
                  (doc) => normalizeStatus(doc.data()['status']) == 'Completed',
                )
                .toList();
          } else if (_selectedTabIndex == 1) {
            orderedProductsDocs = orderedProductsDocs
                .where(
                  (doc) => normalizeStatus(doc.data()['status']) == 'Pending',
                )
                .toList();
          } else if (_selectedTabIndex == 2) {
            orderedProductsDocs = orderedProductsDocs
                .where(
                  (doc) => normalizeStatus(doc.data()['status']) == 'Cancelled',
                )
                .toList();
          }

          // Sort by order date descending
          orderedProductsDocs.sort((a, b) {
            final aDate = a.data()[OrderedProduct.ORDER_DATE_KEY] as String?;
            final bDate = b.data()[OrderedProduct.ORDER_DATE_KEY] as String?;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });

          if (orderedProductsDocs.isEmpty) {
            return const Center(
              child: NothingToShowContainer(
                iconPath: "assets/icons/empty_bag.svg",
                secondaryMessage: "No orders found",
              ),
            );
          }

          // Group by date
          Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
          grouped = {};
          for (var doc in orderedProductsDocs) {
            final date =
                doc.data()[OrderedProduct.ORDER_DATE_KEY] as String? ?? '';
            grouped.putIfAbsent(date, () => []).add(doc);
          }

          String formatOrderDate(String isoDate) {
            try {
              final dt = DateTime.parse(isoDate);
              final day = dt.day.toString().padLeft(2, '0');
              final month = dt.month.toString().padLeft(2, '0');
              final year = dt.year;
              return '$day/$month/$year';
            } catch (e) {
              return isoDate;
            }
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: grouped.entries.length,
            itemBuilder: (context, groupIndex) {
              final entry = grouped.entries.elementAt(groupIndex);

              // Group products by order date
              Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
              orderGroups = {};
              for (var doc in entry.value) {
                final orderId = doc.id; // Use document ID as order identifier
                orderGroups.putIfAbsent(orderId, () => []).add(doc);
              }

              // Only show date if there are products for that date
              final hasProducts = orderGroups.entries.any(
                (orderEntry) => orderEntry.value.isNotEmpty,
              );
              if (!hasProducts) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Row(
                      children: [
                        const Text(
                          'Ordered on: ',
                          style: TextStyle(
                            color: Color(0xFF646161),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          formatOrderDate(entry.key),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...orderGroups.entries.map((orderEntry) {
                    if (orderEntry.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: orderEntry.value.asMap().entries.map((
                          productEntry,
                        ) {
                          final index = productEntry.key;
                          final doc = productEntry.value;
                          final isLast = index == orderEntry.value.length - 1;

                          final order = OrderedProduct.fromMap(
                            doc.data(),
                            id: doc.id,
                          );

                          return Container(
                            decoration: BoxDecoration(
                              border: !isLast
                                  ? Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade100,
                                      ),
                                    )
                                  : null,
                            ),
                            child: buildOrderItem(order, isLast),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        } else if (snapshot.hasError) {
          final error = snapshot.error;
          Logger().w('Firestore error: ${error.toString()}');
          return const Center(
            child: NothingToShowContainer(
              iconPath: "assets/icons/network_error.svg",
              primaryMessage: "Something went wrong",
              secondaryMessage: "Unable to load orders. Please try again.",
            ),
          );
        }
        return const Center(
          child: NothingToShowContainer(
            iconPath: "assets/icons/network_error.svg",
            primaryMessage: "Something went wrong",
            secondaryMessage: "Unable to connect to Database",
          ),
        );
      },
    );
  }

  Widget buildOrderItem(OrderedProduct order, bool isLast) {
    return FutureBuilder<Product?>(
      future: _getProductWithCaching(order.productUid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerItem();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final product = snapshot.data!;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OrderDetailsScreen(key: UniqueKey(), order: order),
              ),
            ).then((_) async {
              await refreshPage();
            });
          },
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Image - Fill card, no margin
                  Container(
                    width: 120,
                    height: 120,
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FutureBuilder<Widget>(
                      future: _buildProductImage(product),
                      builder: (context, imageSnapshot) {
                        if (imageSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          );
                        }
                        return imageSnapshot.data ?? Container();
                      },
                    ),
                  ),
                  SizedBox(width: 14),
                  // Product Details - Flexible content
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(
                        right: 16,
                        top: 12,
                        bottom: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top section with title and price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.title?.split('/').first.trim() ??
                                          'Product',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${product.discountPrice?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Net weight: ${product.variant ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF646161),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<Address?>(
                                future: UserDatabaseHelper().getAddressFromId(
                                  order.addressId ?? '',
                                ),
                                builder: (context, snapshot) {
                                  final addressTitle =
                                      snapshot.hasData && snapshot.data != null
                                      ? (snapshot.data!.title ??
                                            snapshot.data!.addressLine1 ??
                                            '')
                                      : '';
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Color(0xFF646161),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          addressTitle,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF646161),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          // Bottom section with review button
                          Align(
                            alignment: Alignment.bottomRight,
                            child: InkWell(
                              onTap: () => _showReviewDialog(product),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Add Product Review',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kPrimaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.add,
                                      size: 14,
                                      color: kPrimaryColor,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: List.generate(2, (i) => _buildShimmerItem())),
        );
      },
    );
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 12, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Container(width: 80, height: 16, color: Colors.grey[300]),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReviewDialog(Product product) async {
    String currentUserUid = AuthentificationService().currentUser.uid;
    Review? prevReview;

    try {
      prevReview = await ProductDatabaseHelper().getProductReviewWithID(
        product.id,
        currentUserUid,
      );
    } on FirebaseException catch (e) {
      Logger().w("Firebase Exception: $e");
    } catch (e) {
      Logger().w("Unknown Exception: $e");
    }

    if (prevReview == null) {
      prevReview = Review(currentUserUid, reviewerUid: currentUserUid);
    }

    final result = await showDialog(
      context: context,
      builder: (context) {
        return ProductReviewDialog(key: UniqueKey(), review: prevReview!);
      },
    );

    if (result is Review) {
      bool reviewAdded = false;
      String snackbarMessage = "Unknown error occurred";

      try {
        reviewAdded = await ProductDatabaseHelper().addProductReview(
          product.id,
          result,
        );
        if (reviewAdded == true) {
          snackbarMessage = "Product review added successfully";
        } else {
          throw "Couldn't add product review due to unknown reason";
        }
      } on FirebaseException catch (e) {
        Logger().w("Firebase Exception: $e");
        snackbarMessage = e.toString();
      } catch (e) {
        Logger().w("Unknown Exception: $e");
        snackbarMessage = e.toString();
      } finally {
        Logger().i(snackbarMessage);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }

    await refreshPage();
  }

  // Keep the existing buildOrderedProductItem method for compatibility
  Widget buildOrderedProductItem(OrderedProduct orderedProduct) {
    return buildOrderItem(orderedProduct, true);
  }

  Future<Product?> _getProductWithCaching(String productId) async {
    // First try to get from cache
    final cachedProduct = _hiveService.getCachedProduct(productId);
    if (cachedProduct != null) {
      return cachedProduct;
    }

    // If not in cache, fetch from Firestore
    try {
      final product = await ProductDatabaseHelper().getProductWithID(productId);
      if (product != null) {
        // Cache the product for future use
        await _hiveService.cacheProduct(product);
        return product;
      }
    } catch (e) {
      Logger().e('Error fetching product $productId: $e');
    }
    return null;
  }

  Future<String?> _convertImageToBase64(String imageUrl) async {
    try {
      // Check if already cached
      if (_imageCache.containsKey(imageUrl)) {
        return _imageCache[imageUrl];
      }

      // Fetch image from URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final base64String = base64Encode(bytes);

        // Cache the result
        _imageCache[imageUrl] = base64String;

        return base64String;
      }
    } catch (e) {
      Logger().e('Error converting image to base64: $e');
    }
    return null;
  }

  Future<Widget> _buildProductImage(Product product) async {
    try {
      String? base64String;
      if (product.images != null && product.images!.isNotEmpty) {
        base64String = product.images!.first;
        Logger().i(
          'Trying to decode base64 from product.images: ${base64String.substring(0, 30)}...',
        );
      }

      if (base64String != null && base64String.isNotEmpty) {
        try {
          final bytes = base64Decode(base64String);
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              image: DecorationImage(
                image: MemoryImage(bytes),
                fit: BoxFit.cover,
              ),
            ),
          );
        } catch (e) {
          Logger().e('Base64 decode/render error: $e');
        }
      }
    } catch (e) {
      Logger().e('Error in _buildProductImage: $e');
    }
    // Fallback to placeholder
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 32),
    );
  }
}
