import 'package:nexoeshopee/models/Product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum ImageType { local, network }

class CustomImage {
  final ImageType imgType;
  final String path;
  final XFile? xFile; // Store XFile for web compatibility

  CustomImage({this.imgType = ImageType.local, required this.path, this.xFile});

  @override
  String toString() {
    return "Instance of Custom Image: {imgType: $imgType, path: $path, hasXFile: ${xFile != null}}";
  }
}

class ProductDetailsState {
  final List<CustomImage> selectedImages;
  final ProductType? productType;
  final List<String> searchTags;

  const ProductDetailsState({
    this.selectedImages = const [],
    this.productType,
    this.searchTags = const [],
  });

  ProductDetailsState copyWith({
    List<CustomImage>? selectedImages,
    ProductType? productType,
    List<String>? searchTags,
  }) {
    return ProductDetailsState(
      selectedImages: selectedImages ?? this.selectedImages,
      productType: productType ?? this.productType,
      searchTags: searchTags ?? this.searchTags,
    );
  }
}

class ProductDetailsNotifier extends StateNotifier<ProductDetailsState> {
  ProductDetailsNotifier() : super(const ProductDetailsState());

  void setInitialSelectedImages(List<CustomImage> images) {
    state = state.copyWith(selectedImages: images);
  }

  void setSelectedImages(List<CustomImage> images) {
    state = state.copyWith(selectedImages: images);
  }

  void setSelectedImageAtIndex(CustomImage image, int index) {
    final updatedImages = List<CustomImage>.from(state.selectedImages);
    if (index < updatedImages.length) {
      updatedImages[index] = image;
      state = state.copyWith(selectedImages: updatedImages);
    }
  }

  void addNewSelectedImage(CustomImage image) {
    final updatedImages = List<CustomImage>.from(state.selectedImages);
    updatedImages.add(image);
    state = state.copyWith(selectedImages: updatedImages);
  }

  void removeSelectedImageAtIndex(int index) {
    final updatedImages = List<CustomImage>.from(state.selectedImages);
    if (index >= 0 && index < updatedImages.length) {
      updatedImages.removeAt(index);
      state = state.copyWith(selectedImages: updatedImages);
    }
  }

  void clearSelectedImages() {
    state = state.copyWith(selectedImages: []);
  }

  void setInitialProductType(ProductType type) {
    state = state.copyWith(productType: type);
  }

  void setProductType(ProductType? type) {
    state = state.copyWith(productType: type);
  }

  void setSearchTags(List<String> tags) {
    state = state.copyWith(searchTags: tags);
  }

  void setInitSearchTags(List<String> tags) {
    state = state.copyWith(searchTags: tags);
  }

  void addSearchTag(String tag) {
    final updatedTags = List<String>.from(state.searchTags);
    updatedTags.add(tag);
    state = state.copyWith(searchTags: updatedTags);
  }

  void removeSearchTag({required int index}) {
    final updatedTags = List<String>.from(state.searchTags);
    if (index < updatedTags.length) {
      updatedTags.removeAt(index);
      state = state.copyWith(searchTags: updatedTags);
    }
  }
}

final productDetailsProvider =
    StateNotifierProvider<ProductDetailsNotifier, ProductDetailsState>((ref) {
      return ProductDetailsNotifier();
    });
