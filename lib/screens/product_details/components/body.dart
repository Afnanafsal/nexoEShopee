import 'package:shimmer/shimmer.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/product_details/components/product_actions_section.dart';
import 'package:nexoeshopee/screens/product_details/components/product_images.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/services/cache/hive_service.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'product_review_section.dart';

class Body extends StatelessWidget {
  final String productId;

  const Body({required Key key, required this.productId}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final cached = HiveService.instance.getCachedProduct(productId);
    if (cached != null) {
      return SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductImages(product: cached),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(screenPadding),
                ),
                child: Column(
                  children: [
                    SizedBox(height: getProportionateScreenHeight(20)),
                    ProductActionsSection(
                      key: Key('ProductActionsSection_${cached.id}'),
                      product: cached,
                    ),
                    SizedBox(height: getProportionateScreenHeight(20)),
                    ProductReviewsSection(
                      key: Key('ProductReviewsSection_${cached.id}'),
                      product: cached,
                    ),
                    SizedBox(height: getProportionateScreenHeight(100)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: FutureBuilder<Product?>(
          future: (() async {
            final product = await ProductDatabaseHelper().getProductWithID(
              productId,
            );
            if (product != null)
              await HiveService.instance.cacheProduct(product);
            return product;
          })(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final product = snapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProductImages(product: product!),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(screenPadding),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: getProportionateScreenHeight(20)),
                        ProductActionsSection(
                          key: Key('ProductActionsSection_${product.id}'),
                          product: product,
                        ),
                        SizedBox(height: getProportionateScreenHeight(20)),
                        ProductReviewsSection(
                          key: Key('ProductReviewsSection_${product.id}'),
                          product: product,
                        ),
                        SizedBox(height: getProportionateScreenHeight(100)),
                      ],
                    ),
                  ),
                ],
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: getProportionateScreenHeight(300),
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: getProportionateScreenWidth(
                            screenPadding,
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: getProportionateScreenHeight(20)),
                            Container(
                              width: double.infinity,
                              height: 32,
                              color: Colors.white,
                            ),
                            SizedBox(height: getProportionateScreenHeight(20)),
                            Container(
                              width: double.infinity,
                              height: 120,
                              color: Colors.white,
                            ),
                            SizedBox(height: getProportionateScreenHeight(20)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              final error = snapshot.error.toString();
              Logger().e(error);
            }
            return Center(
              child: Icon(Icons.error, color: kTextColor, size: 60),
            );
          },
        ),
      ),
    );
  }
}
