import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:shimmer/shimmer.dart';

import 'package:nexoeshopee/components/nothingtoshow_container.dart';
import 'package:nexoeshopee/components/product_short_detail_card.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/CartItem.dart';
import 'package:nexoeshopee/models/OrderedProduct.dart';
import 'package:nexoeshopee/models/Address.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/providers/user_providers.dart';
import 'package:nexoeshopee/screens/cart/components/checkout_card.dart';
import 'package:nexoeshopee/screens/product_details/product_details_screen.dart';
import 'package:nexoeshopee/services/authentification/authentification_service.dart';
import 'package:nexoeshopee/services/base64_image_service/base64_image_service.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/size_config.dart';
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
  List<Map<String, dynamic>> savedCards = [];
  String? selectedUpiApp;
  bool showQrDialog = false;
  int? selectedCardIndex;

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
                              return Text(
                                address.title ?? address.addressLine1 ?? '',
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            // While loading, show empty or loading text
                            return Text(
                              '',
                              overflow: TextOverflow.ellipsis,
                            );
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

  // Move paymentMethodTile above buildCartItemsList
  Widget paymentMethodTile(IconData icon, String title, String? subtitle) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
            Icon(Icons.credit_card, color: kPrimaryColor, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        ],
      ),
    );
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show shimmer loading for cart items
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
                // Show cart items for selected address, and also items with no addressId (legacy)
                if (cartItem != null &&
                    product != null &&
                    (cartItem.addressId == _selectedAddressId ||
                        cartItem.addressId == null)) {
                  final price =
                      product.discountPrice ?? product.originalPrice ?? 0;
                  totalPrice += price * (cartItem.itemCount);
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
                            child:
                                (product.images != null &&
                                    product.images!.isNotEmpty)
                                ? Base64ImageService().base64ToImage(
                                    product.images!.first,
                                    fit: BoxFit.cover,
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
                                  product.title ?? "Product",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (product.description != null)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      product.description!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      "₹${price.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryColor,
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
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Column(
                            children: [
                              InkWell(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.add, color: kPrimaryColor),
                                ),
                                onTap: () async {
                                  await arrowUpCallback(product.id, _selectedAddressId);
                                },
                              ),
                              SizedBox(height: 8),
                              Text(
                                "${cartItem.itemCount}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: kPrimaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              InkWell(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    color: kPrimaryColor,
                                  ),
                                ),
                                onTap: () async {
                                  await arrowDownCallback(product.id, _selectedAddressId);
                                },
                              ),
                            ],
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
                    SizedBox(height: 20),
                    // Payment Methods Section
                    Text(
                      "Payment Methods",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    // Cards Section
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
                    InkWell(
                      onTap: () => showAddCardDialog(context),
                      child: paymentMethodTile(Icons.add_card, "Add Card", null),
                    ),
                    Text(
                      "UPI Apps",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                            child: Image.asset(
                              'assets/icons/gpay.png',
                              fit: BoxFit.contain,
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
                            child: Image.asset(
                              'assets/icons/phonepe.png',
                              fit: BoxFit.contain,
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
                            child: Image.asset(
                              'assets/icons/paytm.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () => showQrPaymentDialog(context),
                      child: paymentMethodTile(
                        Icons.qr_code,
                        "Scan & Pay",
                        "Generate QR for payment",
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Amount",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "₹${totalPrice.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => showCheckoutBottomSheetWithTotal(totalPrice),
                          child: Text(
                            "Checkout",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
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
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Delivery to",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "${address.title ?? ''}, ${address.addressLine1 ?? ''}\n${address.addressLine2 ?? ''}\n${address.city ?? ''}, ${address.state ?? ''}\nPhone: ${address.phone ?? ''}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.map,
                                    color: kPrimaryColor,
                                    size: 32,
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
            // Ensure a Widget is always returned
            return SizedBox.shrink();
          },
        );
      },
      loading: () {
        Logger().i('CartItemsStreamProvider loading...');
        return Center(child: CircularProgressIndicator());
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

  void showCheckoutBottomSheetWithTotal(double totalPrice) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return CheckoutCard(
          onCheckoutPressed: checkoutButtonCallback,
          totalPrice: totalPrice,
        );
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
        future: ProductDatabaseHelper().getProductWithID(cartItemId.split('_').first),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            Product product = snapshot.data!;
            return Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Show product image from Firestore
                Expanded(
                  flex: 7,
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
                            // Pass productId and selectedAddressId
                            await arrowUpCallback(cartItemId, _selectedAddressId);
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
                            // Pass productId and selectedAddressId
                            await arrowDownCallback(cartItemId, _selectedAddressId);
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

  Future<double> getCartTotal() async {
    final cartItemsId = ref.read(cartItemsStreamProvider).value ?? [];
    double total = 0;
    if (cartItemsId.isNotEmpty) {
      final cartItems = await Future.wait(cartItemsId.map((id) => UserDatabaseHelper().getCartItemFromId(id)));
      final products = await Future.wait(cartItemsId.map((id) => ProductDatabaseHelper().getProductWithID(id.split('_').first)));
      for (int i = 0; i < cartItemsId.length; i++) {
        final cartItem = cartItems[i];
        final product = products[i];
        final price = product?.discountPrice ?? product?.originalPrice ?? 0;
        total += price * (cartItem.itemCount);
      }
    }
    return total;
  }

  Future<void> checkoutButtonCallback() async {
    shutBottomSheet();
    double amount = await getCartTotal();
    if (amount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cart is empty or failed to calculate total.')),
      );
      return;
    }
    // If UPI app is selected, launch UPI intent
    if (selectedUpiApp != null) {
      String upiUrl =
          'upi://pay?pa=afnnafsal@oksbi&pn=Afnan Afsal&am=${amount.toStringAsFixed(2)}&cu=INR';
      // Use url_launcher to launch UPI intent
      if (await canLaunchUrl(Uri.parse(upiUrl))) {
        await launchUrl(
          Uri.parse(upiUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch UPI app')));
      }
      return;
    }

    // If card is selected, proceed with mock order
    final confirmation = await showConfirmationDialog(
      context,
      "This is just a Project Testing App so, no actual Payment Interface is available.\nDo you want to proceed for Mock Ordering of Products?",
    );
    if (confirmation == false) {
      return;
    }

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
    for (final doc in cartSnapshot.docs) {
      final productId = doc.id;
      final data = doc.data();
      final quantity = data[CartItem.ITEM_COUNT_KEY] ?? 1;
      orderedProducts.add(
        OrderedProduct(
          '',
          productUid: productId,
          orderDate: isoDateTime,
          addressId: _selectedAddressId,
          quantity: quantity,
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

  void shutBottomSheet() {
    // Remove bottom sheet handler since we're using modal bottom sheet
  }

  Future<void> arrowUpCallback(String productId, String? addressId) async {
    shutBottomSheet();
    // Find the cart item for the selected address and product
    final cartItem = await UserDatabaseHelper().getCartItemByProductAndAddress(productId, addressId);
    if (cartItem != null) {
      final future = UserDatabaseHelper().increaseCartItemCount(cartItem.id);
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("This product is not in your selected address's cart.")),
      );
    }
  }

  Future<void> arrowDownCallback(String productId, String? addressId) async {
    shutBottomSheet();
    // Find the cart item for the selected address and product
    final cartItem = await UserDatabaseHelper().getCartItemByProductAndAddress(productId, addressId);
    if (cartItem != null) {
      final future = UserDatabaseHelper().decreaseCartItemCount(cartItem.id);
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("This product is not in your selected address's cart.")),
      );
    }
  }
}
