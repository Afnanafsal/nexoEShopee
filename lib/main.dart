import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexoeshopee/app.dart';
import 'package:nexoeshopee/services/cache/hive_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.instance.init();

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

  // Preload and cache favourite products
  final favs = await userHelper.usersFavouriteProductsList;
  await HiveService.instance.updateUserFavorites(userId, favs);

  // Preload and cache ordered products (full order data)
  final ordersSnapshot = await userHelper.firestore
      .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
      .doc(userId)
      .collection(UserDatabaseHelper.ORDERED_PRODUCTS_COLLECTION_NAME)
      .get();
  if (ordersSnapshot.docs.isNotEmpty) {
    await Hive.box<dynamic>('orders').putAll({
      for (var doc in ordersSnapshot.docs)
        doc.id: {'id': doc.id, 'userId': userId, ...doc.data()},
    });
  }

  // You can add more preloads here (addresses, reviews, etc.)
}
