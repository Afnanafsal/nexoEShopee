import 'package:enum_to_string/enum_to_string.dart';
import 'package:nexoeshopee/models/Model.dart';

enum ProductType {
  Electronics,
  Books,
  Fashion,
  Groceries,
  Art,
  Others,
}

class Product extends Model {
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

  Product(
    String id, {
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
  }) : super(id);

  int calculatePercentageDiscount() {
    if (originalPrice == null || discountPrice == null || originalPrice == 0) {
      return 0;
    }
    return (((originalPrice! - discountPrice!) * 100) / originalPrice!).round();
  }

  factory Product.fromMap(Map<String, dynamic> map, {required String id}) {
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
      productType:
          EnumToString.fromString(ProductType.values, map[PRODUCT_TYPE_KEY]),
      searchTags: (map[SEARCH_TAGS_KEY] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      IMAGES_KEY: images,
      TITLE_KEY: title,
      VARIANT_KEY: variant,
      PRODUCT_TYPE_KEY: EnumToString.convertToString(productType),
      DISCOUNT_PRICE_KEY: discountPrice,
      ORIGINAL_PRICE_KEY: originalPrice,
      RATING_KEY: rating,
      HIGHLIGHTS_KEY: highlights,
      DESCRIPTION_KEY: description,
      SELLER_KEY: seller,
      OWNER_KEY: owner,
      SEARCH_TAGS_KEY: searchTags,
    };
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
    if (productType != null) {
      map[PRODUCT_TYPE_KEY] = EnumToString.convertToString(productType);
    }
    if (owner != null) map[OWNER_KEY] = owner;
    if (searchTags != null) map[SEARCH_TAGS_KEY] = searchTags;

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
    );
  }
}
