import 'package:hive/hive.dart';
import 'package:nexoeshopee/models/Product.dart';

part 'cached_product.g.dart';

@HiveType(typeId: 0)
class CachedProduct extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  List<String>? images;

  @HiveField(4)
  double? originalPrice;

  @HiveField(5)
  double? discountPrice;

  @HiveField(6)
  String? seller;

  @HiveField(7)
  String? owner;

  @HiveField(8)
  DateTime cachedAt;

  @HiveField(9)
  String? productType;

  @HiveField(10)
  String? highlights;

  @HiveField(11)
  List<String>? searchTags;

  @HiveField(12)
  String? variant;

  @HiveField(13)
  double rating;

  @HiveField(14)
  DateTime? dateAdded;

  CachedProduct({
    required this.id,
    this.title,
    this.description,
    this.images,
    this.originalPrice,
    this.discountPrice,
    this.seller,
    this.owner,
    required this.cachedAt,
    this.productType,
    this.highlights,
    this.searchTags,
    this.variant,
    this.rating = 0.0,
    this.dateAdded,
  });

  // Convert from your existing Product model
  factory CachedProduct.fromProduct(Product product) {
    return CachedProduct(
      id: product.id,
      title: product.title,
      description: product.description,
      images: product.images,
      originalPrice: product.originalPrice?.toDouble(),
      discountPrice: product.discountPrice?.toDouble(),
      seller: product.seller,
      owner: product.owner,
      cachedAt: DateTime.now(),
      productType: product.productType?.toString(),
      highlights: product.highlights,
      searchTags: product.searchTags,
      variant: product.variant,
      rating: product.rating.toDouble(),
      dateAdded: product.dateAdded,
    );
  }

  // Convert to your existing Product model
  Product toProduct() {
    return Product(
      id,
      title: title,
      description: description,
      images: images,
      originalPrice: originalPrice,
      discountPrice: discountPrice,
      seller: seller,
      owner: owner,
      productType: productType != null
          ? ProductType.values.firstWhere(
              (e) => e.toString() == productType,
              orElse: () => ProductType.Others,
            )
          : null,
      highlights: highlights,
      searchTags: searchTags,
      variant: variant,
      rating: rating,
      dateAdded: dateAdded,
    );
  }

  bool get isExpired {
    // Cache expires after 1 hour
    return DateTime.now().difference(cachedAt).inHours > 1;
  }
}
