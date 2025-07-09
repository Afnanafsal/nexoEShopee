import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/models/Review.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';

final productDatabaseHelperProvider = Provider<ProductDatabaseHelper>((ref) {
  return ProductDatabaseHelper();
});

final allProductsProvider = FutureProvider<List<String>>((ref) async {
  final productHelper = ref.watch(productDatabaseHelperProvider);
  return await productHelper.getAllProducts();
});

final categoryProductsProvider =
    FutureProvider.family<List<String>, ProductType>((ref, productType) async {
      final productHelper = ref.watch(productDatabaseHelperProvider);
      return await productHelper.getCategoryProductsList(productType);
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
  return await productHelper.getProductWithID(productId);
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
