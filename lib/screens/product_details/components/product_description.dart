import 'package:fishkart/models/Product.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart/providers/user_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_svg/svg.dart';
import 'package:logger/logger.dart';
import '../../../utils.dart';
import 'package:flutter/material.dart';

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
    if (widget.product.stock > 0 && cartCount < widget.product.stock) {
      setState(() {
        cartCount++;
      });
    }
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
    // Get selected address from provider
    final selectedAddressId = ref.read(selectedAddressIdProvider);
    final address = selectedAddressId != null
        ? await UserDatabaseHelper().getAddressFromId(selectedAddressId)
        : null;
    if (address == null ||
        address.city == null ||
        widget.product.areaLocation == null ||
        address.city!.toLowerCase() !=
            widget.product.areaLocation!.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product is not available in your area.')),
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
    debugPrint('Product stock for ${product.title}: ${product.stock}');
    final isOutOfStock = product.stock == 0;
    final selectedAddressId = ref.watch(selectedAddressIdProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32), // More space between image and text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product.title ?? '').split('/').first,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (product.variant != null && product.variant!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Net Weight: ${product.variant!}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF646161),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 8),
              if (product.discountPrice != null)
                Text(
                  '\₹${product.originalPrice}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Spacer(),
              Container(
                margin: EdgeInsets.only(left: 12),
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
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ), // Increased height
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, color: Colors.black),
                      onPressed: isOutOfStock ? null : _decrementCounter,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        isOutOfStock ? '0' : '$cartCount',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.black),
                      onPressed: isOutOfStock ? null : _incrementCounter,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            product.description ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF626262),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Use SvgPicture for SVG asset
                      // Make sure to add flutter_svg to pubspec.yaml
                      // and leaf.svg exists in assets/images/
                      SvgPicture.asset(
                        'assets/images/leaf.svg',
                        width: 38,
                        height: 38,
                        color: Color(0xFF7A8C9E),
                      ),
                      SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Fresh',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFB0B6BE),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Color(0xFF7A8C9E), size: 38),
                      SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${product.rating}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Rated',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFB0B6BE),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FutureBuilder<Address?>(
              future: selectedAddressId != null
                  ? UserDatabaseHelper().getAddressFromId(selectedAddressId)
                  : Future.value(null),
              builder: (context, snapshot) {
                final selectedAddress = snapshot.data;
                final city = (selectedAddress?.city ?? '').trim().toLowerCase();
                final areaLocation = (product.areaLocation ?? '')
                    .trim()
                    .toLowerCase();
                final isAreaAvailable =
                    city.isNotEmpty &&
                    areaLocation.isNotEmpty &&
                    city == areaLocation;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOutOfStock || !isAreaAvailable
                          ? Colors.grey
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 24),
                      elevation: 0,
                    ),
                    onPressed: isOutOfStock || !isAreaAvailable
                        ? null
                        : _proceedToCheckout,
                    child: Text(
                      isOutOfStock
                          ? 'Stock Out'
                          : !isAreaAvailable
                          ? 'Product not available in your area'
                          : 'Proceed To Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
