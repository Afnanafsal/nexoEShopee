import 'package:fishkart/models/Product.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart/providers/user_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  Future<Product?>? _mostPopularFuture;

  @override
  void initState() {
    super.initState();
    _mostPopularFuture = ProductDatabaseHelper().getMostOrderedProduct();
  }

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
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32.h),
          FutureBuilder<Product?>(
            future: _mostPopularFuture,
            builder: (context, snapshot) {
              final isMostPopular =
                  snapshot.hasData && snapshot.data?.id == product.id;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMostPopular)
                    Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF1AAE4C),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Most Popular',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  SizedBox(height: 8.h),
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
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            if (product.variant != null &&
                                product.variant!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Text(
                                  'Net Weight: ${product.variant!}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
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
                ],
              );
            },
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                '\₹${product.discountPrice ?? product.originalPrice}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 8.w),
              if (product.discountPrice != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(
                    '\₹${product.originalPrice}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black.withOpacity(0.38),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.black.withOpacity(0.38),
                    ),
                  ),
                ),
              Spacer(),
              Container(
                margin: EdgeInsets.only(left: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove,
                        color: Colors.black,
                        size: 22.sp,
                      ),
                      onPressed: isOutOfStock ? null : _decrementCounter,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Text(
                        isOutOfStock ? '0' : '$cartCount',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.black, size: 22.sp),
                      onPressed: isOutOfStock ? null : _incrementCounter,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            product.description ?? '',
            style: TextStyle(
              fontSize: 16.sp,
              color: Color(0xFF626262),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 7.w),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 12.h,
                    horizontal: 14.w,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/leaf.jpg',
                        width: 32.w,
                        height: 32.w,
                      ),
                      SizedBox(width: 10.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18.sp,
                              color: Color(0xFF222B45),
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Fresh',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Color(0xFF7A8C9E),
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
                  margin: EdgeInsets.only(left: 7.w),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 12.h,
                    horizontal: 14.w,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Color(0xFF7A8C9E), size: 32.w),
                      SizedBox(width: 10.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${product.rating}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18.sp,
                              color: Color(0xFF222B45),
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Rated',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Color(0xFF7A8C9E),
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
          SizedBox(height: 24.h),
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
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 24.h),
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
                        fontSize: 16.sp,
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
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
