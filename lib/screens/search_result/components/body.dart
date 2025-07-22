import 'package:fishkart/components/nothingtoshow_container.dart';
import 'package:fishkart/components/product_card.dart';
import 'package:fishkart/constants.dart';
import 'package:fishkart/screens/product_details/product_details_screen.dart';
import 'package:fishkart/size_config.dart';
import 'package:flutter/material.dart';
import 'package:fishkart/services/cache/hive_service.dart';
import 'package:fishkart/services/database/product_database_helper.dart';

class Body extends StatelessWidget {
  final String searchQuery;
  final List<String> searchResultProductsId;
  final String searchIn;

  const Body({
    Key? key,
    required this.searchQuery,
    required this.searchResultProductsId,
    required this.searchIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Preload and cache all products for search results
    for (final id in searchResultProductsId) {
      final cached = HiveService.instance.getCachedProduct(id);
      if (cached == null) {
        ProductDatabaseHelper().getProductWithID(id).then((product) {
          if (product != null) HiveService.instance.cacheProduct(product);
        });
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(screenPadding),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(height: getProportionateScreenHeight(10)),
                Text("Search Result", style: headingStyle),
                Text.rich(
                  TextSpan(
                    text: "$searchQuery",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                    children: [
                      TextSpan(
                        text: " in ",
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      TextSpan(
                        text: "$searchIn",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(30)),
                SizedBox(
                  height: SizeConfig.screenHeight * 0.75,
                  child: buildProductsGrid(),
                ),
                SizedBox(height: getProportionateScreenHeight(30)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProductsGrid() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F6F9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Builder(
        builder: (context) {
          if (searchResultProductsId.length > 0) {
            return GridView.builder(
              shrinkWrap: true,
              physics: BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: searchResultProductsId.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  productId: searchResultProductsId[index],
                  press: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(
                          key: Key(searchResultProductsId[index]),
                          productId: searchResultProductsId[index],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
          return Center(
            child: NothingToShowContainer(
              iconPath: "assets/icons/search_no_found.svg",
              secondaryMessage: "Found 0 Products",
              primaryMessage: "Try another search keyword",
            ),
          );
        },
      ),
    );
  }
}
