import 'package:fishkart/models/Product.dart';
import 'package:fishkart/size_config.dart';
import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart/providers/user_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import '../../../utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants.dart';
import 'expandable_text.dart';

class ProductDescription extends ConsumerStatefulWidget {
  const ProductDescription({required Key key, required this.product})
    : super(key: key);

  final Product product;

  @override
  ConsumerState<ProductDescription> createState() => _ProductDescriptionState();
}

class _ProductDescriptionState extends ConsumerState<ProductDescription> {
  int cartCount = 0;

  void _incrementCounter() {
    setState(() {
      cartCount++;
    });
  }

  void _decrementCounter() {
    if (cartCount > 1) {
      setState(() {
        cartCount--;
      });
    }
  }

  void _proceedToCheckout() async {
    if (cartCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least 1 item to add to cart.'),
        ),
      );
      return;
    }
    bool allowed = AuthentificationService().currentUserVerified;
    if (!allowed) {
      final reverify = await showConfirmationDialog(
        context,
        "You haven't verified your email address. This action is only allowed for verified users.",
        positiveResponse: "Resend verification email",
        negativeResponse: "Go back",
      );
      if (reverify) {
        final future = AuthentificationService()
            .sendVerificationEmailToCurrentUser();
        await showDialog(
          context: context,
          builder: (context) {
            return AsyncProgressDialog(
              future,
              message: Text("Resending verification email"),
            );
          },
        );
      }
      return;
    }
    String snackbarMessage = "";
    // Get selected address from provider
    final selectedAddressId = ref.read(selectedAddressIdProvider);
    final addFutures = List.generate(
      cartCount,
      (_) => UserDatabaseHelper().addProductToCart(
        widget.product.id,
        addressId: selectedAddressId,
      ),
    );
    Logger().i(
      'Attempting to add product to cart: id=${widget.product.id}, count=$cartCount, addressId=$selectedAddressId',
    );
    bool allAdded = true;
    await showDialog(
      context: context,
      builder: (context) => AsyncProgressDialog(
        Future.wait(addFutures),
        message: const Text("Adding product(s) to cart..."),
      ),
    );
    try {
      final results = await Future.wait(addFutures);
      Logger().i('Cart add results: $results');
      allAdded = results.every((r) => r);
      if (!allAdded) {
        throw "Couldn't add product due to unknown reason";
      }
      snackbarMessage = "Product added successfully";
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
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title ?? '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (product.variant != null && product.variant!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          product.variant!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                '\₹${product.discountPrice ?? product.originalPrice}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 8),
              if (product.discountPrice != null)
                Text(
                  '\₹${product.originalPrice}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Spacer(),
              Container(
                margin: EdgeInsets.only(right: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, color: Colors.black),
                      onPressed: _decrementCounter,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        '$cartCount',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.black),
                      onPressed: _incrementCounter,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            product.description ?? '',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 18),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/leaf.png',
                        width: 32,
                        height: 32,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '100%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Fresh',
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 18),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/star.png',
                        width: 32,
                        height: 32,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${product.rating}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Rated',
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: widget.product.stock == 0
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: null,
                    child: Text(
                      'Stock Out',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF42526E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: _proceedToCheckout,
                    child: Text(
                      'Proceed To Checkout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
