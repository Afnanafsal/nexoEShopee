import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fishkart/app.dart';
import 'package:fishkart/services/cache/hive_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.instance.init();

  // Clear product cache at startup for fresh Firestore fetch
  await HiveService.instance.clearProductCache();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print('Firebase already initialized: $e');
  }

  // Preload and cache essential data before showing the main UI
  await preloadAndCacheEssentialData();

  runApp(ProviderScope(child: App()));
}

Future<void> preloadAndCacheEssentialData() async {
  // Get current user
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final userId = user.uid;
  final userHelper = UserDatabaseHelper();

  // Preload and cache cart items
  final cartItems = await userHelper.allCartItemsList;
  await HiveService.instance.updateUserCart(userId, cartItems);

  // Preload and cache favourite products (IDs and full product data)
  final favs = await userHelper.usersFavouriteProductsList;
  await HiveService.instance.updateUserFavorites(userId, favs);
  if (favs.isNotEmpty) {
    final favProducts = await Future.wait(
      favs.map((id) => ProductDatabaseHelper().getProductWithID(id)),
    );
    for (final product in favProducts) {
      if (product != null) {
        await HiveService.instance.cacheProduct(product);
      }
    }
  }

  // Preload and cache all orders and their products for instant access
  final ordersSnapshot = await userHelper.firestore
      .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
      .doc(userId)
      .collection(UserDatabaseHelper.ORDERED_PRODUCTS_COLLECTION_NAME)
      .get();
  if (ordersSnapshot.docs.isNotEmpty) {
    // Store all orders in Hive
    await Hive.box<dynamic>('orders').putAll({
      for (var doc in ordersSnapshot.docs)
        doc.id: {'id': doc.id, 'userId': userId, ...doc.data()},
    });

    // Collect all unique product IDs from orders
    final orderedProductIds = ordersSnapshot.docs
        .map((doc) => doc.data()['product_uid'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();

    // Fetch and cache all ordered products for instant access
    if (orderedProductIds.isNotEmpty) {
      final orderedProducts = await Future.wait(
        orderedProductIds.map(
          (id) => ProductDatabaseHelper().getProductWithID(id),
        ),
      );
      for (final product in orderedProducts) {
        if (product != null) {
          await HiveService.instance.cacheProduct(product);
        }
      }
    }
  }

  // Preload and cache addresses
  final addressesSnapshot = await userHelper.firestore
      .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
      .doc(userId)
      .collection(UserDatabaseHelper.ADDRESSES_COLLECTION_NAME)
      .get();
  if (addressesSnapshot.docs.isNotEmpty) {
    final addressList = addressesSnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
    await HiveService.instance.cacheAddresses(addressList);
  }
  // You can add more preloads here (reviews, etc.)
}
