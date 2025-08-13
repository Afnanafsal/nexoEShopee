import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/models/CartItem.dart';
import 'package:fishkart/models/OrderedProduct.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/providers/user_providers.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/cache/hive_service.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fishkart/components/async_progress_dialog.dart';

import 'package:fishkart/components/nothingtoshow_container.dart';
import 'package:fishkart/components/product_short_detail_card.dart';
import 'package:fishkart/constants.dart';
import 'package:fishkart/models/CartItem.dart';
import 'package:fishkart/models/OrderedProduct.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/providers/user_providers.dart';
import 'package:fishkart/screens/cart/components/checkout_card.dart';
import 'package:fishkart/screens/product_details/product_details_screen.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import '../../../services/razorpay_service.dart';
import 'package:fishkart/services/base64_image_service/base64_image_service.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/services/cache/hive_service.dart';
import 'package:fishkart/size_config.dart';
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
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.r,
            offset: Offset(0, 1.h),
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
        await UserDatabaseHelper().decreaseCartItemCount(cartItem.id);
        // Optionally, update stock here if needed
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
        await UserDatabaseHelper().increaseCartItemCount(cartItem.id);
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
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  editIndex == null ? 'Add Card' : 'Edit Card',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: kPrimaryColor,
                  ),
                ),
                SizedBox(height: 24),
                TextField(
                  controller: cardNumberController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.credit_card, color: kPrimaryColor),
                    labelText: 'Card Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                ),
                SizedBox(height: 16),
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
                            borderRadius: BorderRadius.circular(12),
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
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: cvvController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock, color: kPrimaryColor),
                          labelText: 'CVV',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person, color: kPrimaryColor),
                    labelText: 'Name on Card',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 28),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: Text(
                        editIndex == null ? 'Save' : 'Update',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
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
                    width: 180,
                    height: 180,
                    color: Colors.grey[200],
                    child: Center(
                      child: QrImageView(data: upiUrl, size: 160.0),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Scan this QR code with your UPI app to pay.'),
                  SizedBox(height: 8),
                  Text(
                    'Expires in: ${Duration(seconds: secondsLeft).inMinutes}:${(secondsLeft % 60).toString().padLeft(2, '0')}',
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pay to: afnnafsal@oksbi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Amount: ₹${totalAmount.toStringAsFixed(2)}'),
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
        if (cartItem != null &&
            product != null &&
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

            String snackbarmMessage = "Something went wrong";
            bool orderSuccess = false;
            try {
              final addedProductsToMyProducts = await UserDatabaseHelper()
                  .addToMyOrders(orderedProducts);
              if (addedProductsToMyProducts) {
                snackbarmMessage = "Products ordered Successfully";
                orderSuccess = true;
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
            if (orderSuccess) {
              // Redirect to HomeScreen after successful order
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false);
            }
            await refreshPage();
          })(),
          message: Text("Uploading order and processing payment..."),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            SizedBox(height: 16.h),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 22.sp,
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
            SizedBox(height: 18.h),

            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Text(
                  "Your Cart",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18.sp,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: 18.h),
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
                          future: UserDatabaseHelper().getAddressFromId(
                            addressId,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              final address = snapshot.data!;
                              return Text(
                                address.title ?? address.addressLine1 ?? '',
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            // While loading, show empty or loading text
                            return Text('', overflow: TextOverflow.ellipsis);
                          },
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _selectedAddressId = value;
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        address.title ??
                            address.addressLine1 ??
                            _addresses.first,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
        cartCards.add(
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: (product.images != null && product.images!.isNotEmpty)
                      ? Image.memory(
                          Base64ImageService().base64ToBytes(
                            product.images!.first,
                          ),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (product.title != null && product.title!.contains('/'))
                            ? product.title!.split('/').first.trim()
                            : (product.title ?? "Product"),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16.sp,
                          color: Colors.black,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          'Net weight: ${product.variant ?? "-"}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Text(
                            '₹${product.discountPrice?.toStringAsFixed(2) ?? product.originalPrice?.toStringAsFixed(2) ?? ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          if (product.originalPrice != null &&
                              product.discountPrice != null)
                            Text(
                              '₹${product.originalPrice?.toStringAsFixed(2) ?? ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 13.sp,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text('Qty: 1'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
      _lastCartTotal = totalPrice;
      return Column(
        children: [
          ...cartCards,
          SizedBox(height: 12),
          Text(
            'Total: ₹${totalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: kPrimaryColor,
            ),
          ),
        ],
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
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 120,
                                  height: 16,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 8),
                                Container(
                                  width: 80,
                                  height: 14,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 8),
                                Container(
                                  width: 60,
                                  height: 16,
                                  color: Colors.grey[300],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
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
                if (cartItem != null &&
                    product != null &&
                    (cartItem.addressId == _selectedAddressId ||
                        cartItem.addressId == null)) {
                  final price =
                      product.discountPrice ?? product.originalPrice ?? 0;
                  totalPrice += price * (cartItem.itemCount);
                  cartCards.add(
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      padding: EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 150,
                            margin: EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image:
                                  (product.images != null &&
                                      product.images!.isNotEmpty)
                                  ? DecorationImage(
                                      image: Base64ImageService()
                                          .base64ToImageProvider(
                                            product.images!.first,
                                          ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: Colors.grey[200],
                            ),
                            child:
                                (product.images == null ||
                                    product.images!.isEmpty)
                                ? Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (product.title != null &&
                                            product.title!.contains('/'))
                                        ? product.title!.split('/').first.trim()
                                        : (product.title ?? "Product"),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Net weight: ${product.variant ?? ''}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        "₹${price.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      if (product.originalPrice != null &&
                                          product.discountPrice != null &&
                                          product.originalPrice !=
                                              product.discountPrice)
                                        Text(
                                          "₹${product.originalPrice}",
                                          style: TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await arrowDownCallback(
                                      cartItemsId[i],
                                      cartItem.addressId,
                                    );
                                    await refreshPage();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[200],
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 22,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${cartItem.itemCount}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await arrowUpCallback(
                                      cartItemsId[i],
                                      cartItem.addressId,
                                    );
                                    await refreshPage();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[200],
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 22,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
              // Store the last total for QR code
              _lastCartTotal = totalPrice;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...cartCards,
                    SizedBox(height: 24),
                    Text(
                      "Payment Methods",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 10),
                    ...savedCards.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final card = entry.value;
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.credit_card,
                              color: Colors.black,
                              size: 28,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                "${card['name'] ?? ''}  XXXX XXXX XXXX ${card['number']?.substring(card['number'].length - 4)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.black,
                              size: 18,
                            ),
                          ],
                        ),
                      );
                    }),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.black,
                            size: 28,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "UPI Pay",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.black,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code, color: Colors.black, size: 28),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Scan & Pay",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.black,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Amount",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "₹${totalPrice.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () =>
                                showCheckoutBottomSheetWithTotal(totalPrice),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Text(
                                "Checkout",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    FutureBuilder<Address?>(
                      future: _selectedAddressId != null
                          ? UserDatabaseHelper().getAddressFromId(
                              _selectedAddressId!,
                            )
                          : null,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final address = snapshot.data!;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.all(18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "Delivery to",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "Home",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "${address.title ?? ''}, ${address.addressLine1 ?? ''}\n${address.addressLine2 ?? ''}\n${address.city ?? ''}, ${address.state ?? ''}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Phone: ${address.phone ?? ''}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              side: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                          ),
                                          onPressed: _fetchAddresses,
                                          child: Text(
                                            "Change/Add Address",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  width: 90,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.map,
                                    color: Colors.black,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    ),
                    SizedBox(height: 24),
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
}
