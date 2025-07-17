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
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(screenPadding),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(height: getProportionateScreenHeight(10)),
                  // Address selector
                  if (_addresses.length > 1)
                    Container(
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
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAddressId,
                          icon: Icon(Icons.keyboard_arrow_down, color: Colors.black),
                          isExpanded: true,
                          items: _addresses.map((addressId) {
                            return DropdownMenuItem<String>(
                              value: addressId,
                              child: FutureBuilder<Address>(
                                future: UserDatabaseHelper().getAddressFromId(addressId),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null) {
                                    final address = snapshot.data!;
                                    return Text(address.title ?? address.addressLine1 ?? addressId, overflow: TextOverflow.ellipsis);
                                  }
                                  return Text(addressId, overflow: TextOverflow.ellipsis);
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
                  else if (_addresses.length == 1)
                    FutureBuilder<Address>(
                      future: UserDatabaseHelper().getAddressFromId(_addresses.first),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final address = snapshot.data!;
                          return Container(
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
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(address.title ?? address.addressLine1 ?? _addresses.first, style: TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  SizedBox(height: getProportionateScreenHeight(10)),
                  Text("Your Orders", style: headingStyle),
                  SizedBox(height: getProportionateScreenHeight(20)),
                  SizedBox(
                    height: SizeConfig.screenHeight * 0.75,
                    child: buildOrderedProductsList(),
                  ),
                ],
              ),
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

          // Filter by selected address
          if (_selectedAddressId != null) {
            orderedProductsDocs = orderedProductsDocs.where((doc) {
              final addressId = doc.data()['address_id'] as String?;
              return addressId == _selectedAddressId;
            }).toList();
          }

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

          // Sort the orders by date in Dart since Firestore ordering might be causing issues
          orderedProductsDocs.sort((a, b) {
            try {
              final aDate = a.data()[OrderedProduct.ORDER_DATE_KEY] as String?;
              final bDate = b.data()[OrderedProduct.ORDER_DATE_KEY] as String?;

              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;

              return bDate.compareTo(aDate); // Descending order (newest first)
            } catch (e) {
              Logger().w('Error sorting orders: $e');
              return 0;
            }
          });

          return ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: orderedProductsDocs.length,
            itemBuilder: (context, index) {
              try {
                final orderedProductDoc = orderedProductsDocs[index];
                final orderedProduct = OrderedProduct.fromMap(
                  orderedProductDoc.data(),
                  id: orderedProductDoc.id,
                );

                Logger().i(
                  'Order ${index + 1}: ${orderedProduct.productUid} - ${orderedProduct.orderDate}',
                );

                return buildOrderedProductItem(orderedProduct);
              } catch (e) {
                Logger().e('Error building ordered product item: $e');
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Card(
                    child: ListTile(
                      leading: Icon(Icons.error, color: Colors.red),
                      title: Text('Error loading order'),
                      subtitle: Text('Unable to load order data'),
                    ),
                  ),
                );
              }
            },
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
                      "Give Product Review",
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
