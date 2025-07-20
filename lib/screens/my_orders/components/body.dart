import 'package:nexoeshopee/components/nothingtoshow_container.dart';
import 'package:nexoeshopee/components/product_short_detail_card.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/OrderedProduct.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/models/Review.dart';
import 'package:nexoeshopee/models/Address.dart';
import 'package:nexoeshopee/screens/my_orders/components/product_review_dialog.dart';
import 'package:nexoeshopee/screens/product_details/product_details_screen.dart';
import 'package:nexoeshopee/services/authentification/authentification_service.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/services/cache/hive_service.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

// ...existing code...

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

  @override
  @override
  void initState() {
    super.initState();
    _initializeUser();
    _fetchAddresses();
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

  void _initializeUser() {
    try {
      final user = AuthentificationService().currentUser;
      currentUserUid = user.uid;
      Logger().i('User authenticated: $currentUserUid');
      _debugFirestorePath();
      _testOrdersAccess();
      _loadMoreOrders();
    } catch (e) {
      Logger().e('Error getting current user: $e');
    }
  }

  // Test method to manually check orders
  void _testOrdersAccess() async {
    try {
      Logger().i('Testing direct Firestore access...');

      final snapshot = await FirebaseFirestore.instance
          .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
          .doc(currentUserUid)
          .collection(UserDatabaseHelper.ORDERED_PRODUCTS_COLLECTION_NAME)
          .get();

      Logger().i('Direct query result: ${snapshot.docs.length} documents');

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs.take(3)) {
          // Show first 3 orders
          Logger().i('Order ${doc.id}: ${doc.data()}');
        }
      }

      // Also test the original method from UserDatabaseHelper
      final orderIds = await UserDatabaseHelper().orderedProductsList;
      Logger().i(
        'UserDatabaseHelper.orderedProductsList: ${orderIds.length} orders',
      );
    } catch (e) {
      Logger().e('Error in _testOrdersAccess: $e');
    }
  }

  void _debugFirestorePath() {
    Logger().i('Debug: Current user UID: $currentUserUid');
    Logger().i(
      'Debug: Firestore path: ${UserDatabaseHelper.USERS_COLLECTION_NAME}/$currentUserUid/${UserDatabaseHelper.ORDERED_PRODUCTS_COLLECTION_NAME}',
    );

    // Test if we can access the user document
    FirebaseFirestore.instance
        .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
        .doc(currentUserUid)
        .get()
        .then((userDoc) {
          if (userDoc.exists) {
            Logger().i('Debug: User document exists: ${userDoc.data()}');
          } else {
            Logger().w('Debug: User document does not exist');
          }
        })
        .catchError((error) {
          Logger().e('Debug: Error accessing user document: $error');
        });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refreshPage,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(screenPadding),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(height: getProportionateScreenHeight(10)),
                // Back button and address selector in same row
                Row(
                  children: [
                    // iOS style back button
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                      tooltip: 'Back',
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _addresses.length > 1
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 2,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedAddressId,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.black,
                                    ),
                                    isExpanded: true,
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
                                              return Text(
                                                address.title ??
                                                    address.addressLine1 ??
                                                    addressId,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            }
                                            return Text(
                                              addressId,
                                              overflow: TextOverflow.ellipsis,
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
                                ),
                              )
                            : (_addresses.length == 1
                                  ? FutureBuilder<Address>(
                                      future: UserDatabaseHelper()
                                          .getAddressFromId(_addresses.first),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          final address = snapshot.data!;
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Text(
                                              address.title ??
                                                  address.addressLine1 ??
                                                  _addresses.first,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }
                                        return SizedBox.shrink();
                                      },
                                    )
                                  : SizedBox.shrink()),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: getProportionateScreenHeight(10)),
                // Tab bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ...List.generate(_orderTabs.length, (i) {
                      final selected = _selectedTabIndex == i;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = i;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 24),
                          padding: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            border: selected
                                ? Border(
                                    bottom: BorderSide(
                                      color: kPrimaryColor,
                                      width: 2,
                                    ),
                                  )
                                : null,
                          ),
                          child: Text(
                            _orderTabs[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected ? kPrimaryColor : Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                SizedBox(height: getProportionateScreenHeight(10)),
                // Orders list
                Expanded(child: buildOrderedProductsList()),
              ],
            ),
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
          // Remove status filter so all orders show
          Logger().i(
            'Found ${orderedProductsDocs.length} orders for user $currentUserUid and address $_selectedAddressId',
          );
          if (orderedProductsDocs.isEmpty) {
            return Center(
              child: NothingToShowContainer(
                iconPath: "assets/icons/empty_bag.svg",
                secondaryMessage: "Order something to show here",
              ),
            );
          }
          // Sort by date descending
          orderedProductsDocs.sort((a, b) {
            final aDate = a.data()[OrderedProduct.ORDER_DATE_KEY] as String?;
            final bDate = b.data()[OrderedProduct.ORDER_DATE_KEY] as String?;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });
          // Group by date (show only date part)
          Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
          grouped = {};
          for (var doc in orderedProductsDocs) {
            final rawDate =
                doc.data()[OrderedProduct.ORDER_DATE_KEY] as String? ?? '';
            String dateOnly = rawDate;
            // Try to parse and format date
            try {
              DateTime dt = DateTime.parse(rawDate);
              dateOnly =
                  "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
            } catch (e) {}
            grouped.putIfAbsent(dateOnly, () => []).add(doc);
          }
          // Debug: print grouped dates and counts
          Logger().i('Grouped order dates:');
          grouped.forEach((date, docs) {
            Logger().i('Date: $date, Count: ${docs.length}');
          });
          return ListView(
            physics: BouncingScrollPhysics(),
            children: grouped.entries.map((entry) {
              // Group products by productUid and count
              Map<String, int> productCounts = {};
              Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
              productDocs = {};
              Logger().i('Rendering date group: ${entry.key}');
              for (var doc in entry.value) {
                final pid =
                    doc.data()[OrderedProduct.PRODUCT_UID_KEY] as String?;
                Logger().i('Rendering product UID: $pid for date ${entry.key}');
                if (pid != null) {
                  productCounts[pid] = (productCounts[pid] ?? 0) + 1;
                  productDocs[pid] = doc;
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ),
                    child: Text(
                      'Ordered on: ${entry.key}',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 4,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                    shadowColor: Colors.black.withOpacity(0.12),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: productCounts.keys.map((pid) {
                          final count = productCounts[pid] ?? 1;
                          return FutureBuilder<Product?>(
                            future: _getProductWithCaching(pid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox(
                                  height: 70,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data == null) {
                                Logger().w(
                                  'Product not found for UID: $pid on date ${entry.key}',
                                );
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Product not found for UID: $pid',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                );
                              }
                              final product = snapshot.data!;
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Color(0xFFF2F6FF),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
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
                                            } on FirebaseException catch (e) {
                                              Logger().w(
                                                "Firebase Exception: $e",
                                              );
                                              snackbarMessage = e.toString();
                                            } catch (e) {
                                              Logger().w(
                                                "Unknown Exception: $e",
                                              );
                                              snackbarMessage = e.toString();
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
                                        icon: Icon(
                                          Icons.edit,
                                          color: Color(0xFF3D8BEA),
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Write a Review',
                                          style: TextStyle(
                                            color: Color(0xFF3D8BEA),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
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
                                                      ProductDetailsScreen(
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
                                        SizedBox(width: 12),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFEDF2FA),
                                            borderRadius: BorderRadius.circular(
                                              6,
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
              );
            }).toList(),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your orders...'),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          final error = snapshot.error;
          Logger().w('Firestore error: ${error.toString()}');
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
          return Center(child: CircularProgressIndicator());
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
