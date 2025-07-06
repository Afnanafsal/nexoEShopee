import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/cart/cart_screen.dart';
import 'package:nexoeshopee/screens/category_products/category_products_screen.dart';
import 'package:nexoeshopee/screens/product_details/product_details_screen.dart';
import 'package:nexoeshopee/screens/search_result/search_result_screen.dart';
//import 'package:nexoeshopee/screens/category_products/category_products_screen.dart';
import 'package:nexoeshopee/services/authentification/authentification_service.dart';
import 'package:nexoeshopee/services/data_streams/all_products_stream.dart';
import 'package:nexoeshopee/services/data_streams/favourite_products_stream.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:flutter/material.dart';
//import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:logger/logger.dart';
import '../../../utils.dart';
import '../components/home_header.dart';
import '../components/delivery_address_bar.dart';
import 'product_type_box.dart';
import 'products_section.dart';

const String ICON_KEY = "icon";
const String TITLE_KEY = "title";
const String PRODUCT_TYPE_KEY = "product_type";

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final productCategories = <Map>[
    <String, dynamic>{
      ICON_KEY: "assets/icons/chicken.svg",
      TITLE_KEY: "Chicken",
      PRODUCT_TYPE_KEY: ProductType.Chicken,
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/mutton.svg",
      TITLE_KEY: "Mutton",
      PRODUCT_TYPE_KEY: ProductType.Mutton,
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/beef.svg",
      TITLE_KEY: "Beef",
      PRODUCT_TYPE_KEY: ProductType.Beef,
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/fish.svg",
      TITLE_KEY: "Fish",
      PRODUCT_TYPE_KEY: ProductType.Fish,
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/eggs.svg",
      TITLE_KEY: "Eggs",
      PRODUCT_TYPE_KEY: ProductType.Eggs,
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/marinated.svg",
      TITLE_KEY: "Marinated",
      PRODUCT_TYPE_KEY: ProductType.MarinatedItems,
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/ready_to_eat.svg",
      TITLE_KEY: "Ready to Eat",
      PRODUCT_TYPE_KEY: ProductType.ReadyToEat,
    },
    <String, dynamic>{
      ICON_KEY: "assets/icons/others.svg",
      TITLE_KEY: "Others",
      PRODUCT_TYPE_KEY: ProductType.Others,
    },
  ];

  final FavouriteProductsStream favouriteProductsStream =
      FavouriteProductsStream();
  final AllProductsStream allProductsStream = AllProductsStream();

  @override
  void initState() {
    super.initState();
    favouriteProductsStream.init();
    allProductsStream.init();
  }

  @override
  void dispose() {
    favouriteProductsStream.dispose();
    allProductsStream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refreshPage,
        child: Column(
          children: [
            DeliveryAddressBar(),
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
                          List<String> searchedProductsId;
                          try {
                            searchedProductsId = await ProductDatabaseHelper()
                                .searchInProducts(query.toLowerCase());
                            // ignore: unnecessary_null_comparison
                            if (searchedProductsId != null) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchResultScreen(
                                    searchQuery: query,
                                    searchResultProductsId: searchedProductsId,
                                    searchIn: "All Products",
                                  ),
                                ),
                              );
                              await refreshPage();
                            } else {
                              throw "Couldn't perform search due to some unknown reason";
                            }
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
                          await refreshPage();
                        },
                      ),
                      SizedBox(height: getProportionateScreenHeight(15)),
                      SizedBox(
                        height: SizeConfig.screenHeight * 0.1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: BouncingScrollPhysics(),
                            children: [
                              ...List.generate(productCategories.length, (
                                index,
                              ) {
                                return ProductTypeBox(
                                  icon: productCategories[index][ICON_KEY],
                                  title: productCategories[index][TITLE_KEY],
                                  onPress: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CategoryProductsScreen(
                                              key: UniqueKey(),
                                              productType:
                                                  productCategories[index][PRODUCT_TYPE_KEY],
                                            ),
                                      ),
                                    );
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(20)),
                      SizedBox(
                        height: SizeConfig.screenHeight * 0.5,
                        child: ProductsSection(
                          sectionTitle: "Today's Fresh Arrivals",
                          productsStreamController: favouriteProductsStream,
                          emptyListMessage: "No fresh arrivals today",
                          onProductCardTapped: onProductCardTapped,
                        ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(20)),
                      SizedBox(
                        height: SizeConfig.screenHeight * 0.8,
                        child: ProductsSection(
                          sectionTitle: "Explore Our Fresh Meat Selection",
                          productsStreamController: allProductsStream,
                          emptyListMessage: "Our butchers are preparing fresh stock",
                          onProductCardTapped: onProductCardTapped,
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

  Future<void> refreshPage() {
    favouriteProductsStream.reload();
    allProductsStream.reload();
    return Future<void>.value();
  }

  void onProductCardTapped(String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailsScreen(key: UniqueKey(), productId: productId),
      ),
    ).then((_) async {
      await refreshPage();
    });
  }
}
