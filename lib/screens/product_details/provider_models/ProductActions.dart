import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductActionsNotifier extends StateNotifier<bool> {
  ProductActionsNotifier() : super(false);

  void setInitialFavStatus(bool status) {
    state = status;
  }

  void setFavStatus(bool status) {
    state = status;
  }

  void toggleFavStatus() {
    state = !state;
  }
}

final productActionsProvider =
    StateNotifierProvider<ProductActionsNotifier, bool>((ref) {
      return ProductActionsNotifier();
    });

// Family provider for multiple products
final productActionsFamilyProvider =
    StateNotifierProvider.family<ProductActionsNotifier, bool, String>((
      ref,
      productId,
    ) {
      return ProductActionsNotifier();
    });
