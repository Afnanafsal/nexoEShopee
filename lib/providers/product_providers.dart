import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/models/Review.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/providers/cache_providers.dart';

final productDatabaseHelperProvider = Provider<ProductDatabaseHelper>((ref) {
  return ProductDatabaseHelper();
});

// Products with caching
final allProductsProvider = FutureProvider<List<String>>((ref) async {
  final productHelper = ref.watch(productDatabaseHelperProvider);
  final cacheService = ref.watch(productCacheProvider);

  // Try to get from cache first
  final cachedProducts = cacheService.getCachedProducts();
  if (cachedProducts.isNotEmpty) {
    return cachedProducts.map((p) => p.id).toList();
  }

  // If not in cache, fetch from database
  final productIds = await productHelper.getAllProducts();

  // Cache the products
  final products = await Future.wait(
    productIds.map((id) => productHelper.getProductWithID(id)),
  );
  final validProducts = products
      .where((p) => p != null)
      .cast<Product>()
      .toList();
  await cacheService.cacheProducts(validProducts);

  return productIds;
});

final categoryProductsProvider =
    FutureProvider.family<List<String>, ProductType>((ref, productType) async {
      final productHelper = ref.watch(productDatabaseHelperProvider);
      final cacheService = ref.watch(productCacheProvider);

      // Try to get from cache first
      final cachedProducts = cacheService.getCachedProductsByType(productType);
      if (cachedProducts.isNotEmpty) {
        return cachedProducts.map((p) => p.id).toList();
      }

      // If not in cache, fetch from database
      final productIds = await productHelper.getCategoryProductsList(
        productType,
      );

      // Cache the products
      final products = await Future.wait(
        productIds.map((id) => productHelper.getProductWithID(id)),
      );
      final validProducts = products
          .where((p) => p != null)
          .cast<Product>()
          .toList();
      await cacheService.cacheProducts(validProducts);

      return productIds;
    });

final latestProductsProvider = FutureProvider.family<List<String>, int>((
  ref,
  limit,
) async {
  final productHelper = ref.watch(productDatabaseHelperProvider);
  return await productHelper.getLatestProducts(limit);
});

final productProvider = FutureProvider.family<Product?, String>((
  ref,
  productId,
) async {
  final productHelper = ref.watch(productDatabaseHelperProvider);
  final cacheService = ref.watch(productCacheProvider);

  // Try to get from cache first
  final cachedProduct = cacheService.getCachedProduct(productId);
  if (cachedProduct != null) {
    return cachedProduct;
  }

  // If not in cache, fetch from database
  final product = await productHelper.getProductWithID(productId);

  // Cache the product if found
  if (product != null) {
    await cacheService.cacheProduct(product);
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
