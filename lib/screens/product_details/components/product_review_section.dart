import 'package:fishkart/components/top_rounded_container.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/providers/product_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

import '../../../constants.dart';
import '../../../size_config.dart';
import 'review_box.dart';

class ProductReviewsSection extends ConsumerWidget {
  const ProductReviewsSection({required Key key, required this.product})
    : super(key: key);

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(product.id));

    return SizedBox(
      height: getProportionateScreenHeight(320),
      child: Stack(
        children: [
          TopRoundedContainer(
            key: const Key('top_rounded_container'),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Product Reviews",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(20)),
                Expanded(
                  child: reviewsAsync.when(
                    data: (reviewsList) {
                      if (reviewsList.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              SvgPicture.asset(
                                "assets/icons/review.svg",
                                color: kTextColor,
                                width: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "No reviews yet",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        physics: BouncingScrollPhysics(),
                        itemCount: reviewsList.length,
                        itemBuilder: (context, index) {
                          return ReviewBox(
                            key: ValueKey(reviewsList[index].id),
                            review: reviewsList[index],
                            productId: product.id,
                          );
                        },
                      );
                    },
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 3,
                        itemBuilder: (context, index) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    height: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 80,
                                    height: 12,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: kPrimaryColor,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Something went wrong!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "$error",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(alignment: Alignment.topCenter),
        ],
      ),
    );
  }
}
