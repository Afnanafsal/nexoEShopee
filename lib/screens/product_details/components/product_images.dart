import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/providers/product_details_providers.dart';
import 'package:nexoeshopee/services/base64_image_service/base64_image_service.dart';
import 'package:nexoeshopee/size_config.dart';

class ProductImages extends ConsumerWidget {
  final Product product;

  const ProductImages({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swiperState = ref.watch(productImageSwiperProvider(product.id));

    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < 0) {
                      // Swipe Left
                      ref
                          .read(productImageSwiperProvider(product.id).notifier)
                          .nextImage(product.images!.length);
                    } else if (details.primaryVelocity! > 0) {
                      // Swipe Right
                      ref
                          .read(productImageSwiperProvider(product.id).notifier)
                          .previousImage(product.images!.length);
                    }
                  }
                },
                child: SizedBox(
                  height: SizeConfig.screenHeight * 0.35,
                  width: MediaQuery.of(context).size.width,
                  child: Base64ImageService().base64ToImage(
                    product.images![swiperState.currentImageIndex],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.7),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            product.images!.length,
            (index) => buildSmallPreview(context, ref, index),
          ),
        ),
      ],
    );
  }

  Widget buildSmallPreview(BuildContext context, WidgetRef ref, int index) {
    final swiperState = ref.watch(productImageSwiperProvider(product.id));

    return GestureDetector(
      onTap: () {
        ref
            .read(productImageSwiperProvider(product.id).notifier)
            .setCurrentImageIndex(index);
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(8),
        ),
        padding: EdgeInsets.all(getProportionateScreenHeight(8)),
        height: getProportionateScreenWidth(48),
        width: getProportionateScreenWidth(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: swiperState.currentImageIndex == index
                ? kPrimaryColor
                : Colors.transparent,
          ),
        ),
        child: Base64ImageService().base64ToImage(product.images![index]),
      ),
    );
  }
}
