import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/services/base64_image_service/base64_image_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logger/logger.dart';
import '../constants.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/services/cache/hive_service.dart';

class ProductCard extends StatelessWidget {
  final String productId;
  final GestureTapCallback press;
  final bool showDiscountTag;
  const ProductCard({
    super.key,
    required this.productId,
    required this.press,
    this.showDiscountTag = true,
  });

  @override
  Widget build(BuildContext context) {
    final cached = HiveService.instance.getCachedProduct(productId);
    if (cached != null) {
      return GestureDetector(
        onTap: press,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: kTextColor.withOpacity(0.15)),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: buildProductCardItems(cached),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: press,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kTextColor.withOpacity(0.15)),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                final Product product = snapshot.data!;
                return buildProductCardItems(product);
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox.shrink();
              } else if (snapshot.hasError) {
                final error = snapshot.error.toString();
                Logger().e(error);
              }
              return Center(
                child: Icon(Icons.error, color: kTextColor, size: 40),
              );
            },
          ),
        ),
      ),
    );
  }

  Column buildProductCardItems(Product product) {
    // Null safety and fallback values for all fields
    final images = product.images ?? [];
    final image = (images.isNotEmpty && images[0].isNotEmpty) ? images[0] : null;
    final title = product.title ?? 'Unknown';
    final discountPrice = product.discountPrice ?? 0.0;
    final originalPrice = product.originalPrice ?? 0.0;
    final stock = product.stock;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: image != null
                ? Base64ImageService().base64ToImage(
                    image,
                    fit: BoxFit.contain,
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50),
                  ),
          ),
        ),
        SizedBox(height: 10),
        Flexible(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 1,
                child: Text(
                  "$title\n",
                  style: TextStyle(
                    color: kTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 5),
              // Stock count display
              Text(
                stock > 0 ? 'In Stock: $stock' : 'Stock Out',
                style: TextStyle(
                  color: stock > 0 ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 5),
              Flexible(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 5,
                      child: Text.rich(
                        TextSpan(
                          text: "\₹${discountPrice}\n",
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: originalPrice > 0 ? "\₹${originalPrice}" : '',
                              style: TextStyle(
                                color: kTextColor,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.normal,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showDiscountTag)
                      Flexible(
                        flex: 3,
                        child: Stack(
                          children: [
                            SvgPicture.asset(
                              "assets/icons/DiscountTag.svg",
                              color: kPrimaryColor,
                            ),
                            Center(
                              child: Text(
                                "${product.calculatePercentageDiscount()}%",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              // Add to Cart or Stock Out button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: stock > 0 ? press : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: stock > 0 ? kPrimaryColor : Colors.grey,
                  ),
                  child: Text(
                    stock > 0 ? 'Add to Cart' : 'Stock Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
