import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/constants.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/screens/cart/cart_screen.dart';
import 'package:fishkart/services/base64_image_service/base64_image_service.dart';
import 'package:fishkart/screens/category_products/category_products_screen.dart';
import 'package:fishkart/screens/product_details/product_details_screen.dart';
import 'package:fishkart/screens/search_result/search_result_screen.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/providers/providers.dart';
// import 'package:fishkart/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:logger/logger.dart';
import 'package:fishkart/services/cache/hive_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import '../../../utils.dart';
import '../components/home_header.dart';
import 'product_type_box.dart';

const String ICON_KEY = "icon";
const String TITLE_KEY = "title";
const String PRODUCT_TYPE_KEY = "product_type";

class Body extends ConsumerStatefulWidget {
  @override
  ConsumerState<Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<Body> {
  int selectedIndex = 0;

  final productCategories = <Map>[
    <String, dynamic>{
      ICON_KEY: "assets/icons/rohu.png",
      TITLE_KEY: "Freshwater",
      PRODUCT_TYPE_KEY: ProductType.Freshwater,
      "examples": ["Rohu", "Catla", "Tilapia"],
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/Pomfret.png",
      TITLE_KEY: "Saltwater",
      PRODUCT_TYPE_KEY: ProductType.Saltwater,
      "examples": ["Pomfret", "King Fish", "Mackerel"],
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/Lobster.png",
      TITLE_KEY: "Shellfish",
      PRODUCT_TYPE_KEY: ProductType.Shellfish,
      "examples": ["Prawns", "Crabs", "Lobster"],
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/salmon.png",
      TITLE_KEY: "Exotic",
      PRODUCT_TYPE_KEY: ProductType.Exotic,
      "examples": ["Salmon", "Tuna", "Snapper"],
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/Anchovies.png",
      TITLE_KEY: "Dried Fish",
      PRODUCT_TYPE_KEY: ProductType.Dried,
      "examples": ["Anchovies", "Bombay Duck"],
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/canned.png",
      TITLE_KEY: "Others",
      PRODUCT_TYPE_KEY: ProductType.Others,
      "examples": ["Other seafood"],
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Show alert if user is not verified (only once per build)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool allowed = AuthentificationService().currentUserVerified;
      if (!allowed && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Email Not Verified'),
            content: Text(
              "You haven't verified your email address. Please verify to access all features.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    });
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => refreshPage(ref),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),
                      HomeHeader(
                        onSearchSubmitted: (value) async {
                          final query = value.toString();
                          if (query.isEmpty) return;
                          try {
                            // Try cache first for search results
                            final cachedIds = HiveService.instance
                                .getCachedSearchResults(query);
                            if (cachedIds != null && cachedIds.isNotEmpty) {
                              if (context.mounted) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchResultScreen(
                                      searchQuery: query,
                                      searchResultProductsId: cachedIds,
                                      searchIn: "All Products",
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                            // If not cached, fetch from backend
                            final searchParams = ProductSearchParams(
                              query: query.toLowerCase(),
                            );
                            final searchResults = await ref.read(
                              productSearchProvider(searchParams).future,
                            );
                            // Cache the search results for future
                            await HiveService.instance.cacheSearchResults(
                              query,
                              searchResults,
                            );
                            if (context.mounted) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchResultScreen(
                                    searchQuery: query,
                                    searchResultProductsId: searchResults,
                                    searchIn: "All Products",
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            final error = e.toString();
                            Logger().e(error);
                            if (context.mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text("$error")));
                            }
                          }
                        },
                        onCartButtonPressed: () async {
                          bool allowed =
                              AuthentificationService().currentUserVerified;
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
                              if (context.mounted) {
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AsyncProgressDialog(
                                      future,
                                      message: Text(
                                        "Resending verification email",
                                      ),
                                    );
                                  },
                                );
                              }
                            }
                            return;
                          }
                          if (context.mounted) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CartScreen(),
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: 12.h),
                      Image.asset(
                        'assets/images/banner.png',
                        width: 390.w,
                        height: 195.h,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 18.h),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 4.h,
                            left: 4.w,
                            right: 4.w,
                            bottom: 0, // Reduce bottom padding
                          ),
                          child: Text(
                            'Fresh Fish Category',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 180.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: 0),
                          itemCount: productCategories.length,
                          separatorBuilder: (context, i) =>
                              SizedBox(width: 6.w),
                          itemBuilder: (context, index) {
                            final cat = productCategories[index];
                            final selected = index == selectedIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                });
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CategoryProductsScreen(
                                          key: UniqueKey(),
                                          productType: cat[PRODUCT_TYPE_KEY],
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 105.w,
                                height: 160.h,
                                alignment: Alignment.center,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: 95.w,
                                  height: 140.h,
                                  margin: EdgeInsets.only(
                                    top: 16.h,
                                    bottom: 16.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(70.r),
                                    border: selected
                                        ? Border.all(
                                            color: const Color(0xFFE0E0E0),
                                            width: 1.w,
                                          )
                                        : Border.all(
                                            color: Colors.transparent,
                                            width: 0,
                                          ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.14,
                                              ),
                                              blurRadius: 10.r,
                                              offset: Offset(0, 6.h),
                                              spreadRadius: 1.r,
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.06,
                                              ),
                                              blurRadius: 8.r,
                                              offset: Offset(0, 2.h),
                                            ),
                                          ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10.h),
                                      Container(
                                        width: 70.w,
                                        height: 70.h, // Increased image height
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: selected
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.10),
                                                    blurRadius: 8.r,
                                                    offset: Offset(0, 2.h),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            cat[ICON_KEY],
                                            width: 70.w,
                                            height: 80.h,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 20.h),
                                      SizedBox(
                                        width: 85.w,
                                        child: Text(
                                          cat[TITLE_KEY],
                                          style: TextStyle(
                                            color: selected
                                                ? const Color(0xFF2C2C2C)
                                                : Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.sp,
                                            fontFamily: 'Poppins',
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Popular Items Section
                      Align(
                        alignment: Alignment.centerLeft,

                        child: Text(
                          'Popular Items',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),

                      Consumer(
                        builder: (context, ref, _) {
                          final allProductsAsync = ref.watch(
                            latestProductsProvider(
                              99999,
                            ), // Fetch all products, no limit
                          );
                          return allProductsAsync.when(
                            data: (productIds) {
                              // Fetch all products and cache them immediately
                              return FutureBuilder<List<Product>>(
                                future:
                                    Future.wait(
                                      productIds.map((id) async {
                                        final cached = HiveService.instance
                                            .getCachedProduct(id);
                                        if (cached != null) return cached;
                                        final product =
                                            await ProductDatabaseHelper()
                                                .getProductWithID(id);
                                        return product ??
                                            Product(
                                              id,
                                              title: 'Unknown',
                                              images: [],
                                              discountPrice: 0,
                                              originalPrice: 0,
                                            );
                                      }),
                                    ).then((products) async {
                                      // Cache all products at once
                                      await HiveService.instance.cacheProducts(
                                        products,
                                      );
                                      return products;
                                    }),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    // Show shimmer effect while loading
                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: 6,
                                      separatorBuilder: (context, index) =>
                                          SizedBox(height: 20.h),
                                      itemBuilder: (context, index) {
                                        return Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 2.w,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(24.r),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 16.r,
                                                  offset: Offset(0, 8.h),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(12.w),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16.r,
                                                        ),
                                                    child: Container(
                                                      width: 80.w,
                                                      height: 80.w,
                                                      color: Colors.grey[200],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 18.h,
                                                          horizontal: 4.w,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          height: 20.h,
                                                          color:
                                                              Colors.grey[300],
                                                        ),
                                                        SizedBox(height: 8.h),
                                                        Container(
                                                          width: 80.w,
                                                          height: 14.h,
                                                          color:
                                                              Colors.grey[300],
                                                        ),
                                                        SizedBox(height: 6.h),
                                                        Row(
                                                          children: [
                                                            Container(
                                                              width: 40.w,
                                                              height: 16.h,
                                                              color: Colors
                                                                  .grey[300],
                                                            ),
                                                            SizedBox(
                                                              width: 8.w,
                                                            ),
                                                            Container(
                                                              width: 40.w,
                                                              height: 14.h,
                                                              color: Colors
                                                                  .grey[300],
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16.0,
                                                      ),
                                                  child: Container(
                                                    width: 56,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black12,
                                                          blurRadius: 12,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                  // Get user's selected address city
                                  final selectedAddressId = ref.read(
                                    selectedAddressIdProvider,
                                  );
                                  String userCity = '';
                                  if (selectedAddressId != null) {
                                    final address = HiveService.instance
                                        .getCachedAddresses()
                                        .cast<Map<dynamic, dynamic>>()
                                        .map((a) => a.cast<String, dynamic>())
                                        .firstWhere(
                                          (a) => a['id'] == selectedAddressId,
                                          orElse: () => <String, dynamic>{},
                                        );
                                    if (address['city'] != null) {
                                      userCity = (address['city'] as String)
                                          .trim()
                                          .toLowerCase();
                                    }
                                  }
                                  // Filter products by areaLocation, with debug logging
                                  final products = (snapshot.data ?? [])
                                      .where((p) {
                                        final areaLocation =
                                            (p.areaLocation ?? '')
                                                .trim()
                                                .toLowerCase();
                                        bool showProduct = false;
                                        String reason = '';
                                        if (userCity.isEmpty) {
                                          showProduct = true;
                                          reason =
                                              'userCity is empty, showing all products';
                                        } else if (areaLocation.isEmpty) {
                                          showProduct = false;
                                          reason =
                                              'areaLocation is empty, hiding product';
                                        } else if (areaLocation == userCity) {
                                          showProduct = true;
                                          reason =
                                              'areaLocation matches userCity';
                                        } else {
                                          showProduct = false;
                                          reason =
                                              'areaLocation does not match userCity';
                                        }
                                        // Debug log for each product
                                        Logger().i(
                                          '[Product Filter] userCity: "$userCity", areaLocation: "$areaLocation", show: $showProduct, reason: $reason, productId: ${p.id}',
                                        );
                                        return showProduct;
                                      })
                                      .where((p) => p.isInStock)
                                      .where(
                                        (p) =>
                                            (p as dynamic).isAvailable == true,
                                      )
                                      .toList();
                                  HiveService.instance.cacheProducts(products);
                                  if (products.isEmpty) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 32.0,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'No products available in your area.',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: products.length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(height: 16.h),
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      return _buildProductCard(product, ref);
                                    },
                                  );
                                },
                              );
                            },
                            loading: () =>
                                Center(child: CircularProgressIndicator()),
                            error: (e, _) =>
                                Center(child: Text('Failed to load products')),
                          );
                        },
                      ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, WidgetRef ref) {
    final isAvailable = (product as dynamic).isAvailable ?? true;

    // Null safety and fallback values for all fields
    final productTitle = (product.title ?? 'Unknown').split('/').first.trim();
    final productImages = product.images ?? [];
    final productImage =
        (productImages.isNotEmpty && productImages.first.isNotEmpty)
        ? productImages.first
        : null;
    final productVariant = product.variant ?? '';
    final discountPrice = product.discountPrice ?? 0.0;
    final originalPrice = product.originalPrice ?? 0.0;

    // Build image widget with proper scaling and positioning
    Widget imageWidget;
    if (productImage != null) {
      Widget imgChild;
      if (productImage.startsWith('data:image')) {
        try {
          final base64Str = productImage.split(',').last;
          imgChild = Image.memory(
            base64Decode(base64Str),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.image, size: 32.sp, color: Colors.grey),
          );
        } catch (_) {
          imgChild = Icon(Icons.image, size: 32.sp, color: Colors.grey);
        }
      } else if (productImage.startsWith('http')) {
        imgChild = Image.network(
          productImage,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.image, size: 32.sp, color: Colors.grey),
        );
      } else if (productImage.length > 100) {
        try {
          imgChild = Image.memory(
            base64Decode(productImage),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.image, size: 32.sp, color: Colors.grey),
          );
        } catch (_) {
          imgChild = Icon(Icons.image, size: 32.sp, color: Colors.grey);
        }
      } else {
        imgChild = Base64ImageService().base64ToImage(
          productImage,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }

      imageWidget = Container(
        width: 104.w,
        height: 93.h,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                isAvailable ? Colors.transparent : Colors.grey.withOpacity(0.6),
                isAvailable ? BlendMode.multiply : BlendMode.saturation,
              ),
              child: imgChild,
            ),
          ),
        ),
      );
    } else {
      imageWidget = Container(
        width: 93.w,
        height: 93.h,
        decoration: BoxDecoration(
          color: isAvailable
              ? const Color(0xFFE0E0E0)
              : const Color(0xFFE0E0E0).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(
          Icons.image,
          size: 32.sp,
          color: isAvailable ? Colors.grey : Colors.grey.withOpacity(0.5),
        ),
      );
    }

    return InkWell(
      onTap: () {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailsScreen(key: UniqueKey(), productId: product.id),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(20.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              blurRadius: 6.r,
              color: Colors.black.withOpacity(isAvailable ? 0.06 : 0.03),
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        height: 110.h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            imageWidget,
            SizedBox(width: 16.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.sp,
                            color: isAvailable
                                ? Colors.black
                                : Colors.grey.shade600,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        if (productVariant.isNotEmpty)
                          Row(
                            children: [
                              Text(
                                'Net weight: $productVariant',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: isAvailable
                                      ? const Color(0xFF8E8E93)
                                      : Colors.grey.shade500,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${discountPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                  color: isAvailable
                                      ? Colors.black
                                      : Colors.grey.shade600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(width: 6.w),
                              if (originalPrice > 0 &&
                                  originalPrice != discountPrice)
                                Text(
                                  '₹${originalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: isAvailable
                                        ? const Color(
                                            0x61000000,
                                          ) // 38% opacity black
                                        : Colors.grey.shade500,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: isAvailable
                                        ? const Color(
                                            0x61000000,
                                          ) // 38% opacity black
                                        : Colors.grey.shade500,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 4.w, bottom: 4.h),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24.r),
                              onTap: () async {
                                final selectedAddressId = ref.read(
                                  selectedAddressIdProvider,
                                );
                                if (selectedAddressId == null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Please select a delivery address before adding to cart.",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                }
                                try {
                                  final success = await UserDatabaseHelper()
                                      .addProductToCart(
                                        product.id,
                                        addressId: selectedAddressId,
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? '$productTitle added to cart!'
                                              : 'Failed to add to cart.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to add to cart: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                width: 28.w,
                                height: 28.w,
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? const Color.fromARGB(255, 0, 0, 0)
                                      : const Color(0xFFB0B0B0),
                                  borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6.r,
                                      offset: Offset(0, 2.h),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 22.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
      ),
    );
  }

  Future<void> refreshPage(WidgetRef ref) {
    ref.invalidate(latestProductsProvider);
    return Future<void>.value();
  }

  void onProductCardTapped(BuildContext context, String productId) {
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductDetailsScreen(key: UniqueKey(), productId: productId),
        ),
      );
    }
  }
}
