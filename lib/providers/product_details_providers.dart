import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/providers/user_providers.dart';

// State for product image swiper
class ProductImageSwiperState {
  final int currentImageIndex;

  const ProductImageSwiperState({this.currentImageIndex = 0});

  ProductImageSwiperState copyWith({int? currentImageIndex}) {
    return ProductImageSwiperState(
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
    );
  }
}

class ProductImageSwiperNotifier
    extends StateNotifier<ProductImageSwiperState> {
  ProductImageSwiperNotifier() : super(const ProductImageSwiperState());

  void setCurrentImageIndex(int index) {
    state = state.copyWith(currentImageIndex: index);
  }

  void nextImage(int totalImages) {
    final nextIndex = (state.currentImageIndex + 1) % totalImages;
    state = state.copyWith(currentImageIndex: nextIndex);
  }

  void previousImage(int totalImages) {
    final prevIndex = (state.currentImageIndex - 1 + totalImages) % totalImages;
    state = state.copyWith(currentImageIndex: prevIndex);
  }
}

final productImageSwiperProvider =
    StateNotifierProvider.family<
      ProductImageSwiperNotifier,
      ProductImageSwiperState,
      String
    >((ref, productId) {
      return ProductImageSwiperNotifier();
    });

// State for expandable text
class ExpandableTextState {
  final bool isExpanded;

  const ExpandableTextState({this.isExpanded = false});

  ExpandableTextState copyWith({bool? isExpanded}) {
    return ExpandableTextState(isExpanded: isExpanded ?? this.isExpanded);
  }
}

class ExpandableTextNotifier extends StateNotifier<ExpandableTextState> {
  ExpandableTextNotifier() : super(const ExpandableTextState());

  void toggle() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void expand() {
    state = state.copyWith(isExpanded: true);
  }

  void collapse() {
    state = state.copyWith(isExpanded: false);
  }
}

final expandableTextProvider =
    StateNotifierProvider.family<
      ExpandableTextNotifier,
      ExpandableTextState,
      String
    >((ref, textId) {
      return ExpandableTextNotifier();
    });

// State for product actions
class ProductActionsState {
  final bool productFavStatus;
  final bool isLoading;

  const ProductActionsState({
    this.productFavStatus = false,
    this.isLoading = false,
  });

  ProductActionsState copyWith({bool? productFavStatus, bool? isLoading}) {
    return ProductActionsState(
      productFavStatus: productFavStatus ?? this.productFavStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProductActionsNotifier extends StateNotifier<ProductActionsState> {
  final Ref ref;
  final String productId;

  ProductActionsNotifier(this.ref, this.productId)
    : super(const ProductActionsState()) {
    _loadFavoriteStatus();
  }

  void _loadFavoriteStatus() async {
    try {
      final isFav = await ref.read(
        isProductFavouriteProvider(productId).future,
      );
      state = state.copyWith(productFavStatus: isFav);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  void setProductFavStatus(bool status) {
    state = state.copyWith(productFavStatus: status);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  Future<void> toggleFavorite() async {
    state = state.copyWith(isLoading: true);
    try {
      final userHelper = ref.read(userDatabaseHelperProvider);
      final newStatus = !state.productFavStatus;
      await userHelper.switchProductFavouriteStatus(productId, newStatus);
      state = state.copyWith(productFavStatus: newStatus, isLoading: false);
      // Invalidate related providers
      ref.invalidate(isProductFavouriteProvider(productId));
      ref.invalidate(favouriteProductsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final productActionsProvider =
    StateNotifierProvider.family<
      ProductActionsNotifier,
      ProductActionsState,
      String
    >((ref, productId) {
      return ProductActionsNotifier(ref, productId);
    });
