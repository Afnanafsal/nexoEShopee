import 'package:fishkart/components/nothingtoshow_container.dart';
import 'package:fishkart/components/product_short_detail_card.dart';
import 'package:fishkart/constants.dart';
import 'package:fishkart/models/OrderedProduct.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/models/Review.dart';
import 'package:fishkart/models/Address.dart';
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

// ...existing code...

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  int _selectedTabIndex = 0;
  final List<String> _orderTabs = [
    'All Orders',
    'Pending',
    'Completed',
    'Accepted',
    'Shipped',
    'Cancelled',
  ];
  List<String> _addresses = [];
  String? _selectedAddressId;
  late final String currentUserUid;
  final HiveService _hiveService = HiveService.instance;

  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  final List<OrderedProduct> _allOrders = [];

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
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refreshPage,
        child: Container(
          color: const Color(0xFFF7F8FA),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(0),
              vertical: getProportionateScreenHeight(0),
            ),
            children: [
              const SizedBox(height: 12),
              // Top bar: back button and address selector
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _addresses.isEmpty
                        ? const SizedBox.shrink()
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            child: _addresses.length > 1
                                ? DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedAddressId,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.black54,
                                      ),
                                      isExpanded: true,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                      items: _addresses.map((addressId) {
                                        return DropdownMenuItem<String>(
                                          value: addressId,
                                          child: FutureBuilder<Address>(
                                            future: UserDatabaseHelper()
                                                .getAddressFromId(addressId),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData &&
                                                  snapshot.data != null) {
                                                final address = snapshot.data!;
                                                return Flexible(
                                                  child: Text(
                                                    address.title ??
                                                        address.addressLine1 ??
                                                        addressId,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                );
                                              }
                                              return Flexible(
                                                child: Text(
                                                  addressId,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAddressId = value;
                                        });
                                      },
                                    ),
                                  )
                                : FutureBuilder<Address>(
                                    future: UserDatabaseHelper()
                                        .getAddressFromId(_addresses.first),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        final address = snapshot.data!;
                                        return Flexible(
                                          child: Text(
                                            address.title ??
                                                address.addressLine1 ??
                                                _addresses.first,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Tab bar
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _orderTabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = _selectedTabIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? kPrimaryColor.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: selected
                              ? Border.all(color: kPrimaryColor, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          _orderTabs[i],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected ? kPrimaryColor : Colors.black54,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: SizeConfig.screenHeight * 0.75,
                child: buildOrderedProductsList(),
              ),
            ],
          ),
        ),
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
          if (_selectedAddressId != null) {
            orderedProductsDocs = orderedProductsDocs.where((doc) {
              final addressId = doc.data()['address_id'] as String?;
              return addressId == _selectedAddressId;
            }).toList();
          }

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
            // All Orders
          } else if (_selectedTabIndex == 1) {
            orderedProductsDocs = orderedProductsDocs
                .where(
                  (doc) => normalizeStatus(doc.data()['status']) == 'Pending',
                )
                .toList();
          } else if (_selectedTabIndex == 2) {
            orderedProductsDocs = orderedProductsDocs
                .where(
                  (doc) => normalizeStatus(doc.data()['status']) == 'Completed',
                )
                .toList();
          } else if (_selectedTabIndex == 3) {
            orderedProductsDocs = orderedProductsDocs
                .where(
                  (doc) => normalizeStatus(doc.data()['status']) == 'Accepted',
                )
                .toList();
          } else if (_selectedTabIndex == 4) {
            orderedProductsDocs = orderedProductsDocs
                .where(
                  (doc) => normalizeStatus(doc.data()['status']) == 'Shipped',
                )
                .toList();
          } else if (_selectedTabIndex == 5) {
            orderedProductsDocs = orderedProductsDocs
                .where(
                  (doc) => normalizeStatus(doc.data()['status']) == 'Cancelled',
                )
                .toList();
          }

          // Sort strictly by most recent order date descending
          orderedProductsDocs.sort((a, b) {
            final aDate = a.data()[OrderedProduct.ORDER_DATE_KEY] as String?;
            final bDate = b.data()[OrderedProduct.ORDER_DATE_KEY] as String?;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });

          if (orderedProductsDocs.isEmpty) {
            return Center(
              child: NothingToShowContainer(
                iconPath: "assets/icons/empty_bag.svg",
                secondaryMessage: "Order something to show here",
              ),
            );
          }

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
              int hour = dt.hour;
              final minute = dt.minute.toString().padLeft(2, '0');
              final ampm = hour >= 12 ? 'PM' : 'AM';
              hour = hour % 12;
              if (hour == 0) hour = 12;
              final hourStr = hour.toString().padLeft(2, '0');
              final day = dt.day.toString().padLeft(2, '0');
              final month = dt.month.toString().padLeft(2, '0');
              final year = dt.year.toString().substring(2);
              return '$hourStr:$minute $ampm $day-$month-$year';
            } catch (e) {
              return isoDate;
            }
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            children: grouped.entries.map((entry) {
              Map<String, int> productCounts = {};
              Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
              productDocs = {};
              for (var doc in entry.value) {
                final pid =
                    doc.data()[OrderedProduct.PRODUCT_UID_KEY] as String?;
                if (pid != null) {
                  productCounts[pid] = (productCounts[pid] ?? 0) + 1;
                  productDocs[pid] = doc;
                }
              }
              final firstDoc = entry.value.isNotEmpty
                  ? entry.value.first
                  : null;
              final status = firstDoc != null
                  ? normalizeStatus(firstDoc.data()['status'])
                  : 'Pending';
              Color statusBgColor;
              Color statusTextColor;
              switch (status) {
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
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 2,
                        bottom: 2,
                        top: 2,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  status == 'Completed'
                                      ? Icons.check_circle
                                      : status == 'Pending'
                                      ? Icons.hourglass_bottom
                                      : status == 'Accepted'
                                      ? Icons.verified
                                      : status == 'Shipped'
                                      ? Icons.local_shipping
                                      : Icons.cancel,
                                  color: statusTextColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: statusTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  formatOrderDate(entry.key),
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 2,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        child: Column(
                          children: productCounts.keys.map((pid) {
                            final doc = productDocs[pid];
                            if (doc == null) return const SizedBox.shrink();
                            final order = OrderedProduct.fromMap(
                              doc.data(),
                              id: doc.id,
                            );
                            return FutureBuilder<Product?>(
                              future: _getProductWithCaching(pid),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return SizedBox(
                                    height: 70,
                                    child: Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  height: 16,
                                                  color: Colors.grey[300],
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  width: 80,
                                                  height: 12,
                                                  color: Colors.grey[300],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data == null) {
                                  return const SizedBox.shrink();
                                }
                                final product = snapshot.data!;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ProductShortDetailCard(
                                          productId: product.id,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    OrderDetailsScreen(
                                                      key: UniqueKey(),
                                                      order: order,
                                                    ),
                                              ),
                                            ).then((_) async {
                                              await refreshPage();
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        children: [
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: kPrimaryColor,
                                              side: BorderSide(
                                                color: kPrimaryColor
                                                    .withOpacity(0.5),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 2,
                                                  ),
                                            ),
                                            onPressed: () async {
                                              String currentUserUid =
                                                  AuthentificationService()
                                                      .currentUser
                                                      .uid;
                                              Review? prevReview;
                                              try {
                                                prevReview =
                                                    await ProductDatabaseHelper()
                                                        .getProductReviewWithID(
                                                          product.id,
                                                          currentUserUid,
                                                        );
                                              } on FirebaseException catch (e) {
                                                Logger().w(
                                                  "Firebase Exception: $e",
                                                );
                                              } catch (e) {
                                                Logger().w(
                                                  "Unknown Exception: $e",
                                                );
                                              }
                                              if (prevReview == null) {
                                                prevReview = Review(
                                                  currentUserUid,
                                                  reviewerUid: currentUserUid,
                                                );
                                              }
                                              final result = await showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return ProductReviewDialog(
                                                    key: UniqueKey(),
                                                    review: prevReview!,
                                                  );
                                                },
                                              );
                                              if (result is Review) {
                                                bool reviewAdded = false;
                                                String snackbarMessage =
                                                    "Unknown error occurred";
                                                try {
                                                  reviewAdded =
                                                      await ProductDatabaseHelper()
                                                          .addProductReview(
                                                            product.id,
                                                            result,
                                                          );
                                                  if (reviewAdded == true) {
                                                    snackbarMessage =
                                                        "Product review added successfully";
                                                  } else {
                                                    throw "Coulnd't add product review due to unknown reason";
                                                  }
                                                } on FirebaseException catch (
                                                  e
                                                ) {
                                                  Logger().w(
                                                    "Firebase Exception: $e",
                                                  );
                                                  snackbarMessage = e
                                                      .toString();
                                                } catch (e) {
                                                  Logger().w(
                                                    "Unknown Exception: $e",
                                                  );
                                                  snackbarMessage = e
                                                      .toString();
                                                } finally {
                                                  Logger().i(snackbarMessage);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        snackbarMessage,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                              await refreshPage();
                                            },
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 17,
                                            ),
                                            label: const Text(
                                              'Review',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 120,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          final error = snapshot.error;
          Logger().w('Firestore error: \\${error.toString()}');
          return Center(
            child: NothingToShowContainer(
              iconPath: "assets/icons/network_error.svg",
              primaryMessage: "Something went wrong",
              secondaryMessage: "Unable to load orders. Please try again.",
            ),
          );
        }
        return Center(
          child: NothingToShowContainer(
            iconPath: "assets/icons/network_error.svg",
            primaryMessage: "Something went wrong",
            secondaryMessage: "Unable to connect to Database",
          ),
        );
      },
    );
  }

  Widget buildOrderedProductItem(OrderedProduct orderedProduct) {
    return FutureBuilder<Product?>(
      future: _getProductWithCaching(orderedProduct.productUid!),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final product = snapshot.data!;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kTextColor.withOpacity(0.12),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: "Ordered on:  ",
                      style: TextStyle(color: Colors.black, fontSize: 12),
                      children: [
                        TextSpan(
                          text: orderedProduct.orderDate,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: kTextColor.withOpacity(0.15)),
                    ),
                  ),
                  child: ProductShortDetailCard(
                    productId: product.id,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(
                            key: UniqueKey(),
                            productId: product.id,
                          ),
                        ),
                      ).then((_) async {
                        await refreshPage();
                      });
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () async {
                      String currentUserUid =
                          AuthentificationService().currentUser.uid;
                      Review? prevReview;
                      try {
                        prevReview = await ProductDatabaseHelper()
                            .getProductReviewWithID(product.id, currentUserUid);
                      } on FirebaseException catch (e) {
                        Logger().w("Firebase Exception: $e");
                      } catch (e) {
                        Logger().w("Unknown Exception: $e");
                      }
                      if (prevReview == null) {
                        prevReview = Review(
                          currentUserUid,
                          reviewerUid: currentUserUid,
                        );
                      }

                      final result = await showDialog(
                        context: context,
                        builder: (context) {
                          return ProductReviewDialog(
                            key: UniqueKey(),
                            review: prevReview!,
                          );
                        },
                      );
                      if (result is Review) {
                        bool reviewAdded = false;
                        String snackbarMessage = "Unknown error occurred";
                        try {
                          reviewAdded = await ProductDatabaseHelper()
                              .addProductReview(product.id, result);
                          if (reviewAdded == true) {
                            snackbarMessage =
                                "Product review added successfully";
                          } else {
                            throw "Coulnd't add product review due to unknown reason";
                          }
                        } on FirebaseException catch (e) {
                          Logger().w("Firebase Exception: $e");
                          snackbarMessage = e.toString();
                        } catch (e) {
                          Logger().w("Unknown Exception: $e");
                          snackbarMessage = e.toString();
                        } finally {
                          Logger().i(snackbarMessage);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(snackbarMessage)),
                          );
                        }
                      }
                      await refreshPage();
                    },
                    child: Text(
                      "Write a Review",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          // Shimmer placeholder for product card (all loading states)
          return SizedBox(
            height: 70,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 12,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          final error = snapshot.error.toString();
          Logger().e(error);
        }
        return Icon(Icons.error, size: 60, color: kTextColor);
      },
    );
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
}
