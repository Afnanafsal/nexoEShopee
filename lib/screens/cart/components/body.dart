import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:nexoeshopee/components/default_button.dart';
import 'package:nexoeshopee/components/nothingtoshow_container.dart';
import 'package:nexoeshopee/components/product_short_detail_card.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/CartItem.dart';
import 'package:nexoeshopee/models/OrderedProduct.dart';
import 'package:nexoeshopee/models/Address.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/cart/components/checkout_card.dart';
import 'package:nexoeshopee/screens/product_details/product_details_screen.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:nexoeshopee/providers/user_providers.dart';

import '../../../utils.dart';

class Body extends ConsumerStatefulWidget {
  @override
  ConsumerState<Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<Body> {
  List<String> _addresses = [];
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
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
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(screenPadding),
        ),
        child: Column(
          children: [
            SizedBox(height: getProportionateScreenHeight(10)),
            Text("Your Cart", style: headingStyle),
            SizedBox(height: getProportionateScreenHeight(20)),
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: refreshPage,
                child: buildCartItemsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> refreshPage() {
    ref.invalidate(cartItemsStreamProvider);
    return Future<void>.value();
  }

  Widget buildCartItemsList() {
    final cartItemsAsync = ref.watch(cartItemsStreamProvider);

    return cartItemsAsync.when(
      data: (cartItemsId) {
        if (cartItemsId.isEmpty) {
          return SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Center(
              child: NothingToShowContainer(
                iconPath: "assets/icons/empty_cart.svg",
                secondaryMessage: "Your cart is empty",
              ),
            ),
          );
        }

        return Column(
          children: [
            DefaultButton(
              text: "Proceed to Payment",
              press: showCheckoutBottomSheet,
            ),
            SizedBox(height: getProportionateScreenHeight(20)),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 16),
                physics: BouncingScrollPhysics(),
                itemCount: cartItemsId.length,
                itemBuilder: (context, index) {
                  if (index >= cartItemsId.length) {
                    return SizedBox(height: getProportionateScreenHeight(80));
                  }
                  return buildCartItemDismissible(
                    context,
                    cartItemsId[index],
                    index,
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        Logger().w(error.toString());
        return SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Center(
            child: NothingToShowContainer(
              iconPath: "assets/icons/network_error.svg",
              primaryMessage: "Something went wrong",
              secondaryMessage: "Unable to connect to Database",
            ),
          ),
        );
      },
    );
  }

  void showCheckoutBottomSheet() {
    // Show checkout bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return CheckoutCard(onCheckoutPressed: checkoutButtonCallback);
      },
    );
  }

  Widget buildCartItemDismissible(
    BuildContext context,
    String cartItemId,
    int index,
  ) {
    return Dismissible(
      key: Key(cartItemId),
      direction: DismissDirection.startToEnd,
      dismissThresholds: {DismissDirection.startToEnd: 0.65},
      background: buildDismissibleBackground(),
      child: buildCartItem(cartItemId, index),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          final confirmation = await showConfirmationDialog(
            context,
            "Remove Product from Cart?",
          );
          if (confirmation) {
            if (direction == DismissDirection.startToEnd) {
              bool result = false;
              String snackbarMessage = "Something went wrong";
              try {
                result = await UserDatabaseHelper().removeProductFromCart(
                  cartItemId,
                );
                if (result == true) {
                  snackbarMessage = "Product removed from cart successfully";
                  await refreshPage();
                } else {
                  throw "Coulnd't remove product from cart due to unknown reason";
                }
              } on FirebaseException catch (e) {
                Logger().w("Firebase Exception: $e");
                snackbarMessage = "Something went wrong";
              } catch (e) {
                Logger().w("Unknown Exception: $e");
                snackbarMessage = "Something went wrong";
              } finally {
                Logger().i(snackbarMessage);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
              }

              return result;
            }
          }
        }
        return false;
      },
      onDismissed: (direction) {},
    );
  }

  Widget buildCartItem(String cartItemId, int index) {
    return Container(
      padding: EdgeInsets.only(bottom: 4, top: 4, right: 4),
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: kTextColor.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: FutureBuilder<Product?>(
        future: ProductDatabaseHelper().getProductWithID(cartItemId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            Product product = snapshot.data!;
            return Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 8,
                  child: ProductShortDetailCard(
                    productId: product.id,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(
                            key: Key(product.id),
                            productId: product.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 12),
                    decoration: BoxDecoration(
                      color: kTextColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          child: Icon(Icons.arrow_drop_up, color: kTextColor),
                          onTap: () async {
                            await arrowUpCallback(cartItemId);
                          },
                        ),
                        SizedBox(height: 8),
                        FutureBuilder<CartItem>(
                          future: UserDatabaseHelper().getCartItemFromId(
                            cartItemId,
                          ),
                          builder: (context, snapshot) {
                            int itemCount = 0;
                            if (snapshot.hasData) {
                              final cartItem = snapshot.data;
                              if (cartItem != null) {
                                itemCount = cartItem.itemCount;
                              }
                            } else if (snapshot.hasError) {
                              final error = snapshot.error.toString();
                              Logger().e(error);
                            }
                            return Text(
                              "$itemCount",
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 8),
                        InkWell(
                          child: Icon(Icons.arrow_drop_down, color: kTextColor),
                          onTap: () async {
                            await arrowDownCallback(cartItemId);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            final error = snapshot.error;
            Logger().w(error.toString());
            return Center(child: Text(error.toString()));
          } else {
            return Center(child: Icon(Icons.error));
          }
        },
      ),
    );
  }

  Widget buildDismissibleBackground() {
    return Container(
      padding: EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(width: 4),
          Text(
            "Delete",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> checkoutButtonCallback() async {
    shutBottomSheet();
    final confirmation = await showConfirmationDialog(
      context,
      "This is just a Project Testing App so, no actual Payment Interface is available.\nDo you want to proceed for Mock Ordering of Products?",
    );
    if (confirmation == false) {
      return;
    }
    final orderFuture = UserDatabaseHelper().emptyCart();
    orderFuture
        .then((orderedProductsUid) async {
          print(orderedProductsUid);
          final dateTime = DateTime.now();
          final formatedDateTime =
              "${dateTime.day}-${dateTime.month}-${dateTime.year}";
          List<OrderedProduct> orderedProducts = orderedProductsUid
              .map(
                (e) => OrderedProduct(
                  '',
                  productUid: e,
                  orderDate: formatedDateTime,
                  addressId: _selectedAddressId,
                ),
              )
              .toList();
          bool addedProductsToMyProducts = false;
          String snackbarmMessage = "Something went wrong";
          try {
            addedProductsToMyProducts = await UserDatabaseHelper()
                .addToMyOrders(orderedProducts);
            if (addedProductsToMyProducts) {
              snackbarmMessage = "Products ordered Successfully";
            } else {
              throw "Could not order products due to unknown issue";
            }
          } on FirebaseException catch (e) {
            Logger().e(e.toString());
            snackbarmMessage = e.toString();
          } catch (e) {
            Logger().e(e.toString());
            snackbarmMessage = e.toString();
          } finally {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(snackbarmMessage)));
          }
          await showDialog(
            context: context,
            builder: (context) {
              return AsyncProgressDialog(
                orderFuture,
                message: Text("Placing the Order"),
              );
            },
          );
        })
        .catchError((e) {
          Logger().e(e.toString());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Something went wrong")));
        });
    await showDialog(
      context: context,
      builder: (context) {
        return AsyncProgressDialog(
          orderFuture,
          message: Text("Placing the Order"),
        );
      },
    );
    await refreshPage();
  }

  void shutBottomSheet() {
    // Remove bottom sheet handler since we're using modal bottom sheet
  }

  Future<void> arrowUpCallback(String cartItemId) async {
    shutBottomSheet();
    final future = UserDatabaseHelper().increaseCartItemCount(cartItemId);
    future
        .then((status) async {
          if (status) {
            await refreshPage();
          } else {
            throw "Couldn't perform the operation due to some unknown issue";
          }
        })
        .catchError((e) {
          Logger().e(e.toString());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Something went wrong")));
        });
    await showDialog(
      context: context,
      builder: (context) {
        return AsyncProgressDialog(future, message: Text("Please wait"));
      },
    );
  }

  Future<void> arrowDownCallback(String cartItemId) async {
    shutBottomSheet();
    final future = UserDatabaseHelper().decreaseCartItemCount(cartItemId);
    future
        .then((status) async {
          if (status) {
            await refreshPage();
          } else {
            throw "Couldn't perform the operation due to some unknown issue";
          }
        })
        .catchError((e) {
          Logger().e(e.toString());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Something went wrong")));
        });
    await showDialog(
      context: context,
      builder: (context) {
        return AsyncProgressDialog(future, message: Text("Please wait"));
      },
    );
  }
}
