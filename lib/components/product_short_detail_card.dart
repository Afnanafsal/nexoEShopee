import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/services/base64_image_service/base64_image_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';

import '../constants.dart';
import '../size_config.dart';

class ProductShortDetailCard extends StatelessWidget {
  final String productId;
  final VoidCallback onPressed;
  const ProductShortDetailCard({
    super.key,
    required this.productId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: FutureBuilder<Product?>(
        future: ProductDatabaseHelper().getProductWithID(productId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final product = snapshot.data!;
            return Container(
              height: 150, // Increased height for card and image

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 120, // Slightly wider for better aspect
                      height: 110, // Increased height for image
                      color: Colors.grey[200],
                      child:
                          product.images != null && product.images!.isNotEmpty
                          ? Base64ImageService().base64ToImage(
                              product.images![0],
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.title ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.variant != null &&
                            product.variant!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              product.variant!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "\₹${product.discountPrice}",
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "\₹${product.originalPrice}",
                              style: TextStyle(
                                color: kTextColor,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            // Shimmer placeholder for product short detail card
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 80,
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: 80,
                              height: 14,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            final errorMessage = snapshot.error.toString();
            Logger().e(errorMessage);
          }
          return Center(child: Icon(Icons.error, color: kTextColor, size: 60));
        },
      ),
    );
  }
}
