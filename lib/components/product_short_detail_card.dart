import 'package:fishkart/models/Product.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/services/base64_image_service/base64_image_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import '../constants.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/models/Review.dart';
import 'package:fishkart/screens/my_orders/components/product_review_dialog.dart';

// Top-level function to display product image from base64 or network
Widget buildProductImage(String imageStr) {
  final isBase64 = imageStr.length > 100 && !imageStr.startsWith('http');
  if (isBase64) {
    try {
      final bytes = Base64ImageService().base64ToBytes(imageStr);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: 120,
        height: 110,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
      );
    } catch (e) {
      return Icon(Icons.broken_image, size: 48, color: Colors.grey[400]);
    }
  } else {
    return Image.network(
      imageStr,
      fit: BoxFit.cover,
      width: 120,
      height: 110,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
    );
  }
}

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
                      width: 120,
                      height: 110,
                      color: Colors.grey[200],
                      child:
                          (product.images != null &&
                              product.images!.isNotEmpty &&
                              product.images!.first.isNotEmpty)
                          ? buildProductImage(product.images!.first)
                          : Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "\₹${product.discountPrice}",
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "\₹${product.originalPrice}",
                              style: TextStyle(
                                color: kTextColor,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.normal,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
            final screenWidth = MediaQuery.of(context).size.width;
            final imageSize = screenWidth * 0.22;
            final textWidth = screenWidth * 0.35;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: imageSize,
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: imageSize,
                          height: imageSize,
                          color: Colors.grey[300],
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: textWidth,
                              height: 16,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: imageSize * 0.1),
                            Container(
                              width: textWidth * 0.6,
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
