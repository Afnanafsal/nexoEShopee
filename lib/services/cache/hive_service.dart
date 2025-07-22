import 'package:hive_flutter/hive_flutter.dart';
import 'package:fishkart/models/cached_product.dart';
import 'package:fishkart/models/cached_user.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/services/cache/duration_adapter.dart';

class HiveService {
  // Cache a list of addresses (List<Map<String, dynamic>>) in Hive
  Future<void> cacheAddresses(List<Map<String, dynamic>> addresses) async {
    final Map<String, Map<String, dynamic>> addressesMap = {
      for (var address in addresses) address['id'] as String: address,
    };
    await _addressesBox?.putAll(addressesMap);
  }

  // Returns all cached addresses as a List<Map<String, dynamic>>
  List<Map<String, dynamic>> getCachedAddresses() {
    return (_addressesBox?.values.toList() ?? []).cast<Map<String, dynamic>>();
  }

  static const String _productsBoxName = 'products';
  static const String _usersBoxName = 'users';
  static const String _settingsBoxName = 'settings';
  static const String _categoriesBoxName = 'categories';
  static const String _ordersBoxName = 'orders';
  static const String _addressesBoxName = 'addresses';
  static const String _reviewsBoxName = 'reviews';

  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();
  HiveService._();

  Box<CachedProduct>? _productsBox;
  Box<CachedUser>? _usersBox;
  Box<dynamic>? _settingsBox;
  Box<List<String>>? _categoriesBox;
  Box<dynamic>? _ordersBox;
  Box<dynamic>? _addressesBox;
  Box<dynamic>? _reviewsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CachedProductAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CachedUserAdapter());
    }
    // Register DurationAdapter
    if (!Hive.isAdapterRegistered(99)) {
      Hive.registerAdapter(DurationAdapter());
    }

    _productsBox = await Hive.openBox<CachedProduct>(_productsBoxName);
    _usersBox = await Hive.openBox<CachedUser>(_usersBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _categoriesBox = await Hive.openBox<List<String>>(_categoriesBoxName);
    _ordersBox = await Hive.openBox(_ordersBoxName);
    _addressesBox = await Hive.openBox(_addressesBoxName);
    _reviewsBox = await Hive.openBox(_reviewsBoxName);
    // Orders caching
    Future<void> cacheOrder(
      String orderId,
      Map<String, dynamic> orderData,
    ) async {
      await _ordersBox?.put(orderId, orderData);
    }

    Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
      final Map<String, Map<String, dynamic>> ordersMap = {
        for (var order in orders) order['id'] as String: order,
      };
      await _ordersBox?.putAll(ordersMap);
    }

    Map<String, dynamic>? getCachedOrder(String orderId) {
      return _ordersBox?.get(orderId) as Map<String, dynamic>?;
    }

    List<Map<String, dynamic>> getCachedOrders() {
      return (_ordersBox?.values.toList() ?? []).cast<Map<String, dynamic>>();
    }

    Future<void> clearOrderCache() async {
      await _ordersBox?.clear();
    }

    // Addresses caching
    Future<void> cacheAddress(
      String addressId,
      Map<String, dynamic> addressData,
    ) async {
      await _addressesBox?.put(addressId, addressData);
    }

    Future<void> cacheAddresses(List<Map<String, dynamic>> addresses) async {
      final Map<String, Map<String, dynamic>> addressesMap = {
        for (var address in addresses) address['id'] as String: address,
      };
      await _addressesBox?.putAll(addressesMap);
    }

    Map<String, dynamic>? getCachedAddress(String addressId) {
      return _addressesBox?.get(addressId) as Map<String, dynamic>?;
    }

    List<Map<String, dynamic>> getCachedAddresses() {
      return (_addressesBox?.values.toList() ?? [])
          .cast<Map<String, dynamic>>();
    }

    Future<void> clearAddressCache() async {
      await _addressesBox?.clear();
    }

    // Reviews caching
    Future<void> cacheReview(
      String reviewId,
      Map<String, dynamic> reviewData,
    ) async {
      await _reviewsBox?.put(reviewId, reviewData);
    }

    Future<void> cacheReviews(List<Map<String, dynamic>> reviews) async {
      final Map<String, Map<String, dynamic>> reviewsMap = {
        for (var review in reviews) review['id'] as String: review,
      };
      await _reviewsBox?.putAll(reviewsMap);
    }

    Map<String, dynamic>? getCachedReview(String reviewId) {
      return _reviewsBox?.get(reviewId) as Map<String, dynamic>?;
    }

    List<Map<String, dynamic>> getCachedReviews() {
      return (_reviewsBox?.values.toList() ?? []).cast<Map<String, dynamic>>();
    }

    Future<void> clearReviewCache() async {
      await _reviewsBox?.clear();
    }
  }

  Future<void> cacheProduct(Product product) async {
    final cachedProduct = CachedProduct.fromProduct(product);
    await _productsBox?.put(product.id, cachedProduct);
  }

  Future<void> cacheProducts(List<Product> products) async {
    final Map<String, CachedProduct> productsMap = {};
    for (final product in products) {
      productsMap[product.id] = CachedProduct.fromProduct(product);
    }
    await _productsBox?.putAll(productsMap);
  }

  Product? getCachedProduct(String productId) {
    final cachedProduct = _productsBox?.get(productId);
    if (cachedProduct != null && !cachedProduct.isExpired) {
      return cachedProduct.toProduct();
    }
    return null;
  }

  List<Product> getCachedProducts() {
    final cachedProducts = _productsBox?.values.toList() ?? [];
    return cachedProducts
        .where((product) => !product.isExpired)
        .map((product) => product.toProduct())
        .toList();
  }

  List<Product> getCachedProductsByType(ProductType type) {
    final cachedProducts = _productsBox?.values.toList() ?? [];
    return cachedProducts
        .where(
          (product) =>
              !product.isExpired && product.productType == type.toString(),
        )
        .map((product) => product.toProduct())
        .toList();
  }

  Future<void> removeCachedProduct(String productId) async {
    await _productsBox?.delete(productId);
  }

  Future<void> clearExpiredProducts() async {
    final expiredKeys = <String>[];
    for (final entry
        in _productsBox?.toMap().entries ??
            <MapEntry<dynamic, CachedProduct>>[]) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key.toString());
      }
    }
    await _productsBox?.deleteAll(expiredKeys);
  }

  Future<void> cacheUser(String userId, CachedUser user) async {
    await _usersBox?.put(userId, user);
  }

  CachedUser? getCachedUser(String userId) {
    final cachedUser = _usersBox?.get(userId);
    if (cachedUser != null && !cachedUser.isExpired) {
      return cachedUser;
    }
    return null;
  }

  Future<void> updateUserFavorites(
    String userId,
    List<String> favorites,
  ) async {
    final cachedUser = getCachedUser(userId);
    if (cachedUser != null) {
      cachedUser.favoriteProducts = favorites;
      cachedUser.cachedAt = DateTime.now();
      await _usersBox?.put(userId, cachedUser);
    }
  }

  Future<void> updateUserCart(String userId, List<String> cartItems) async {
    final cachedUser = getCachedUser(userId);
    if (cachedUser != null) {
      cachedUser.cartItems = cartItems;
      cachedUser.cachedAt = DateTime.now();
      await _usersBox?.put(userId, cachedUser);
    }
  }

  Future<void> cacheProductsByCategory(
    String category,
    List<String> productIds,
  ) async {
    await _categoriesBox?.put(category, productIds);
  }

  List<String>? getCachedProductsByCategory(String category) {
    return _categoriesBox?.get(category);
  }

  Future<void> cacheSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }

  T? getCachedSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox?.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> cacheUserPreferences(Map<String, dynamic> preferences) async {
    await _settingsBox?.put('user_preferences', preferences);
  }

  Map<String, dynamic>? getCachedUserPreferences() {
    return _settingsBox?.get('user_preferences') as Map<String, dynamic>?;
  }

  Future<void> cacheSearchResults(String query, List<String> productIds) async {
    final searchKey = 'search_${query.toLowerCase()}';
    await _settingsBox?.put(searchKey, {
      'results': productIds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  List<String>? getCachedSearchResults(String query) {
    final searchKey = 'search_${query.toLowerCase()}';
    final data = _settingsBox?.get(searchKey) as Map<String, dynamic>?;

    if (data != null) {
      final timestamp = data['timestamp'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      if (DateTime.now().difference(cachedTime).inMinutes <= 15) {
        return List<String>.from(data['results'] as List);
      }
    }
    return null;
  }

  Future<void> cacheProductWithDetails(
    Product product, {
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
    Duration? cacheDuration,
  }) async {
    final cachedProduct = CachedProduct.fromProduct(
      product,
      reviews: reviews,
      totalReviews: totalReviews,
      averageRating: averageRating,
      stockQuantity: stockQuantity,
      isAvailable: isAvailable,
      specifications: specifications,
      relatedProductIds: relatedProductIds,
      viewCount: viewCount,
      purchaseCount: purchaseCount,
      metadata: metadata,
      isFeatured: isFeatured,
      category: category,
      subcategory: subcategory,
      tags: tags,
      cacheDuration: cacheDuration,
    );
    await _productsBox?.put(product.id, cachedProduct);
  }

  Future<void> updateProductReviews(
    String productId,
    List<Map<String, dynamic>> reviews,
  ) async {
    final cachedProduct = _productsBox?.get(productId);
    if (cachedProduct != null) {
      cachedProduct.updateReviews(reviews);
    }
  }

  Future<void> updateProductStock(
    String productId,
    int quantity, {
    bool? available,
  }) async {
    final cachedProduct = _productsBox?.get(productId);
    if (cachedProduct != null) {
      cachedProduct.updateStock(quantity, available: available);
    }
  }

  Future<void> updateProductSpecifications(
    String productId,
    Map<String, dynamic> specifications,
  ) async {
    final cachedProduct = _productsBox?.get(productId);
    if (cachedProduct != null) {
      cachedProduct.updateSpecifications(specifications);
    }
  }

  Future<void> updateProductMetadata(
    String productId,
    Map<String, dynamic> metadata,
  ) async {
    final cachedProduct = _productsBox?.get(productId);
    if (cachedProduct != null) {
      cachedProduct.updateMetadata(metadata);
    }
  }

  Future<void> incrementProductViewCount(String productId) async {
    final cachedProduct = _productsBox?.get(productId);
    if (cachedProduct != null) {
      cachedProduct.incrementViewCount();
    }
  }

  Future<void> incrementProductPurchaseCount(String productId) async {
    final cachedProduct = _productsBox?.get(productId);
    if (cachedProduct != null) {
      cachedProduct.incrementPurchaseCount();
    }
  }

  Future<void> setProductFeatured(String productId, bool featured) async {
    final cachedProduct = _productsBox?.get(productId);
    if (cachedProduct != null) {
      cachedProduct.setFeatured(featured);
    }
  }

  CachedProduct? getCachedProductWithDetails(String productId) {
    final cachedProduct = _productsBox?.get(productId);
    if (cachedProduct != null && !cachedProduct.isExpired) {
      return cachedProduct;
    }
    return null;
  }

  Map<String, dynamic>? getCachedProductDetails(String productId) {
    final cachedProduct = _productsBox?.get(productId);
    if (cachedProduct != null && !cachedProduct.isExpired) {
      return cachedProduct.getProductDetails();
    }
    return null;
  }

  List<Product> getCachedProductsWithStock() {
    final cachedProducts = _productsBox?.values.toList() ?? [];
    return cachedProducts
        .where((product) => !product.isExpired && product.hasStock)
        .map((product) => product.toProduct())
        .toList();
  }

  List<Product> getCachedFeaturedProducts() {
    final cachedProducts = _productsBox?.values.toList() ?? [];
    return cachedProducts
        .where((product) => !product.isExpired && product.isFeatured == true)
        .map((product) => product.toProduct())
        .toList();
  }

  List<Product> getCachedProductsByCategoryName(String category) {
    final cachedProducts = _productsBox?.values.toList() ?? [];
    return cachedProducts
        .where((product) => !product.isExpired && product.category == category)
        .map((product) => product.toProduct())
        .toList();
  }

  List<Product> getCachedProductsWithReviews() {
    final cachedProducts = _productsBox?.values.toList() ?? [];
    return cachedProducts
        .where((product) => !product.isExpired && product.hasReviews)
        .map((product) => product.toProduct())
        .toList();
  }

  List<Product> getCachedProductsByPopularity({int? limit}) {
    final cachedProducts = _productsBox?.values.toList() ?? [];
    final popularProducts = cachedProducts
        .where((product) => !product.isExpired)
        .toList();

    popularProducts.sort((a, b) {
      final aScore = (a.viewCount ?? 0) + (a.purchaseCount ?? 0) * 2;
      final bScore = (b.viewCount ?? 0) + (b.purchaseCount ?? 0) * 2;
      return bScore.compareTo(aScore);
    });

    final products = popularProducts
        .map((product) => product.toProduct())
        .toList();
    return limit != null ? products.take(limit).toList() : products;
  }

  bool isProductStockExpired(String productId) {
    final cachedProduct = _productsBox?.get(productId);
    return cachedProduct?.isStockExpired() ?? true;
  }

  bool isProductReviewsExpired(String productId) {
    final cachedProduct = _productsBox?.get(productId);
    return cachedProduct?.isReviewsExpired() ?? true;
  }

  Future<void> clearExpiredProductDetails() async {
    final productsToUpdate = <String, CachedProduct>{};

    for (final entry
        in _productsBox?.toMap().entries ??
            <MapEntry<dynamic, CachedProduct>>[]) {
      final product = entry.value;
      if (product.isStockExpired() || product.isReviewsExpired()) {
        final updatedProduct = product.copyWithDetails(
          reviews: product.isReviewsExpired() ? null : product.reviews,
          totalReviews: product.isReviewsExpired()
              ? null
              : product.totalReviews,
          averageRating: product.isReviewsExpired()
              ? null
              : product.averageRating,
          stockQuantity: product.isStockExpired()
              ? null
              : product.stockQuantity,
          isAvailable: product.isStockExpired() ? null : product.isAvailable,
        );
        productsToUpdate[entry.key.toString()] = updatedProduct;
      }
    }

    if (productsToUpdate.isNotEmpty) {
      await _productsBox?.putAll(productsToUpdate);
    }
  }

  Future<void> clearAllCache() async {
    await _productsBox?.clear();
    await _usersBox?.clear();
    await _settingsBox?.clear();
    await _categoriesBox?.clear();
  }

  Future<void> clearProductCache() async {
    await _productsBox?.clear();
  }

  Future<void> clearUserCache() async {
    await _usersBox?.clear();
  }

  int getCachedProductsCount() {
    return _productsBox?.length ?? 0;
  }

  int getCachedUsersCount() {
    return _usersBox?.length ?? 0;
  }

  Future<void> cleanupExpiredData() async {
    await clearExpiredProducts();
  }

  Future<void> close() async {
    await _productsBox?.close();
    await _usersBox?.close();
    await _settingsBox?.close();
    await _categoriesBox?.close();
  }
}
