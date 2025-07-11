import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/services/cache/hive_service.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/models/cached_user.dart';

// Hive Service Provider
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService.instance;
});

// Cache Providers
final productCacheProvider = Provider<ProductCacheService>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ProductCacheService(hiveService);
});

final userCacheProvider = Provider<UserCacheService>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return UserCacheService(hiveService);
});

final searchCacheProvider = Provider<SearchCacheService>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return SearchCacheService(hiveService);
});

// Product Cache Service
class ProductCacheService {
  final HiveService _hiveService;

  ProductCacheService(this._hiveService);

  Future<void> cacheProduct(Product product) async {
    await _hiveService.cacheProduct(product);
  }

  Future<void> cacheProducts(List<Product> products) async {
    await _hiveService.cacheProducts(products);
  }

  Product? getCachedProduct(String productId) {
    return _hiveService.getCachedProduct(productId);
  }

  List<Product> getCachedProducts() {
    return _hiveService.getCachedProducts();
  }

  List<Product> getCachedProductsByType(ProductType type) {
    return _hiveService.getCachedProductsByType(type);
  }

  Future<void> removeCachedProduct(String productId) async {
    await _hiveService.removeCachedProduct(productId);
  }

  Future<void> clearExpiredProducts() async {
    await _hiveService.clearExpiredProducts();
  }
}

// User Cache Service
class UserCacheService {
  final HiveService _hiveService;

  UserCacheService(this._hiveService);

  Future<void> cacheUser(String userId, CachedUser user) async {
    await _hiveService.cacheUser(userId, user);
  }

  CachedUser? getCachedUser(String userId) {
    return _hiveService.getCachedUser(userId);
  }

  Future<void> updateUserFavorites(
    String userId,
    List<String> favorites,
  ) async {
    await _hiveService.updateUserFavorites(userId, favorites);
  }

  Future<void> updateUserCart(String userId, List<String> cartItems) async {
    await _hiveService.updateUserCart(userId, cartItems);
  }

  Future<void> cacheUserPreferences(Map<String, dynamic> preferences) async {
    await _hiveService.cacheUserPreferences(preferences);
  }

  Map<String, dynamic>? getCachedUserPreferences() {
    return _hiveService.getCachedUserPreferences();
  }
}

// Search Cache Service
class SearchCacheService {
  final HiveService _hiveService;

  SearchCacheService(this._hiveService);

  Future<void> cacheSearchResults(String query, List<String> productIds) async {
    await _hiveService.cacheSearchResults(query, productIds);
  }

  List<String>? getCachedSearchResults(String query) {
    return _hiveService.getCachedSearchResults(query);
  }

  Future<void> cacheProductsByCategory(
    String category,
    List<String> productIds,
  ) async {
    await _hiveService.cacheProductsByCategory(category, productIds);
  }

  List<String>? getCachedProductsByCategory(String category) {
    return _hiveService.getCachedProductsByCategory(category);
  }
}

// Cache Statistics Provider
final cacheStatsProvider = Provider<CacheStats>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return CacheStats(
    cachedProductsCount: hiveService.getCachedProductsCount(),
    cachedUsersCount: hiveService.getCachedUsersCount(),
  );
});

class CacheStats {
  final int cachedProductsCount;
  final int cachedUsersCount;

  CacheStats({
    required this.cachedProductsCount,
    required this.cachedUsersCount,
  });
}

// Cache Management Provider
final cacheManagementProvider = Provider<CacheManagement>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return CacheManagement(hiveService);
});

class CacheManagement {
  final HiveService _hiveService;

  CacheManagement(this._hiveService);

  Future<void> clearAllCache() async {
    await _hiveService.clearAllCache();
  }

  Future<void> clearProductCache() async {
    await _hiveService.clearProductCache();
  }

  Future<void> clearUserCache() async {
    await _hiveService.clearUserCache();
  }

  Future<void> cleanupExpiredData() async {
    await _hiveService.cleanupExpiredData();
  }

  Future<void> cacheSetting(String key, dynamic value) async {
    await _hiveService.cacheSetting(key, value);
  }

  T? getCachedSetting<T>(String key, {T? defaultValue}) {
    return _hiveService.getCachedSetting<T>(key, defaultValue: defaultValue);
  }
}
