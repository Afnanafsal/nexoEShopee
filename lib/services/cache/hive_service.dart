import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexoeshopee/models/cached_product.dart';
import 'package:nexoeshopee/models/cached_user.dart';
import 'package:nexoeshopee/models/Product.dart';

class HiveService {
  static const String _productsBoxName = 'products';
  static const String _usersBoxName = 'users';
  static const String _settingsBoxName = 'settings';
  static const String _categoriesBoxName = 'categories';

  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();
  HiveService._();

  Box<CachedProduct>? _productsBox;
  Box<CachedUser>? _usersBox;
  Box<dynamic>? _settingsBox;
  Box<List<String>>? _categoriesBox;

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CachedProductAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CachedUserAdapter());
    }

    _productsBox = await Hive.openBox<CachedProduct>(_productsBoxName);
    _usersBox = await Hive.openBox<CachedUser>(_usersBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _categoriesBox = await Hive.openBox<List<String>>(_categoriesBoxName);
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
