import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/cart/cart_screen.dart';
import 'package:nexoeshopee/screens/category_products/category_products_screen.dart';
import 'package:nexoeshopee/screens/product_details/product_details_screen.dart';
import 'package:nexoeshopee/screens/search_result/search_result_screen.dart';
import 'package:nexoeshopee/services/authentification/authentification_service.dart';
import 'package:nexoeshopee/providers/providers.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:logger/logger.dart';
import '../../../utils.dart';
import '../components/home_header.dart';
import '../components/delivery_address_bar.dart';
import 'product_type_box.dart';
import 'products_section.dart';

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
      ICON_KEY: "assets/icons/Mackerel.png",
      TITLE_KEY: "Saltwater Fish",
      PRODUCT_TYPE_KEY: ProductType.Saltwater,
      "examples": ["Pomfret", "King Fish", "Mackerel"],
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/prawns.png",
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
    final favouriteProductsAsync = ref.watch(latestProductsProvider(20));
    final allProductsAsync = ref.watch(latestProductsProvider(50));

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
                          if (query.length <= 0) return;
                          try {
                            final searchParams = ProductSearchParams(
                              query: query.toLowerCase(),
                            );
                            final searchResults = await ref.read(
                              productSearchProvider(searchParams).future,
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
                      SizedBox(
                        height: SizeConfig.screenHeight * 0.5,
                        child: ProductsSection(
                          sectionTitle: "Today's Fresh Arrivals",
                          productsAsync: favouriteProductsAsync,
                          emptyListMessage: "No fresh arrivals today",
                          onProductCardTapped: (productId) =>
                              onProductCardTapped(context, productId),
                        ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(20)),
                      SizedBox(
                        height: SizeConfig.screenHeight * 0.8,
                        child: ProductsSection(
                          sectionTitle: "Explore Our Fresh Meat Selection",
                          productsAsync: allProductsAsync,
                          emptyListMessage:
                              "Our butchers are preparing fresh stock",
                          onProductCardTapped: (productId) =>
                              onProductCardTapped(context, productId),
                        ),
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
