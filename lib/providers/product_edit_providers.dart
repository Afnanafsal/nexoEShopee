import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/edit_product/provider_models/ProductDetails.dart';
import 'package:nexoeshopee/providers/product_providers.dart';

// State for product editing/creation
class ProductEditState {
  final List<CustomImage> selectedImages;
  final ProductType? productType;
  final List<String> searchTags;
  final bool isLoading;
  final String? error;

  const ProductEditState({
    this.selectedImages = const [],
    this.productType,
    this.searchTags = const [],
    this.isLoading = false,
    this.error,
  });

  ProductEditState copyWith({
    List<CustomImage>? selectedImages,
    ProductType? productType,
    List<String>? searchTags,
    bool? isLoading,
    String? error,
  }) {
    return ProductEditState(
      selectedImages: selectedImages ?? this.selectedImages,
      productType: productType ?? this.productType,
      searchTags: searchTags ?? this.searchTags,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProductEditNotifier extends StateNotifier<ProductEditState> {
  ProductEditNotifier() : super(const ProductEditState());

  void setSelectedImages(List<CustomImage> images) {
    state = state.copyWith(selectedImages: images);
  }

  void addSelectedImage(CustomImage image) {
    final newImages = [...state.selectedImages, image];
    state = state.copyWith(selectedImages: newImages);
  }

  void setImageAtIndex(CustomImage image, int index) {
    if (index < state.selectedImages.length) {
      final newImages = [...state.selectedImages];
      newImages[index] = image;
      state = state.copyWith(selectedImages: newImages);
    }
  }

  void removeImageAtIndex(int index) {
    if (index < state.selectedImages.length) {
      final newImages = [...state.selectedImages]..removeAt(index);
      state = state.copyWith(selectedImages: newImages);
    }
  }

  void setProductType(ProductType? type) {
    state = state.copyWith(productType: type);
  }

  void setSearchTags(List<String> tags) {
    state = state.copyWith(searchTags: tags);
  }

  void addSearchTag(String tag) {
    final newTags = [...state.searchTags, tag];
    state = state.copyWith(searchTags: newTags);
  }

  void removeSearchTag(int index) {
    if (index < state.searchTags.length) {
      final newTags = [...state.searchTags]..removeAt(index);
      state = state.copyWith(searchTags: newTags);
    }
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const ProductEditState();
  }

  void initializeWithProduct(Product product) {
    final images =
        product.images
            ?.map(
              (base64) => CustomImage(imgType: ImageType.network, path: base64),
            )
            .toList() ??
        [];

    state = ProductEditState(
      selectedImages: images,
      productType: product.productType,
      searchTags: product.searchTags ?? [],
    );
  }
}

final productEditProvider =
    StateNotifierProvider<ProductEditNotifier, ProductEditState>((ref) {
      return ProductEditNotifier();
    });

// Provider for initializing product edit with existing product
final productEditInitializerProvider = FutureProvider.family<void, String?>((
  ref,
  productId,
) async {
  if (productId != null) {
    final product = await ref.read(productProvider(productId).future);
    if (product != null) {
      ref.read(productEditProvider.notifier).initializeWithProduct(product);
    }
  }
});
