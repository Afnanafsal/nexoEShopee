import 'package:enum_to_string/enum_to_string.dart';
import 'package:fishkart/models/Model.dart';

enum ProductType { Freshwater, Saltwater, Shellfish, Exotic, Others, Dried }

class Product extends Model {
  int calculatePercentageDiscount() {
    if (originalPrice == null || discountPrice == null || originalPrice == 0) {
      return 0;
    }
    return (((originalPrice! - discountPrice!) * 100) / originalPrice!).round();
  }
  Product(
    String id, {
    this.images,
    this.title,
    this.variant,
    this.discountPrice,
    this.originalPrice,
    this.rating = 0,
    this.highlights,
    this.description,
    this.seller,
    this.owner,
    this.productType,
    this.searchTags,
    this.dateAdded,
    this.stock = 0,
  }) : super(id);
  static const String IMAGES_KEY = "images";
  static const String TITLE_KEY = "title";
  static const String VARIANT_KEY = "variant";
  static const String DISCOUNT_PRICE_KEY = "discount_price";
  static const String ORIGINAL_PRICE_KEY = "original_price";
  static const String RATING_KEY = "rating";
  static const String HIGHLIGHTS_KEY = "highlights";
  static const String DESCRIPTION_KEY = "description";
  static const String SELLER_KEY = "seller";
  static const String OWNER_KEY = "owner";
  static const String PRODUCT_TYPE_KEY = "product_type";
  static const String SEARCH_TAGS_KEY = "search_tags";
  static const String DATE_ADDED_KEY = "dateAdded";
  static const String STOCK_KEY = "stock";

  List<String>? images;
  String? title;
  String? variant;
  num? discountPrice;
  num? originalPrice;
  num rating;
  String? highlights;
  String? description;
  String? seller;
  String? owner;
  ProductType? productType;
  List<String>? searchTags;
  DateTime? dateAdded;
  int stock;
  factory Product.fromMap(Map<String, dynamic> map, {required String id}) {
    print('Raw Firestore stock value for product id $id: ${map[STOCK_KEY]}');
    int parsedStock = 0;
    if (map[STOCK_KEY] != null) {
      if (map[STOCK_KEY] is int) {
        parsedStock = map[STOCK_KEY];
      } else if (map[STOCK_KEY] is String) {
        parsedStock = int.tryParse(map[STOCK_KEY]) ?? 0;
      } else if (map[STOCK_KEY] is double) {
        parsedStock = (map[STOCK_KEY] as double).toInt();
      }
    }
    return Product(
      id,
      images: (map[IMAGES_KEY] as List<dynamic>?)?.cast<String>() ?? [],
      title: map[TITLE_KEY],
      variant: map[VARIANT_KEY],
      discountPrice: map[DISCOUNT_PRICE_KEY],
      originalPrice: map[ORIGINAL_PRICE_KEY],
      rating: map[RATING_KEY] ?? 0.0,
      highlights: map[HIGHLIGHTS_KEY],
      description: map[DESCRIPTION_KEY],
      seller: map[SELLER_KEY],
      owner: map[OWNER_KEY],
      productType: map[PRODUCT_TYPE_KEY] != null
          ? EnumToString.fromString(ProductType.values, map[PRODUCT_TYPE_KEY])
          : null,
      searchTags:
          (map[SEARCH_TAGS_KEY] as List<dynamic>?)?.cast<String>() ?? [],
      dateAdded: map[DATE_ADDED_KEY] != null
          ? DateTime.tryParse(map[DATE_ADDED_KEY])
          : null,
      stock: parsedStock,
    );
  }
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      IMAGES_KEY: images,
      TITLE_KEY: title,
      VARIANT_KEY: variant,
      DISCOUNT_PRICE_KEY: discountPrice,
      ORIGINAL_PRICE_KEY: originalPrice,
      RATING_KEY: rating,
      HIGHLIGHTS_KEY: highlights,
      DESCRIPTION_KEY: description,
      SELLER_KEY: seller,
      OWNER_KEY: owner,
      PRODUCT_TYPE_KEY: productType != null
          ? EnumToString.convertToString(productType)
          : null,
      SEARCH_TAGS_KEY: searchTags,
      DATE_ADDED_KEY: dateAdded?.toIso8601String(),
      STOCK_KEY: stock,
    };
    return map;
  }

  @override
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};

    if (images != null) map[IMAGES_KEY] = images;
    if (title != null) map[TITLE_KEY] = title;
    if (variant != null) map[VARIANT_KEY] = variant;
    if (discountPrice != null) map[DISCOUNT_PRICE_KEY] = discountPrice;
    if (originalPrice != null) map[ORIGINAL_PRICE_KEY] = originalPrice;
    map[RATING_KEY] = rating; // Always include rating
    if (highlights != null) map[HIGHLIGHTS_KEY] = highlights;
    if (description != null) map[DESCRIPTION_KEY] = description;
    if (seller != null) map[SELLER_KEY] = seller;
    if (owner != null) map[OWNER_KEY] = owner;
    if (productType != null) {
      map[PRODUCT_TYPE_KEY] = EnumToString.convertToString(productType);
    }
    if (searchTags != null) map[SEARCH_TAGS_KEY] = searchTags;
    if (dateAdded != null) map[DATE_ADDED_KEY] = dateAdded?.toIso8601String();
    map[STOCK_KEY] = stock;
    return map;
  }

  Product copyWith({
    String? id,
    List<String>? images,
    String? title,
    String? variant,
    num? discountPrice,
    num? originalPrice,
    num? rating,
    String? highlights,
    String? description,
    String? seller,
    String? owner,
    ProductType? productType,
    List<String>? searchTags,
    DateTime? dateAdded,
    int? stock,
  }) {
    return Product(
      id ?? this.id,
      images: images ?? this.images,
      title: title ?? this.title,
      variant: variant ?? this.variant,
      discountPrice: discountPrice ?? this.discountPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      highlights: highlights ?? this.highlights,
      description: description ?? this.description,
      seller: seller ?? this.seller,
      owner: owner ?? this.owner,
      productType: productType ?? this.productType,
      searchTags: searchTags ?? this.searchTags,
      dateAdded: dateAdded ?? this.dateAdded,
      stock: stock ?? this.stock,
    );
  }
}
