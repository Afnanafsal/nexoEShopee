import 'package:hive_flutter/hive_flutter.dart';
import 'package:fishkart/models/cached_product.dart';
import 'package:fishkart/models/cached_user.dart';

class LegacyHiveService {
  /// Removes all unwanted files/keys from all Hive boxes, keeping only essential data.
  static Future<void> removeUnwantedFiles() async {
    // User box: keep only 'profile_picture' and essential user keys
    final userBox = Hive.box(_userBox);
    final userKeysToKeep = [
      'profile_picture',
      'user_id',
      'email',
    ]; // add more if needed
    for (var key in userBox.keys) {
      if (!userKeysToKeep.contains(key)) {
        await userBox.delete(key);
      }
    }

    // Settings box: keep only essential settings
    final settingsBox = Hive.box(_settingsBox);
    final settingsKeysToKeep = ['theme', 'language']; // add more if needed
    for (var key in settingsBox.keys) {
      if (!settingsKeysToKeep.contains(key)) {
        await settingsBox.delete(key);
      }
    }

    // Cache box: clear all except essential cache keys
    final cacheBox = Hive.box(_cacheBox);
    final cacheKeysToKeep = []; // add essential cache keys if any
    for (var key in cacheBox.keys) {
      if (!cacheKeysToKeep.contains(key)) {
        await cacheBox.delete(key);
      }
    }

    // Favorite box: keep only 'favorites' key
    final favoriteBox = Hive.box(_favoriteBox);
    for (var key in favoriteBox.keys) {
      if (key != 'favorites') {
        await favoriteBox.delete(key);
      }
    }

    // Product box: keep only valid product objects
    final productBox = Hive.box<CachedProduct>(_productBox);
    for (var key in productBox.keys) {
      final product = productBox.get(key);
      if (product == null) {
        await productBox.delete(key);
      }
    }
  }

  static const String _userBox = 'user_box';
  static const String _settingsBox = 'settings_box';
  static const String _cacheBox = 'cache_box';
  static const String _favoriteBox = 'favorite_box';
  static const String _productBox = 'product_box';

  // Register adapters
  static Future<void> registerAdapters() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CachedProductAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CachedUserAdapter());
    }
  }

  // Initialize all boxes
  static Future<void> initializeBoxes() async {
    await registerAdapters();
    await Hive.openBox(_userBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_favoriteBox);
    await Hive.openBox<CachedProduct>(_productBox);
  }

  // User Box Methods
  static Box get userBox => Hive.box(_userBox);

  static Future<void> saveUserData(String key, dynamic value) async {
    await userBox.put(key, value);
  }

  static dynamic getUserData(String key) {
    return userBox.get(key);
  }

  static Future<void> deleteUserData(String key) async {
    await userBox.delete(key);
  }

  static Future<void> clearUserData() async {
    await userBox.clear();
  }

  // Settings Box Methods
  static Box get settingsBox => Hive.box(_settingsBox);

  static Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue);
  }

  static Future<void> deleteSetting(String key) async {
    await settingsBox.delete(key);
  }

  // Cache Box Methods
  static Box get cacheBox => Hive.box(_cacheBox);
  static Future<void> saveCache(String key, dynamic value) async {
    await cacheBox.put(key, value);
  }

  static dynamic getCache(String key, {dynamic defaultValue}) {
    return cacheBox.get(key, defaultValue: defaultValue);
  }

  static Future<void> clearAllCacheExcept(List<String> keysToKeep) async {
    for (var key in cacheBox.keys) {
      if (!keysToKeep.contains(key)) {
        await cacheBox.delete(key);
      }
    }
  }

  // Favorite Box Methods
  static Box get favoriteBox => Hive.box(_favoriteBox);

  static Future<void> addToFavorites(String productId) async {
    List<String> favorites = getFavorites();
    if (!favorites.contains(productId)) {
      favorites.add(productId);
      await favoriteBox.put('favorites', favorites);
    }
  }

  static Future<void> removeFromFavorites(String productId) async {
    List<String> favorites = getFavorites();
    favorites.remove(productId);
    await favoriteBox.put('favorites', favorites);
  }

  static List<String> getFavorites() {
    final favs = favoriteBox.get('favorites');
    if (favs is List<String>) {
      return favs;
    } else if (favs is List) {
      return favs.map((e) => e.toString()).toList();
    } else {
      return [];
    }
  }

  static Future<void> setFavorites(List<String> favorites) async {
    await favoriteBox.put('favorites', favorites);
  }

  static Future<void> clearFavorites() async {
    await favoriteBox.put('favorites', <String>[]);
  }

  // Product Box Methods
  static Box<CachedProduct> get productBox =>
      Hive.box<CachedProduct>(_productBox);

  static Future<void> saveProduct(CachedProduct product) async {
    await productBox.put(product.id, product);
  }

  static CachedProduct? getProduct(String productId) {
    return productBox.get(productId);
  }

  static List<CachedProduct> getAllProducts() {
    return productBox.values.toList();
  }

  static Future<void> deleteProduct(String productId) async {
    await productBox.delete(productId);
  }

  static Future<void> clearProducts() async {
    await productBox.clear();
  }

  // Close all boxes
  static Future<void> closeBoxes() async {
    await userBox.close();
    await settingsBox.close();
    await cacheBox.close();
    await favoriteBox.close();
    await productBox.close();
  }
}
