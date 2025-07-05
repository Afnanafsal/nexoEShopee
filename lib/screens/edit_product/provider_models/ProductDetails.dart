import 'package:nexoeshopee/models/Product.dart';
import 'package:flutter/material.dart';
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

class ProductDetails extends ChangeNotifier {
  List<CustomImage> _selectedImages = [];
  ProductType? _productType;
  List<String> _searchTags = [];

  List<CustomImage> get selectedImages {
    return _selectedImages;
  }

  set initialSelectedImages(List<CustomImage> images) {
    _selectedImages = images;
  }

  set selectedImages(List<CustomImage> images) {
    _selectedImages = images;
    notifyListeners();
  }

  void setSelectedImageAtIndex(CustomImage image, int index) {
    if (index < _selectedImages.length) {
      _selectedImages[index] = image;
      notifyListeners();
    }
  }

  void addNewSelectedImage(CustomImage image) {
    _selectedImages.add(image);
    notifyListeners();
  }

  ProductType? get productType {
    return _productType;
  }

  set initialProductType(ProductType type) {
    _productType = type;
  }

  set productType(ProductType? type) {
    _productType = type;
    notifyListeners();
  }

  List<String> get searchTags {
    return _searchTags;
  }

  set searchTags(List<String> tags) {
    _searchTags = tags;
    notifyListeners();
  }

  set initSearchTags(List<String> tags) {
    _searchTags = tags;
  }

  void addSearchTag(String tag) {
    _searchTags.add(tag);
    notifyListeners();
  }

  void removeSearchTag({required int index}) {
    _searchTags.removeAt(index);
    notifyListeners();
  }
}
