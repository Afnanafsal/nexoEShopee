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
  void shutBottomSheet() {
    Navigator.of(context).maybePop();
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
    double amount = await getCartTotal();
    if (amount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cart is empty or failed to calculate total.')),
      );
      return;
    }

    if (useRazorpay) {
      // Replace with actual user details as needed
      final user = FirebaseAuth.instance.currentUser;
      final name = user?.displayName ?? 'FishKart User';
      final email = user?.email ?? 'user@example.com';
      final contact =
          user?.phoneNumber ??
          '9999999999'; // TODO: Replace with user's phone if available

      // Open Razorpay checkout
      _razorpayService.openCheckout(
        amount: amount,
        name: name,
        description: 'Order Payment',
        contact: contact,
        email: email,
      );
      // TODO: On payment success, move order placement logic here
      // You can listen to payment success in RazorpayService and call order placement
      return;
    }
    // Normal checkout logic (previous logic)
    // Fetch only cart items for the selected address BEFORE deleting
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
    // Update stock for each product in the order
    for (final doc in cartSnapshot.docs) {
      final data = doc.data();
      final productId = data[CartItem.PRODUCT_ID_KEY];
      final quantity = data[CartItem.ITEM_COUNT_KEY] ?? 1;
      // Decrease reserved, increase ordered
      await Product.orderStock(productId, quantity);
      // Get vendorId from product.vendorId
      String? vendorId;
      var cachedProduct = HiveService.instance.getCachedProduct(productId);
      if (cachedProduct != null &&
          cachedProduct.toMap().containsKey('vendorId') &&
          cachedProduct.toMap()['vendorId'] != null) {
        vendorId = cachedProduct.toMap()['vendorId'];
      } else {
        // fallback: fetch from db if not cached
        try {
          final product = await ProductDatabaseHelper().getProductWithID(
            productId,
          );
          if (product != null && product.toMap().containsKey('vendorId')) {
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

    // Now delete only cart items for the selected address
    for (final doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }

    String snackbarmMessage = "Something went wrong";
    try {
      final addedProductsToMyProducts = await UserDatabaseHelper()
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
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(snackbarmMessage)));
    await showDialog(
      context: context,
      builder: (context) {
        return AsyncProgressDialog(
          Future.value(true),
          message: Text("Placing the Order"),
        );
      },
    );
    await refreshPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Your Cart",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Address selector
          if (_addresses.length > 1)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshPage,
              child: buildCartItemsList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> refreshPage() {
    ref.invalidate(cartItemsStreamProvider);
    return Future<void>.value();
  }

  Widget buildCartItemsList() {
    final cartItemsAsync = ref.watch(cartItemsStreamProvider);
    Logger().i('CartItemsStreamProvider value: $cartItemsAsync');

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
                final productId = id.split('_').first;
                Logger().i('Fetching product for cart item: $productId');
                return ProductDatabaseHelper().getProductWithID(productId);
              }),
            ),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
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
              double totalPrice = 0;
              List<Widget> cartCards = [];

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
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Product Image
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child:
                                (product.images != null &&
                                    product.images!.isNotEmpty)
                                ? Base64ImageService().base64ToImage(
                                    product.images!.first,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          SizedBox(width: 12),
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title ?? "Product",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Qty: ${cartItem.itemCount} | 500 gm",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "₹${price.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quantity Controls
                          Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.add, size: 18),
                                  onPressed: () async {
                                    await arrowUpCallback(
                                      cartItemsId[i],
                                      _selectedAddressId,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "${cartItem.itemCount}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.remove, size: 18),
                                  onPressed: () async {
                                    await arrowDownCallback(
                                      cartItemsId[i],
                                      _selectedAddressId,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }

              _lastCartTotal = totalPrice;

              return SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cart Items
                    ...cartCards,

                    SizedBox(height: 20),

                    // Payment Methods Section
                    Text(
                      "Payment Methods",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Saved Cards Section
                    ...savedCards.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final card = entry.value;
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: idx,
                              groupValue: selectedCardIndex,
                              onChanged: (val) {
                                setState(() {
                                  selectedCardIndex = val;
                                  selectedUpiApp = null;
                                });
                              },
                              activeColor: kPrimaryColor,
                            ),
                            Icon(
                              Icons.credit_card,
                              color: kPrimaryColor,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card['name'] ?? 'Card',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    "**** **** **** ${card['number']?.substring(card['number'].length - 4)}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: kPrimaryColor),
                              onPressed: () => showAddCardDialog(
                                context,
                                card: card,
                                editIndex: idx,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await deleteCardFromFirestore(idx);
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add Card Option
                    InkWell(
                      onTap: () => showAddCardDialog(context),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_card,
                              color: kPrimaryColor,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Add Card",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // UPI Apps Section
                    Text(
                      "UPI Apps",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() {
                            selectedUpiApp = 'gpay';
                            selectedCardIndex = null;
                          }),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedUpiApp == 'gpay'
                                    ? kPrimaryColor
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "GPay",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: selectedUpiApp == 'gpay'
                                      ? kPrimaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        InkWell(
                          onTap: () => setState(() {
                            selectedUpiApp = 'phonepe';
                            selectedCardIndex = null;
                          }),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedUpiApp == 'phonepe'
                                    ? kPrimaryColor
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "PhonePe",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: selectedUpiApp == 'phonepe'
                                      ? kPrimaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        InkWell(
                          onTap: () => setState(() {
                            selectedUpiApp = 'paytm';
                            selectedCardIndex = null;
                          }),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedUpiApp == 'paytm'
                                    ? kPrimaryColor
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "Paytm",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: selectedUpiApp == 'paytm'
                                      ? kPrimaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Scan & Pay
                    InkWell(
                      onTap: () => showQrPaymentDialog(context),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.qr_code,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Scan & Pay",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 40),

                    // Total Amount and Checkout Button
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Amount",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                "₹${totalPrice.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => checkoutButtonCallback(),
                              child: Text(
                                "Checkout",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Delivery Address Section
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
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Delivery to",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "${address.title ?? 'Home'}, ${address.addressLine1 ?? ''}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "${address.city ?? ''}, ${address.state ?? ''}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      "Phone: ${address.phone ?? '7976339567'}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Spacer(),
                                    TextButton(
                                        onPressed: () async {
                                        // Show address selection popup similar to the dropdown
                                        final selected = await showDialog<String>(
                                          context: context,
                                          builder: (context) {
                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Container(
                                            padding: EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                              Text(
                                                "Select Delivery Address",
                                                style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              ..._addresses.map((addressId) {
                                                return FutureBuilder<Address>(
                                                future: UserDatabaseHelper().getAddressFromId(addressId),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData && snapshot.data != null) {
                                                  final address = snapshot.data!;
                                                  return ListTile(
                                                    title: Text(
                                                    address.title ?? address.addressLine1 ?? '',
                                                    overflow: TextOverflow.ellipsis,
                                                    ),
                                                    subtitle: Text(
                                                    "${address.addressLine1 ?? ''}, ${address.city ?? ''}",
                                                    overflow: TextOverflow.ellipsis,
                                                    ),
                                                    leading: Radio<String>(
                                                    value: addressId,
                                                    groupValue: _selectedAddressId,
                                                    onChanged: (val) {
                                                      Navigator.pop(context, val);
                                                    },
                                                    activeColor: kPrimaryColor,
                                                    ),
                                                    onTap: () {
                                                    Navigator.pop(context, addressId);
                                                    },
                                                  );
                                                  }
                                                  return SizedBox.shrink();
                                                },
                                                );
                                              }).toList(),
                                              SizedBox(height: 8),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text("Cancel"),
                                              ),
                                              ],
                                            ),
                                            ),
                                          );
                                          },
                                        );
                                        if (selected != null && selected != _selectedAddressId) {
                                          setState(() {
                                          _selectedAddressId = selected;
                                          });
                                        }
                                        },
                                      child: Text(
                                        "Change",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                // Map placeholder
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.map,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Map View",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
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

                    SizedBox(height: 20),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          },
        );
      },
      loading: () {
        Logger().i('CartItemsStreamProvider loading...');
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
