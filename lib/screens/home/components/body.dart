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
import 'package:fishkart/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:fishkart/services/cache/hive_service.dart';
import 'package:shimmer/shimmer.dart';
import '../../../utils.dart';
import '../components/home_header.dart';
import 'product_type_box.dart';

const String ICON_KEY = "icon";
const String TITLE_KEY = "title";
const String PRODUCT_TYPE_KEY = "product_type";

class Body extends ConsumerWidget {
  final productCategories = <Map>[
    <String, dynamic>{
      ICON_KEY: "assets/icons/rohu.png",
      TITLE_KEY: "Freshwater Fish",
      PRODUCT_TYPE_KEY: ProductType.Freshwater,
      "examples": ["Rohu", "Catla", "Tilapia"],
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/Pomfret.png",
      TITLE_KEY: "Saltwater Fish",
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
      TITLE_KEY: "Exotic Fish",
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
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => refreshPage(ref),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(screenPadding),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(height: getProportionateScreenHeight(15)),
                      HomeHeader(
                        onSearchSubmitted: (value) async {
                          final query = value.toString();
                          if (query.isEmpty) return;
                          try {
                            // Try cache first for search results
                            final cachedIds = HiveService.instance
                                .getCachedSearchResults(query);
                            if (cachedIds != null && cachedIds.isNotEmpty) {
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
                          } catch (e) {
                            final error = e.toString();
                            Logger().e(error);
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text("$error")));
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
                            return;
                          }
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: getProportionateScreenHeight(10)),
                      Image.asset(
                        'assets/images/banner.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: getProportionateScreenHeight(15)),
                      SizedBox(
                        height: SizeConfig.screenHeight * 0.191,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: BouncingScrollPhysics(),
                            itemCount: productCategories.length,
                            itemBuilder: (context, index) {
                              return ProductTypeBox(
                                icon: productCategories[index][ICON_KEY],
                                title: productCategories[index][TITLE_KEY],
                                onPress: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CategoryProductsScreen(
                                        key: UniqueKey(),
                                        productType:
                                            productCategories[index][PRODUCT_TYPE_KEY],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(20)),
                      // Popular Items Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'Popular Items',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Color(0xFF2B344F),
                            ),
                          ),
                        ),
                      ),
                      // Only load a small batch of products for first-time users for speed
                      Consumer(
                        builder: (context, ref, _) {
                          final allProductsAsync = ref.watch(
                            latestProductsProvider(12), // Reduced from 50 to 8 for faster load
                          );
                          return allProductsAsync.when(
                            data: (productIds) {
                              // Show shimmer/placeholder while loading products
                              // Only load a small batch for first-time users
                              return FutureBuilder<List<Product>>(
                                future: Future.wait(
                                  productIds.map((id) async {
                                    final cached = HiveService.instance.getCachedProduct(id);
                                    if (cached != null) return cached;
                                    final product = await ProductDatabaseHelper().getProductWithID(id);
                                    if (product != null) await HiveService.instance.cacheProduct(product);
                                    return product ?? Product(id, title: 'Unknown', images: [], discountPrice: 0, originalPrice: 0);
                                  }),
                                ),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    // Show shimmer effect while loading
                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: 6,
                                      separatorBuilder: (context, index) => SizedBox(height: 20),
                                      itemBuilder: (context, index) {
                                        return Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(
                                            margin: EdgeInsets.symmetric(horizontal: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
                                              ],
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(12.0),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(16),
                                                    child: Container(
                                                      width: 80,
                                                      height: 80,
                                                      color: Colors.grey[200],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 4.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(width: double.infinity, height: 18, color: Colors.grey[300]),
                                                        SizedBox(height: 8),
                                                        Container(width: 80, height: 14, color: Colors.grey[300]),
                                                        SizedBox(height: 6),
                                                        Row(
                                                          children: [
                                                            Container(width: 40, height: 16, color: Colors.grey[300]),
                                                            SizedBox(width: 8),
                                                            Container(width: 40, height: 14, color: Colors.grey[300]),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                  child: Container(
                                                    width: 56,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
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
                                  final selectedAddressId = ref.read(selectedAddressIdProvider);
                                  String userCity = '';
                                  if (selectedAddressId != null) {
                                    final address = HiveService.instance.getCachedAddresses().firstWhere(
                                      (a) => a['id'] == selectedAddressId,
                                      orElse: () => <String, dynamic>{},
                                    );
                                    if (address['city'] != null) {
                                      userCity = (address['city'] as String).trim().toLowerCase();
                                    }
                                  }
                                  // Filter products by areaLocation
                                  final products = (snapshot.data ?? [])
                                    .where((p) {
                                      final areaLocation = (p.areaLocation ?? '').trim().toLowerCase();
                                      if (userCity.isEmpty || areaLocation.isEmpty) return true;
                                      return areaLocation == userCity;
                                    })
                                    .where((p) => p.isInStock)
                                    .take(8)
                                    .toList();
                                  HiveService.instance.cacheProducts(products);
                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: products.length,
                                    separatorBuilder: (context, index) => SizedBox(height: 20),
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      // Null safety and fallback values for all fields
                                      final productTitle = product.title ?? 'Unknown';
                                      final productImages = product.images ?? [];
                                      final productImage = (productImages.isNotEmpty && productImages.first.isNotEmpty) ? productImages.first : null;
                                      final productVariant = product.variant ?? '';
                                      final discountPrice = product.discountPrice ?? 0.0;
                                      final originalPrice = product.originalPrice ?? 0.0;
                                      return InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProductDetailsScreen(key: UniqueKey(), productId: product.id),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          margin: EdgeInsets.symmetric(horizontal: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(16),
                                                  child: Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey[200],
                                                    child: productImage != null
                                                        ? Base64ImageService().base64ToImage(productImage, fit: BoxFit.cover, width: 80, height: 80)
                                                        : Center(child: Icon(Icons.image, color: Colors.grey, size: 40)),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 4.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(productTitle, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF2B344F)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                      if (productVariant.isNotEmpty)
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 2.0),
                                                          child: Text('Net weight: $productVariant', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                                        ),
                                                      SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          Text('₹${discountPrice.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black)),
                                                          if (originalPrice > 0)
                                                            Padding(
                                                              padding: const EdgeInsets.only(left: 8.0),
                                                              child: Text('₹${originalPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: Colors.black38, decoration: TextDecoration.lineThrough)),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(32),
                                                    onTap: () {
                                                      final selectedAddressId = ref.read(selectedAddressIdProvider);
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$productTitle added to cart!')));
                                                      UserDatabaseHelper().addProductToCart(product.id, addressId: selectedAddressId).catchError((e) {
                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add to cart: $e')));
                                                        return false;
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 56,
                                                      height: 56,
                                                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)]),
                                                      child: Icon(Icons.add, size: 36, color: Color(0xFF2B344F)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
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
                      SizedBox(height: getProportionateScreenHeight(80)),
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

  Future<void> refreshPage(WidgetRef ref) {
    ref.invalidate(latestProductsProvider);
    return Future<void>.value();
  }

  void onProductCardTapped(BuildContext context, String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailsScreen(key: UniqueKey(), productId: productId),
      ),
    );
  }
}
