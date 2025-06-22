import 'package:flutter/material.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/product_details/provider_models/ProductImageSwiper.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:provider/provider.dart';

class ProductImages extends StatelessWidget {
  final Product product;

  const ProductImages({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductImageSwiper(),
      child: Consumer<ProductImageSwiper>(
        builder: (context, swiper, _) {
          return Column(
            children: [
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < 0) {
                      // Swipe Left
                      swiper.currentImageIndex =
                          (swiper.currentImageIndex + 1) % product.images!.length;
                    } else if (details.primaryVelocity! > 0) {
                      // Swipe Right
                      swiper.currentImageIndex =
                          (swiper.currentImageIndex - 1 + product.images!.length) %
                              product.images!.length;
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: SizedBox(
                    height: SizeConfig.screenHeight * 0.35,
                    width: SizeConfig.screenWidth * 0.75,
                    child: Image.network(
                      product.images![swiper.currentImageIndex],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  product.images!.length,
                  (index) => buildSmallPreview(context, swiper, index),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildSmallPreview(
      BuildContext context, ProductImageSwiper swiper, int index) {
    return GestureDetector(
      onTap: () {
        swiper.currentImageIndex = index;
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(8)),
        padding: EdgeInsets.all(getProportionateScreenHeight(8)),
        height: getProportionateScreenWidth(48),
        width: getProportionateScreenWidth(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: swiper.currentImageIndex == index
                ? kPrimaryColor
                : Colors.transparent,
          ),
        ),
        child: Image.network(product.images![index]),
      ),
    );
  }
}
