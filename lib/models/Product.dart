import 'package:enum_to_string/enum_to_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fishkart/models/Model.dart';

enum ProductType { Freshwater, Saltwater, Shellfish, Exotic, Others, Dried }

class Product extends Model {
  // Helper: Is product in stock?
  bool get isInStock => stock > 0;
  // Helper: Is product available?
  bool get isAvailable => _isAvailable ?? true;
  final bool? _isAvailable;

  // Helper: Check if all products in cart have enough stock
  static Future<bool> cartHasSufficientStock(Map<String, int> cart) async {
    // cart: {productId: qty}
    final firestore = FirebaseFirestore.instance;
    for (final entry in cart.entries) {
      final doc = await firestore.collection('products').doc(entry.key).get();
      final data = doc.data();
      if (data == null || (data['stock'] ?? 0) < entry.value) {
        return false;
      }
    }
    return true;
  }

  // Helper: Fast checkout dialog
  static Future<void> showFastCheckoutDialog(
    BuildContext context, {
    required VoidCallback onProceed,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Proceed to Checkout'),
        content: const Text('Are you sure you want to checkout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onProceed();
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  // --- Firestore stock management methods ---
  /// Restore stock when an item is removed from cart (undo reservation)
  static Future<void> restoreStockFromCart(String productId, int qty) async {
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId);
    print('[restoreStockFromCart] productId: $productId, qty: $qty');
    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(productRef);
          final data = snapshot.data();
          print('[restoreStockFromCart] Firestore data: $data');
          if (data == null) throw Exception('Product not found');
          final currentStock = (data['stock'] ?? 0) as int;
          final reserved = (data['reserved'] ?? 0) as int;
          print(
            '[restoreStockFromCart] Before update: stock=$currentStock, reserved=$reserved',
          );
          int newStock = currentStock + qty;
          int newReserved = reserved - qty;
          if (newReserved < 0) {
            print(
              '[restoreStockFromCart] Warning: reserved would go negative, setting to 0',
            );
            newReserved = 0;
          }
          transaction.update(productRef, {
            'stock': newStock,
            'reserved': newReserved,
          });
          print(
            '[restoreStockFromCart] After update: stock=$newStock, reserved=$newReserved',
          );
        })
        .catchError((e) {
          print('[restoreStockFromCart] Error: $e');
          throw e;
        });
  }

  static Future<void> reserveStock(String productId, int qty) async {
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId);
    print('[reserveStock] productId: $productId, qty: $qty');
    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(productRef);
          final data = snapshot.data();
          print('[reserveStock] Firestore data: $data');
          if (data == null) throw Exception('Product not found');
          final currentStock = (data['stock'] ?? 0) as int;
          final reserved = (data['reserved'] ?? 0) as int;
          if (currentStock < qty) {
            print('[reserveStock] Not enough stock: $currentStock < $qty');
            throw Exception('Not enough stock');
          }
          transaction.update(productRef, {
            'stock': currentStock - qty,
            'reserved': reserved + qty,
          });
          print(
            '[reserveStock] Updated stock: ${currentStock - qty}, reserved: ${reserved + qty}',
          );
        })
        .catchError((e) {
          print('[reserveStock] Error: $e');
          throw e;
        });
  }

  static Future<void> unreserveStock(String productId, int qty) async {
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId);
    print('[unreserveStock] productId: $productId, qty: $qty');
    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(productRef);
          final data = snapshot.data();
          print('[unreserveStock] Firestore data: $data');
          if (data == null) throw Exception('Product not found');
          final reserved = (data['reserved'] ?? 0) as int;
          transaction.update(productRef, {'reserved': reserved - qty});
          print('[unreserveStock] Updated reserved: ${reserved - qty}');
        })
        .catchError((e) {
          print('[unreserveStock] Error: $e');
          throw e;
        });
  }

  static Future<void> orderStock(String productId, int qty) async {
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId);
    print('[orderStock] productId: $productId, qty: $qty');
    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(productRef);
          final data = snapshot.data();
          print('[orderStock] Firestore data: $data');
          if (data == null) throw Exception('Product not found');
          final reserved = (data['reserved'] ?? 0) as int;
          final ordered = (data['ordered'] ?? 0) as int;
          if (reserved < qty) {
            print('[orderStock] Not enough reserved stock: $reserved < $qty');
            throw Exception('Not enough reserved stock');
          }
          transaction.update(productRef, {
            'reserved': reserved - qty,
            'ordered': ordered + qty,
          });
          print(
            '[orderStock] Updated reserved: ${reserved - qty}, ordered: ${ordered + qty}',
          );
        })
        .catchError((e) {
          print('[orderStock] Error: $e');
          throw e;
        });
  }

  static Future<void> completeOrderStock(String productId, int qty) async {
    final productRef = FirebaseFirestore.instance
        .collection('products')
        .doc(productId);
    print('[completeOrderStock] productId: $productId, qty: $qty');
    await FirebaseFirestore.instance
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(productRef);
          final data = snapshot.data();
          print('[completeOrderStock] Firestore data: $data');
          if (data == null) throw Exception('Product not found');
          final ordered = (data['ordered'] ?? 0) as int;
          transaction.update(productRef, {'ordered': ordered - qty});
          print('[completeOrderStock] Updated ordered: ${ordered - qty}');
        })
        .catchError((e) {
          print('[completeOrderStock] Error: $e');
          throw e;
        });
  }

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
    this.vendorId,
    this.userId,
    this.productType,
    this.searchTags,
    this.dateAdded,
    this.stock = 0,
    this.areaLocation,
    bool? isAvailable,
  }) : _isAvailable = isAvailable,
       super(id);
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
  String? vendorId;
  String? userId;
  ProductType? productType;
  List<String>? searchTags;
  DateTime? dateAdded;
  int stock;
  String? areaLocation;
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
      vendorId: map['vendorId'],
      userId: map['userId'],
      productType: map[PRODUCT_TYPE_KEY] != null
          ? EnumToString.fromString(ProductType.values, map[PRODUCT_TYPE_KEY])
          : null,
      searchTags:
          (map[SEARCH_TAGS_KEY] as List<dynamic>?)?.cast<String>() ?? [],
      dateAdded: map[DATE_ADDED_KEY] != null
          ? DateTime.tryParse(map[DATE_ADDED_KEY])
          : null,
      stock: parsedStock,
      areaLocation: map['areaLocation'],
      isAvailable: map['isAvailable'] is bool ? map['isAvailable'] : true,
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
      'areaLocation': areaLocation,
      'isAvailable': isAvailable,
      'vendorId': vendorId,
      'userId': userId,
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
    String? vendorId,
    String? userId,
    ProductType? productType,
    List<String>? searchTags,
    DateTime? dateAdded,
    int? stock,
    String? areaLocation,
    bool? isAvailable,
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
      vendorId: vendorId ?? this.vendorId,
      userId: userId ?? this.userId,
      productType: productType ?? this.productType,
      searchTags: searchTags ?? this.searchTags,
      dateAdded: dateAdded ?? this.dateAdded,
      stock: stock ?? this.stock,
      areaLocation: areaLocation ?? this.areaLocation,
      isAvailable: isAvailable ?? _isAvailable,
    );
  }
}
