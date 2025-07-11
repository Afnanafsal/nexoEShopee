import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductImageSwiperNotifier extends StateNotifier<int> {
  ProductImageSwiperNotifier() : super(0);

  void setCurrentImageIndex(int index) {
    state = index;
  }

  void nextImage(int maxIndex) {
    if (state < maxIndex - 1) {
      state = state + 1;
    }
  }

  void previousImage() {
    if (state > 0) {
      state = state - 1;
    }
  }

  void reset() {
    state = 0;
  }
}

final productImageSwiperProvider =
    StateNotifierProvider<ProductImageSwiperNotifier, int>((ref) {
      return ProductImageSwiperNotifier();
    });
