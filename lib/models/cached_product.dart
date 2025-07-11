import 'package:hive/hive.dart';
import 'package:nexoeshopee/models/Product.dart';

part 'cached_product.g.dart';

@HiveType(typeId: 0)
class CachedProduct extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  List<String>? images;

  @HiveField(2)
  String? title;

  @HiveField(3)
  String? variant;

  @HiveField(4)
  num? discountPrice;

  @HiveField(5)
  num? originalPrice;

  @HiveField(6)
  num rating;

  @HiveField(7)
  String? highlights;

  @HiveField(8)
  String? description;

  @HiveField(9)
  String? seller;

  @HiveField(10)
  String? owner;

  @HiveField(11)
  String? productType;

  @HiveField(12)
  List<String>? searchTags;

  @HiveField(13)
  DateTime? dateAdded;

  @HiveField(14)
  DateTime cachedAt;

  @HiveField(15)
  Duration cacheDuration;

  // Product details caching fields
  @HiveField(16)
  List<Map<String, dynamic>>? reviews;

  @HiveField(17)
  int? totalReviews;

  @HiveField(18)
  double? averageRating;

  @HiveField(19)
  int? stockQuantity;

  @HiveField(20)
  bool? isAvailable;

  @HiveField(21)
  Map<String, dynamic>? specifications;

  @HiveField(22)
  List<String>? relatedProductIds;

  @HiveField(23)
  int? viewCount;

  @HiveField(24)
  int? purchaseCount;

  @HiveField(25)
  DateTime? lastUpdated;

  @HiveField(26)
  Map<String, dynamic>? metadata;

  @HiveField(27)
  bool? isFeatured;

  @HiveField(28)
  String? category;

  @HiveField(29)
  String? subcategory;

  @HiveField(30)
  List<String>? tags;

  CachedProduct({
    required this.id,
    this.images,
    this.title,
    this.variant,
    this.discountPrice,
    this.originalPrice,
    this.rating = 0.0,
    this.highlights,
    this.description,
    this.seller,
    this.owner,
    this.productType,
    this.searchTags,
    this.dateAdded,
    required this.cachedAt,
    this.cacheDuration = const Duration(hours: 24),
    // Product details fields
    this.reviews,
    this.totalReviews,
    this.averageRating,
    this.stockQuantity,
    this.isAvailable,
    this.specifications,
    this.relatedProductIds,
    this.viewCount,
    this.purchaseCount,
    this.lastUpdated,
    this.metadata,
    this.isFeatured,
    this.category,
    this.subcategory,
    this.tags,
  });

  factory CachedProduct.fromProduct(
    Product product, {
    Duration? cacheDuration,
    List<Map<String, dynamic>>? reviews,
    int? totalReviews,
    double? averageRating,
    int? stockQuantity,
    bool? isAvailable,
    Map<String, dynamic>? specifications,
    List<String>? relatedProductIds,
    int? viewCount,
    int? purchaseCount,
    Map<String, dynamic>? metadata,
    bool? isFeatured,
    String? category,
    String? subcategory,
    List<String>? tags,
  }) {
    return CachedProduct(
      id: product.id,
      images: product.images,
      title: product.title,
      variant: product.variant,
      discountPrice: product.discountPrice,
      originalPrice: product.originalPrice,
      rating: product.rating,
      highlights: product.highlights,
      description: product.description,
      seller: product.seller,
      owner: product.owner,
      productType: product.productType?.toString(),
      searchTags: product.searchTags,
      dateAdded: product.dateAdded,
      cachedAt: DateTime.now(),
      cacheDuration: cacheDuration ?? const Duration(hours: 24),
      // Product details
      reviews: reviews,
      totalReviews: totalReviews,
      averageRating: averageRating,
      stockQuantity: stockQuantity,
      isAvailable: isAvailable,
      specifications: specifications,
      relatedProductIds: relatedProductIds,
      viewCount: viewCount,
      purchaseCount: purchaseCount,
      lastUpdated: DateTime.now(),
      metadata: metadata,
      isFeatured: isFeatured,
      category: category,
      subcategory: subcategory,
      tags: tags,
    );
  }

  Product toProduct() {
    return Product(
      id,
      images: images,
      title: title,
      variant: variant,
      discountPrice: discountPrice,
      originalPrice: originalPrice,
      rating: rating,
      highlights: highlights,
      description: description,
      seller: seller,
      owner: owner,
      productType: productType != null
          ? ProductType.values.firstWhere(
              (type) => type.toString() == productType,
              orElse: () => ProductType.Others,
            )
          : null,
      searchTags: searchTags,
      dateAdded: dateAdded,
    );
  }

  bool get isExpired {
    return DateTime.now().difference(cachedAt) > cacheDuration;
  }

  void updateCacheTime() {
    cachedAt = DateTime.now();
    save();
  }

  // Product details caching methods
  void updateReviews(List<Map<String, dynamic>> newReviews) {
    reviews = newReviews;
    totalReviews = newReviews.length;
    if (newReviews.isNotEmpty) {
      final totalRating = newReviews.fold<double>(
        0.0,
        (sum, review) => sum + (review['rating'] as num).toDouble(),
      );
      averageRating = totalRating / newReviews.length;
    }
    lastUpdated = DateTime.now();
    save();
  }

  void updateStock(int quantity, {bool? available}) {
    stockQuantity = quantity;
    isAvailable = available ?? (quantity > 0);
    lastUpdated = DateTime.now();
    save();
  }

  void updateSpecifications(Map<String, dynamic> specs) {
    specifications = specs;
    lastUpdated = DateTime.now();
    save();
  }

  void updateRelatedProducts(List<String> productIds) {
    relatedProductIds = productIds;
    lastUpdated = DateTime.now();
    save();
  }

  void incrementViewCount() {
    viewCount = (viewCount ?? 0) + 1;
    lastUpdated = DateTime.now();
    save();
  }

  void incrementPurchaseCount() {
    purchaseCount = (purchaseCount ?? 0) + 1;
    lastUpdated = DateTime.now();
    save();
  }

  void updateMetadata(Map<String, dynamic> newMetadata) {
    metadata = {...(metadata ?? {}), ...newMetadata};
    lastUpdated = DateTime.now();
    save();
  }

  void updateCategoryInfo({String? cat, String? subcat}) {
    if (cat != null) category = cat;
    if (subcat != null) subcategory = subcat;
    lastUpdated = DateTime.now();
    save();
  }

  void updateTags(List<String> newTags) {
    tags = newTags;
    lastUpdated = DateTime.now();
    save();
  }

  void setFeatured(bool featured) {
    isFeatured = featured;
    lastUpdated = DateTime.now();
    save();
  }

  // Getters for product details
  bool get hasReviews => reviews != null && reviews!.isNotEmpty;
  bool get hasStock => stockQuantity != null && stockQuantity! > 0;
  bool get hasSpecifications =>
      specifications != null && specifications!.isNotEmpty;
  bool get hasRelatedProducts =>
      relatedProductIds != null && relatedProductIds!.isNotEmpty;
  bool get hasMetadata => metadata != null && metadata!.isNotEmpty;

  // Check if specific data is expired (for granular cache control)
  bool isReviewsExpired({Duration? customDuration}) {
    if (lastUpdated == null) return true;
    final expireDuration = customDuration ?? const Duration(hours: 6);
    return DateTime.now().difference(lastUpdated!) > expireDuration;
  }

  bool isStockExpired({Duration? customDuration}) {
    if (lastUpdated == null) return true;
    final expireDuration = customDuration ?? const Duration(minutes: 30);
    return DateTime.now().difference(lastUpdated!) > expireDuration;
  }

  // Get product details as a Map for easy access
  Map<String, dynamic> getProductDetails() {
    return {
      'reviews': reviews,
      'totalReviews': totalReviews,
      'averageRating': averageRating,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'specifications': specifications,
      'relatedProductIds': relatedProductIds,
      'viewCount': viewCount,
      'purchaseCount': purchaseCount,
      'lastUpdated': lastUpdated,
      'metadata': metadata,
      'isFeatured': isFeatured,
      'category': category,
      'subcategory': subcategory,
      'tags': tags,
    };
  }

  // Create a copy with updated product details
  CachedProduct copyWithDetails({
    List<Map<String, dynamic>>? reviews,
    int? totalReviews,
    double? averageRating,
    int? stockQuantity,
    bool? isAvailable,
    Map<String, dynamic>? specifications,
    List<String>? relatedProductIds,
    int? viewCount,
    int? purchaseCount,
    Map<String, dynamic>? metadata,
    bool? isFeatured,
    String? category,
    String? subcategory,
    List<String>? tags,
  }) {
    return CachedProduct(
      id: id,
      images: images,
      title: title,
      variant: variant,
      discountPrice: discountPrice,
      originalPrice: originalPrice,
      rating: rating,
      highlights: highlights,
      description: description,
      seller: seller,
      owner: owner,
      productType: productType,
      searchTags: searchTags,
      dateAdded: dateAdded,
      cachedAt: cachedAt,
      cacheDuration: cacheDuration,
      reviews: reviews ?? this.reviews,
      totalReviews: totalReviews ?? this.totalReviews,
      averageRating: averageRating ?? this.averageRating,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      specifications: specifications ?? this.specifications,
      relatedProductIds: relatedProductIds ?? this.relatedProductIds,
      viewCount: viewCount ?? this.viewCount,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      lastUpdated: DateTime.now(),
      metadata: metadata ?? this.metadata,
      isFeatured: isFeatured ?? this.isFeatured,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      tags: tags ?? this.tags,
    );
  }
}
