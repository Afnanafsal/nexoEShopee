import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/models/Review.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/services/cache/hive_service.dart';
import 'package:hive/hive.dart';

final productDatabaseHelperProvider = Provider<ProductDatabaseHelper>((ref) {
  return ProductDatabaseHelper();
});

final allProductsProvider = FutureProvider<List<String>>((ref) async {
  // Try cache first
  final cachedProducts = HiveService.instance.getCachedProducts();
  if (cachedProducts.isNotEmpty) {
    return cachedProducts.map((p) => p.id).toList();
  }
  // Fallback to backend
  final productHelper = ref.read(productDatabaseHelperProvider);
  final products = await productHelper.getAllProducts();
  // Cache products
  await HiveService.instance.cacheProducts(products.map((id) => Product(id)).toList());
  return products;
});

final categoryProductsProvider = FutureProvider.family<List<String>, ProductType>((ref, productType) async {
  // Try cache first
  final cachedProducts = HiveService.instance.getCachedProductsByType(productType);
  final productHelper = ref.read(productDatabaseHelperProvider);
  List<Product> validProducts = [];
  if (cachedProducts.isNotEmpty) {
    for (final product in cachedProducts) {
      final firestoreProduct = await productHelper.getProductWithID(product.id);
      if (firestoreProduct != null) {
        validProducts.add(product);
      } else {
        // Remove deleted product from cache
        await HiveService.instance.removeCachedProduct(product.id);
      }
    }
    if (validProducts.isNotEmpty) {
      return validProducts.map((p) => p.id).toList();
    }
  }
  // Fallback to backend
  final products = await productHelper.getCategoryProductsList(productType);
  // Remove deleted products from cache if any
  List<String> validIds = [];
  for (final id in products) {
    final firestoreProduct = await productHelper.getProductWithID(id);
    if (firestoreProduct != null) {
      validIds.add(id);
    } else {
      await HiveService.instance.removeCachedProduct(id);
    }
  }
  // Cache valid products by type
  await HiveService.instance.cacheProducts(validIds.map((id) => Product(id, productType: productType)).toList());
  return validIds;
});

final latestProductsProvider = FutureProvider.family<List<String>, int>((
  ref,
  limit,
) async {
  final productHelper = ref.watch(productDatabaseHelperProvider);
  return await productHelper.getLatestProducts(limit);
});

final productProvider = FutureProvider.family<Product?, String>((ref, productId) async {
  // Try cache first
  final cachedProduct = HiveService.instance.getCachedProduct(productId);
  if (cachedProduct != null) {
    return cachedProduct;
  }
  // Fallback to backend
  final productHelper = ref.read(productDatabaseHelperProvider);
  final product = await productHelper.getProductWithID(productId);
  if (product != null) {
    await HiveService.instance.cacheProduct(product);
  }
  return product;
});

final userProductsProvider = FutureProvider<List<String>>((ref) async {
  final productHelper = ref.watch(productDatabaseHelperProvider);
  return await productHelper.usersProductsList;
});

final productSearchProvider =
    FutureProvider.family<List<String>, ProductSearchParams>((
      ref,
      params,
    ) async {
      final productHelper = ref.watch(productDatabaseHelperProvider);
      return await productHelper.searchInProducts(
        params.query,
        productType: params.productType,
      );
    });

final productReviewsProvider = StreamProvider.family<List<Review>, String>((
  ref,
  productId,
) {
  final productHelper = ref.watch(productDatabaseHelperProvider);
  return productHelper.getAllReviewsStreamForProductId(productId);
});

class ProductSearchParams {
  final String query;
  final ProductType? productType;

  ProductSearchParams({required this.query, this.productType});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductSearchParams &&
        other.query == query &&
        other.productType == productType;
  }

  @override
  int get hashCode => query.hashCode ^ productType.hashCode;
}
