import 'package:fishkart/components/top_rounded_container.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/providers/product_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      height: 320.h,
      child: Stack(
        children: [
          TopRoundedContainer(
            key: const Key('top_rounded_container'),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Product Reviews",
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
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
                                  width: 40.w,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "No reviews yet",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
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
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 3,
                          itemBuilder: (context, index) => Container(
                            margin: EdgeInsets.symmetric(vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6.r,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 120.w,
                                      height: 16.h,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 8.h),
                                    Container(
                                      width: double.infinity,
                                      height: 12.h,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 8.h),
                                    Container(
                                      width: 80.w,
                                      height: 12.h,
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
                              size: 60.sp,
                              color: kPrimaryColor,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "Something went wrong!",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "$error",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
