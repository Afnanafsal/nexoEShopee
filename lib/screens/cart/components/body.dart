import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fishkart/components/async_progress_dialog.dart';

import 'package:fishkart/components/nothingtoshow_container.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fishkart/constants.dart';
import 'package:fishkart/models/CartItem.dart';
import 'package:fishkart/models/OrderedProduct.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/providers/user_providers.dart';
import 'package:fishkart/screens/cart/components/checkout_card.dart';
import 'package:fishkart/screens/product_details/product_details_screen.dart';
import 'package:fishkart/screens/my_orders/order_details_screen.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import '../../../services/razorpay_service.dart';
import 'package:fishkart/services/base64_image_service/base64_image_service.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/services/cache/hive_service.dart';
import '../../../utils.dart';

// Formatter for MM/YY expiry
class ExpiryDateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    // Only allow MM/YY
    if (text.length == 2 && oldValue.text.length == 1) {
      if (int.tryParse(text.substring(0, 2)) != null &&
          int.parse(text.substring(0, 2)) <= 12) {
        text += '/';
      } else {
        text = '';
      }
    }
    if (text.length > 5) {
      text = text.substring(0, 5);
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class Body extends ConsumerStatefulWidget {
  @override
  ConsumerState<Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<Body> {
  // Payment method tile widget for UPI and Add Card
  Widget paymentMethodTile(IconData icon, String title, String? subtitle) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.r,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 28.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                  ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18.sp),
        ],
      ),
    );
  }

  // Show checkout bottom sheet with total
  void showCheckoutBottomSheetWithTotal(double totalPrice) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return CheckoutCard(
          onCheckoutPressed: checkoutButtonCallback,
          onRazorpayPressed: () => checkoutButtonCallback(useRazorpay: true),
          totalPrice: totalPrice,
        );
      },
    );
  }

  void shutBottomSheet() {
    // Remove bottom sheet handler since we're using modal bottom sheet
  }

  Future<void> arrowDownCallback(String cartItemId, String? addressId) async {
    shutBottomSheet();
    // Extract productId from cartItemId (format: productId_addressId)
    final productIdOnly = cartItemId.split('_').first;
    final cartItem = await UserDatabaseHelper().getCartItemByProductAndAddress(
      productIdOnly,
      addressId,
    );
    if (cartItem != null) {
      try {
        // If quantity > 1, decrease. If 1, remove from cart.
        if (cartItem.itemCount > 1) {
          await UserDatabaseHelper().decreaseCartItemCount(cartItem.id);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Decreased quantity.")));
        } else {
          // Remove item from cart
          await UserDatabaseHelper().decreaseCartItemCount(
            cartItem.id,
          ); // Already deletes if count <= 1
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Item removed from cart.")));
        }
        // Refresh cart items provider to update UI
        ref.invalidate(cartItemsStreamProvider);
      } catch (e) {
        Logger().e(e.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Something went wrong")));
      }
      await showDialog(
        context: context,
        builder: (context) {
          return AsyncProgressDialog(
            Future.value(true),
            message: Text("Please wait"),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("This product is not in your selected address's cart."),
        ),
      );
    }
  }

  Future<void> arrowUpCallback(String cartItemId, String? addressId) async {
    shutBottomSheet();
    // Extract productId from cartItemId (format: productId_addressId)
    final productIdOnly = cartItemId.split('_').first;
    final cartItem = await UserDatabaseHelper().getCartItemByProductAndAddress(
      productIdOnly,
      addressId,
    );
    if (cartItem != null) {
      try {
        // Get product stock
        final product = await ProductDatabaseHelper().getProductWithID(
          productIdOnly,
        );
        if (product != null && cartItem.itemCount < product.stock) {
          await UserDatabaseHelper().increaseCartItemCount(cartItem.id);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Increased quantity.")));
          // Refresh cart items provider to update UI
          ref.invalidate(cartItemsStreamProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Cannot add more. Stock limit reached.")),
          );
        }
      } catch (e) {
        Logger().e(e.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Something went wrong")));
      }
      await showDialog(
        context: context,
        builder: (context) {
          return AsyncProgressDialog(
            Future.value(true),
            message: Text("Please wait"),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("This product is not in your selected address's cart."),
        ),
      );
    }
  }

  List<Map<String, dynamic>> savedCards = [];
  String? selectedUpiApp;
  bool showQrDialog = false;
  int? selectedCardIndex;
  late RazorpayService _razorpayService;

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void showAddCardDialog(
    BuildContext context, {
    Map<String, dynamic>? card,
    int? editIndex,
  }) {
    final cardNumberController = TextEditingController(
      text: card?['number'] ?? '',
    );
    final expiryController = TextEditingController(text: card?['expiry'] ?? '');
    final cvvController = TextEditingController(text: card?['cvv'] ?? '');
    final nameController = TextEditingController(text: card?['name'] ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  editIndex == null ? 'Add Card' : 'Edit Card',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp,
                    color: kPrimaryColor,
                  ),
                ),
                SizedBox(height: 24.h),
                TextField(
                  controller: cardNumberController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.credit_card, color: kPrimaryColor),
                    labelText: 'Card Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expiryController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: kPrimaryColor,
                          ),
                          labelText: 'Expiry (MM/YY)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                          ExpiryDateTextInputFormatter(),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: cvvController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock, color: kPrimaryColor),
                          labelText: 'CVV',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person, color: kPrimaryColor),
                    labelText: 'Name on Card',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 28.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: kPrimaryColor),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 14.h,
                        ),
                      ),
                      child: Text(
                        editIndex == null ? 'Save' : 'Update',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16.sp,
                        ),
                      ),
                      onPressed: () async {
                        final expiry = expiryController.text;
                        final valid = RegExp(
                          r'^(0[1-9]|1[0-2])\/\d{2}$',
                        ).hasMatch(expiry);
                        if (!valid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Expiry must be in MM/YY format'),
                            ),
                          );
                          return;
                        }
                        final cardData = {
                          'number': cardNumberController.text,
                          'expiry': expiryController.text,
                          'cvv': cvvController.text,
                          'name': nameController.text,
                        };
                        await saveCardToFirestore(
                          cardData,
                          editIndex: editIndex,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> saveCardToFirestore(
    Map<String, dynamic> card, {
    int? editIndex,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final cardsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cards');
    try {
      if (editIndex == null) {
        await cardsRef.add(card);
      } else {
        final cardId = savedCards[editIndex]['id'];
        await cardsRef.doc(cardId).set(card);
      }
      await fetchCardsFromFirestore();
    } catch (e) {
      Logger().e('Error saving card: $e');
    }
  }

  Future<void> fetchCardsFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final cardsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cards');
    try {
      final snapshot = await cardsRef.get();
      final cards = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      setState(() {
        savedCards = cards;
        if (savedCards.isNotEmpty) selectedCardIndex ??= 0;
      });
    } catch (e) {
      Logger().e('Error fetching cards: $e');
    }
  }

  Future<void> deleteCardFromFirestore(int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final cardId = savedCards[index]['id'];
    final cardsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cards');
    try {
      await cardsRef.doc(cardId).delete();
      await fetchCardsFromFirestore();
      if (selectedCardIndex == index) selectedCardIndex = null;
    } catch (e) {
      Logger().e('Error deleting card: $e');
    }
  }

  void showQrPaymentDialog(BuildContext context) {
    int secondsLeft = 300;
    // Get the actual total from the UI (buildCartItemsList)
    double totalAmount = 0;
    final cartItemsAsync = ref.read(cartItemsStreamProvider);
    if (cartItemsAsync.hasValue) {
      // Fetch product prices synchronously is not possible, so pass total from UI
      // Instead, get the total from the last buildCartItemsList calculation
      // We'll use a workaround: store the last total in a variable
      if (_lastCartTotal != null) {
        totalAmount = _lastCartTotal!;
      }
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (secondsLeft > 0) {
              Future.delayed(Duration(seconds: 1), () {
                setState(() {
                  secondsLeft--;
                });
              });
            }
            String upiUrl =
                'upi://pay?pa=afnnafsal@oksbi&pn=Afnan Afsal&am=${totalAmount.toStringAsFixed(2)}&cu=INR';
            return AlertDialog(
              title: Text('Scan & Pay'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 180.w,
                    height: 180.h,
                    color: Colors.grey[200],
                    child: Center(
                      child: QrImageView(data: upiUrl, size: 160.w),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Scan this QR code with your UPI app to pay.',
                    style: TextStyle(fontSize: 15.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Expires in: ${Duration(seconds: secondsLeft).inMinutes}:${(secondsLeft % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Pay to: afnnafsal@oksbi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                  Text(
                    'Amount: ₹${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 15.sp),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double? _lastCartTotal;

  List<String> _addresses = [];

  String? get _selectedAddressId => ref.watch(selectedAddressIdProvider);
  set _selectedAddressId(String? value) {
    ref.read(selectedAddressIdProvider.notifier).state = value;
  }

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _fetchAddresses();
    fetchCardsFromFirestore();
  }

  Future<void> _fetchAddresses() async {
    try {
      final addresses = await UserDatabaseHelper().addressesList;
      if (mounted) {
        setState(() {
          _addresses = addresses;
        });
        // If no address selected, set to first
        if (_addresses.isNotEmpty && _selectedAddressId == null) {
          _selectedAddressId = _addresses.first;
        }
      }
    } catch (e) {
      Logger().e('Error fetching addresses: $e');
    }
  }

  Future<double> getCartTotal() async {
    final cartItemsId = ref.read(cartItemsStreamProvider).value ?? [];
    double total = 0;
    if (cartItemsId.isNotEmpty) {
      final cartItems = await Future.wait(
        cartItemsId.map((id) => UserDatabaseHelper().getCartItemFromId(id)),
      );
      final products = await Future.wait(
        cartItemsId.map(
          (id) => ProductDatabaseHelper().getProductWithID(id.split('_').first),
        ),
      );
      for (int i = 0; i < cartItemsId.length; i++) {
        final cartItem = cartItems[i];
        final product = products[i];
        if (product != null &&
            (cartItem.addressId == _selectedAddressId ||
                cartItem.addressId == null)) {
          final price = product.discountPrice ?? product.originalPrice ?? 0;
          total += price * (cartItem.itemCount);
        }
      }
    }
    return total;
  }

  Future<void> checkoutButtonCallback({bool useRazorpay = false}) async {
    shutBottomSheet();
    OrderedProduct? orderedProductToShow;
    bool orderSuccess = false;
    String snackbarmMessage = "Something went wrong";
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // The entire checkout process runs inside this dialog
        return AsyncProgressDialog(
          (() async {
            double amount = await getCartTotal();
            if (amount == 0) {
              Navigator.of(context, rootNavigator: true).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cart is empty or failed to calculate total.'),
                ),
              );
              return;
            }

            // Normal checkout logic (previous logic)
            String uid = AuthentificationService().currentUser.uid;
            final cartSnapshot = await FirebaseFirestore.instance
                .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
                .doc(uid)
                .collection(UserDatabaseHelper.CART_COLLECTION_NAME)
                .where('address_id', isEqualTo: _selectedAddressId)
                .get();

            final dateTime = DateTime.now();
            final isoDateTime = dateTime.toIso8601String();
            List<OrderedProduct> orderedProducts = [];
            for (final doc in cartSnapshot.docs) {
              final data = doc.data();
              final productId = data[CartItem.PRODUCT_ID_KEY];
              final quantity = data[CartItem.ITEM_COUNT_KEY] ?? 1;
              await Product.orderStock(productId, quantity);
              String? vendorId;
              var cachedProduct = HiveService.instance.getCachedProduct(
                productId,
              );
              if (cachedProduct != null &&
                  cachedProduct.toMap().containsKey('vendorId') &&
                  cachedProduct.toMap()['vendorId'] != null) {
                vendorId = cachedProduct.toMap()['vendorId'];
              } else {
                try {
                  final product = await ProductDatabaseHelper()
                      .getProductWithID(productId);
                  if (product != null &&
                      product.toMap().containsKey('vendorId')) {
                    vendorId = product.toMap()['vendorId'];
                  }
                } catch (_) {}
              }
              orderedProducts.add(
                OrderedProduct(
                  '',
                  productUid: productId,
                  orderDate: isoDateTime,
                  addressId: _selectedAddressId,
                  quantity: quantity,
                  vendorId: vendorId,
                  userId: uid,
                  status: 'pending',
                ),
              );
            }

            for (final doc in cartSnapshot.docs) {
              await doc.reference.delete();
            }

            try {
              final addedProductsToMyProducts = await UserDatabaseHelper()
                  .addToMyOrders(orderedProducts);
              if (addedProductsToMyProducts) {
                snackbarmMessage = "Products ordered Successfully";
                orderSuccess = true;
                if (orderedProducts.isNotEmpty) {
                  orderedProductToShow = orderedProducts.first;
                }
              } else {
                throw "Could not order products due to unknown issue";
              }
            } on FirebaseException catch (e) {
              Logger().e(e.toString());
              snackbarmMessage = e.toString();
            } catch (e) {
              Logger().e(e.toString());
              snackbarmMessage = e.toString();
            }
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(snackbarmMessage)));
            await refreshPage();
          })(),
          message: Text("Uploading order and processing payment..."),
        );
      },
    );
    // After dialog is closed, schedule navigation if order was successful
    if (orderSuccess && orderedProductToShow != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                OrderDetailsScreen(order: orderedProductToShow!),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF1F5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/home', (route) => false),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: 8.w),
                  // You can add a title or leave empty for spacing
                ],
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.only(
                  left: 4.w,
                ), // Slight indent for 'Your Cart'
                child: Text(
                  'Your Cart',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refreshPage,
                  child: buildCartItemsList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> refreshPage() {
    ref.invalidate(cartItemsStreamProvider);
    return Future<void>.value();
  }

  Widget buildCartItemsList() {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    // Try to load cart items from cache first
    List<String> cachedCartItems = [];
    if (userId != null) {
      final cachedUser = HiveService.instance.getCachedUser(userId);
      if (cachedUser != null) {
        cachedCartItems = cachedUser.cartItems;
      }
    }
    if (cachedCartItems.isNotEmpty) {
      // Use cached cart items and products for instant UI
      final products = cachedCartItems.map((id) {
        final productId = id.split('_').first;
        final cachedProduct = HiveService.instance.getCachedProduct(productId);
        return cachedProduct ??
            Product(
              productId,
              title: 'Unknown',
              images: [],
              discountPrice: 0,
              originalPrice: 0,
            );
      }).toList();
      double totalPrice = 0;
      List<Widget> cartCards = [];
      for (int i = 0; i < cachedCartItems.length; i++) {
        final product = products[i];
        // For demo, assume quantity 1 (can be improved if CartItem is cached)
        totalPrice += product.discountPrice ?? product.originalPrice ?? 0;
        cartCards.add(buildCartItemCard(product, 1, cachedCartItems[i]));
      }
      _lastCartTotal = totalPrice;
      return SingleChildScrollView(
        child: Column(
          children: [
            ...cartCards,
            SizedBox(height: 16),
            buildPaymentMethodsSection(),
            SizedBox(height: 16),
            buildCheckoutSection(totalPrice),
            SizedBox(height: 16),
            buildDeliveryAddressSection(),
            SizedBox(height: 20),
          ],
        ),
      );
    }
    // Fallback to DB if cache is empty
    final cartItemsAsync = ref.watch(cartItemsStreamProvider);
    Logger().i('CartItemsStreamProvider value: $cartItemsAsync');
    bool isFirstLoad = cartItemsAsync.isLoading && (savedCards.isEmpty);
    return cartItemsAsync.when(
      data: (cartItemsId) {
        Logger().i('Cart items IDs: $cartItemsId');
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
        // Calculate total price using both Product and CartItem
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            Future.wait(
              cartItemsId.map((id) {
                Logger().i('Fetching cart item details for: $id');
                return UserDatabaseHelper().getCartItemFromId(id);
              }),
            ),
            Future.wait(
              cartItemsId.map((id) {
                // Extract productId from composite key
                final productId = id.split('_').first;
                Logger().i('Fetching product for cart item: $productId');
                return ProductDatabaseHelper().getProductWithID(productId);
              }),
            ),
          ]),
          builder: (context, snapshot) {
            double totalPrice = 0;
            List<Widget> cartCards = [];
            if (snapshot.connectionState == ConnectionState.waiting &&
                isFirstLoad) {
              // Show shimmer loading only on first load
              return ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return buildShimmerCartItem();
                },
              );
            }
            if (snapshot.hasData) {
              final cartItems = snapshot.data![0] as List<CartItem?>;
              final products = snapshot.data![1] as List<Product?>;
              Logger().i('Fetched cartItems: $cartItems');
              Logger().i('Fetched products: $products');
              for (int i = 0; i < cartItemsId.length; i++) {
                final cartItem = cartItems[i];
                final product = products[i];
                // Show cart items for selected address, and also items with no addressId (legacy)
                if (cartItem != null &&
                    product != null &&
                    (cartItem.addressId == _selectedAddressId ||
                        cartItem.addressId == null)) {
                  final price =
                      product.discountPrice ?? product.originalPrice ?? 0;
                  totalPrice += price * (cartItem.itemCount);
                  cartCards.add(
                    buildCartItemCard(
                      product,
                      cartItem.itemCount,
                      cartItemsId[i],
                    ),
                  );
                }
              }
              // Store the last total for QR code
              _lastCartTotal = totalPrice;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    ...cartCards,
                    SizedBox(height: 16),
                    buildPaymentMethodsSection(),
                    SizedBox(height: 16),
                    buildCheckoutSection(totalPrice),
                    SizedBox(height: 16),
                    buildDeliveryAddressSection(),
                    SizedBox(height: 20),
                  ],
                ),
              );
            }
            // Ensure a Widget is always returned
            return SizedBox.shrink();
          },
        );
      },
      loading: () {
        Logger().i('CartItemsStreamProvider loading...');
        // Don't show indicator, just return empty widget
        return SizedBox.shrink();
      },
      error: (error, stackTrace) {
        Logger().w('CartItemsStreamProvider error: $error');
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

  Widget buildShimmerCartItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 120,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 14, color: Colors.grey[300]),
                  SizedBox(height: 4),
                  Container(width: 80, height: 12, color: Colors.grey[300]),
                  SizedBox(height: 4),
                  Container(width: 60, height: 14, color: Colors.grey[300]),
                ],
              ),
            ),
            Container(width: 24, height: 24, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget buildCartItemCard(Product product, int quantity, String cartItemId) {
    return StatefulBuilder(
      builder: (context, setState) {
        int currentQuantity = quantity;
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (product.images != null && product.images!.isNotEmpty)
                      ? Base64ImageService().base64ToImage(
                          product.images!.first,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.image_not_supported,
                          size: 30,
                          color: Colors.grey,
                        ),
                ),
              ),
              SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title ?? "Product",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Net weight 500 gms", // Static text as shown in image
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "₹${(product.discountPrice ?? product.originalPrice ?? 0).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Quantity Controls
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.add, color: Color(0xFF646161), size: 24),
                      onPressed: () async {
                        await arrowUpCallback(cartItemId, _selectedAddressId);
                        setState(() {
                          currentQuantity++;
                        });
                        ref.invalidate(cartItemsStreamProvider);
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    currentQuantity.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.remove,
                        color: Color(0xFF646161),
                        size: 24,
                      ),
                      onPressed: () async {
                        if (currentQuantity > 1) {
                          await arrowDownCallback(
                            cartItemId,
                            _selectedAddressId,
                          );
                          setState(() {
                            currentQuantity--;
                          });
                          ref.invalidate(cartItemsStreamProvider);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payment Methods",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12),
        // Saved Cards
        ...savedCards.asMap().entries.map((entry) {
          final idx = entry.key;
          final card = entry.value;
          return buildPaymentMethodItem(
            title:
                "**** **** **** ${card['number']?.substring(card['number'].length - 4)}",
            isSelected: selectedCardIndex == idx,
            onTap: () {
              setState(() {
                selectedCardIndex = idx;
                selectedUpiApp = null;
              });
            },
            onEdit: () =>
                showAddCardDialog(context, card: card, editIndex: idx),
            onDelete: () => deleteCardFromFirestore(idx),
            imageAsset: 'assets/icons/visa.png',
          );
        }),
        // Add Card Option
        buildPaymentMethodItem(
          title: "**** **** **** ****",
          isSelected: false,
          onTap: () => showAddCardDialog(context),
          showAddIcon: true,
          imageAsset: 'assets/icons/master.png',
        ),
        SizedBox(height: 8),
        buildPaymentMethodItem(
          imageAsset: 'assets/icons/upi.png',
          title: "UPI Pay",
          isSelected: selectedUpiApp != null,
          onTap: () {
            setState(() {
              selectedUpiApp = 'upi';
              selectedCardIndex = null;
            });
          },
        ),

        // Custom QR payment method using asset image
        GestureDetector(
          onTap: () => showQrPaymentDialog(context),
          child: Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Image.asset(
                    'assets/icons/qr.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Scan & Pay",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPaymentMethodItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    bool showAddIcon = false,
    required String imageAsset,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
                width: 32,
                height: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            if (showAddIcon)
              Icon(Icons.add, color: Colors.grey[600], size: 20)
            else if (onEdit != null || onDelete != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: Icon(
                        Icons.edit,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  if (onEdit != null && onDelete != null) SizedBox(width: 8),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(Icons.delete, color: Colors.red, size: 20),
                    ),
                ],
              )
            else
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget buildCheckoutSection(double totalPrice) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Amount",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  "₹${totalPrice.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return CheckoutCard(
                    onCheckoutPressed: () async {
                      Navigator.of(context).pop();
                      await checkoutButtonCallback();
                    },
                    onRazorpayPressed: () async {
                      Navigator.of(context).pop();
                      await checkoutButtonCallback(useRazorpay: true);
                    },
                    totalPrice: totalPrice,
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              "Checkout",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDeliveryAddressSection() {
    return FutureBuilder<Address?>(
      future: _selectedAddressId != null
          ? UserDatabaseHelper().getAddressFromId(_selectedAddressId!)
          : null,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final address = snapshot.data!;
          return Container(
            padding: EdgeInsets.fromLTRB(28, 22, 22, 22),
            margin: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Delivery to",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8F8F8F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "${address.receiver ?? ''}, ${address.pincode ?? ''}",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          Text(
                            "${address.addressLine1 ?? ''}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8F8F8F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if ((address.addressLine2 ?? '').isNotEmpty)
                            Text(
                              "${address.addressLine2}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8F8F8F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if ((address.city ?? '').isNotEmpty ||
                              (address.state ?? '').isNotEmpty)
                            Text(
                              "${address.city ?? ''}${(address.city != null && address.city!.isNotEmpty && address.state != null && address.state!.isNotEmpty) ? ', ' : ''}${address.state ?? ''}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8F8F8F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          SizedBox(height: 4),
                          Text(
                            "Phone: ${address.phone ?? ''}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 18),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                // Show a bottom sheet to select address
                                await showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return Container(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Select Delivery Address",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          ..._addresses.map(
                                            (
                                              addressId,
                                            ) => FutureBuilder<Address?>(
                                              future: UserDatabaseHelper()
                                                  .getAddressFromId(addressId),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData)
                                                  return SizedBox.shrink();
                                                final addr = snapshot.data!;
                                                return ListTile(
                                                  title: Text(
                                                    "${addr.title ?? "Home"}",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    "${addr.addressLine1 ?? ""}, ${addr.city ?? ""}, ${addr.state ?? ""}, ${addr.pincode ?? ""}",
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  trailing:
                                                      _selectedAddressId ==
                                                          addressId
                                                      ? Icon(
                                                          Icons.check,
                                                          color: kPrimaryColor,
                                                        )
                                                      : null,
                                                  onTap: () {
                                                    _selectedAddressId =
                                                        addressId;
                                                    Navigator.pop(context);
                                                    setState(() {});
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                elevation: 0,
                                              ),
                                              onPressed: () {
                                                // Navigate to add address screen (implement as needed)
                                                Navigator.pop(context);
                                                Navigator.of(
                                                  context,
                                                ).pushNamed('/add_address');
                                              },
                                              child: Text(
                                                "Add New Address",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Text(
                                "Change/Add Address",
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 18),
                    SizedBox(width: 120), // Space for image
                  ],
                ),
                Positioned(
                  top: 14,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      (address.title ?? "Home").toLowerCase(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5C5C5C),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[200],
                          child: Image.asset(
                            'assets/icons/location.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}
