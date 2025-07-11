// Example usage of enhanced product details caching
// This file demonstrates how to use the new caching functionality

import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/services/cache/hive_service.dart';

class ProductCacheExamples {
  static final HiveService _hiveService = HiveService.instance;

  // Example 1: Cache a product with complete details
  static Future<void> cacheCompleteProduct(Product product) async {
    // Sample review data
    final reviews = [
      {
        'reviewer_uid': 'user123',
        'rating': 5,
        'review': 'Excellent product!',
        'date': DateTime.now().toIso8601String(),
      },
      {
        'reviewer_uid': 'user456',
        'rating': 4,
        'review': 'Good quality, fast delivery',
        'date': DateTime.now().toIso8601String(),
      },
    ];

    // Sample specifications
    final specifications = {
      'weight': '1kg',
      'origin': 'Local Farm',
      'packaging': 'Vacuum sealed',
      'shelf_life': '7 days',
      'temperature': 'Keep refrigerated',
    };

    // Sample metadata
    final metadata = {
      'supplier_id': 'supplier123',
      'batch_number': 'BATCH001',
      'expiry_date': DateTime.now().add(Duration(days: 7)).toIso8601String(),
      'nutritional_info': {
        'calories': '200 per 100g',
        'protein': '25g',
        'fat': '10g',
      },
    };

    await _hiveService.cacheProductWithDetails(
      product,
      reviews: reviews,
      totalReviews: reviews.length,
      averageRating: 4.5,
      stockQuantity: 50,
      isAvailable: true,
      specifications: specifications,
      relatedProductIds: ['product2', 'product3', 'product4'],
      viewCount: 150,
      purchaseCount: 25,
      metadata: metadata,
      isFeatured: true,
      category: 'Fresh Meat',
      subcategory: 'Chicken',
      tags: ['fresh', 'organic', 'premium'],
      cacheDuration: Duration(hours: 12),
    );
  }

  // Example 2: Update specific product details
  static Future<void> updateProductDetails(String productId) async {
    // Update stock
    await _hiveService.updateProductStock(productId, 45, available: true);

    // Add new reviews
    final newReviews = [
      {
        'reviewer_uid': 'user789',
        'rating': 5,
        'review': 'Outstanding quality!',
        'date': DateTime.now().toIso8601String(),
      },
    ];
    await _hiveService.updateProductReviews(productId, newReviews);

    // Update metadata
    await _hiveService.updateProductMetadata(productId, {
      'last_restocked': DateTime.now().toIso8601String(),
      'quality_grade': 'A+',
    });

    // Track user interaction
    await _hiveService.incrementProductViewCount(productId);
  }

  // Example 3: Retrieve cached product with details
  static Future<Map<String, dynamic>?> getProductWithDetails(
    String productId,
  ) async {
    final cachedProduct = _hiveService.getCachedProductWithDetails(productId);

    if (cachedProduct != null) {
      return {
        'product': cachedProduct.toProduct(),
        'details': cachedProduct.getProductDetails(),
        'cache_info': {
          'cached_at': cachedProduct.cachedAt,
          'is_expired': cachedProduct.isExpired,
          'has_reviews': cachedProduct.hasReviews,
          'has_stock': cachedProduct.hasStock,
          'has_specifications': cachedProduct.hasSpecifications,
          'reviews_expired': cachedProduct.isReviewsExpired(),
          'stock_expired': cachedProduct.isStockExpired(),
        },
      };
    }
    return null;
  }

  // Example 4: Get filtered products
  static Future<List<Product>> getFilteredProducts() async {
    // Get featured products
    final featuredProducts = _hiveService.getCachedFeaturedProducts();

    // Get products with stock
    final inStockProducts = _hiveService.getCachedProductsWithStock();

    // Get products by category
    final chickenProducts = _hiveService.getCachedProductsByCategoryName(
      'Chicken',
    );

    // Get products with reviews
    final reviewedProducts = _hiveService.getCachedProductsWithReviews();

    // Get popular products
    final popularProducts = _hiveService.getCachedProductsByPopularity(
      limit: 10,
    );

    print('Featured: ${featuredProducts.length}');
    print('In Stock: ${inStockProducts.length}');
    print('Chicken: ${chickenProducts.length}');
    print('With Reviews: ${reviewedProducts.length}');
    print('Popular: ${popularProducts.length}');

    return popularProducts;
  }

  // Example 5: Cache maintenance
  static Future<void> performCacheMaintenance() async {
    // Clear expired product details (keeps basic product info)
    await _hiveService.clearExpiredProductDetails();

    // Clear completely expired products
    await _hiveService.clearExpiredProducts();

    // General cleanup
    await _hiveService.cleanupExpiredData();

    print('Cache maintenance completed');
  }

  // Example 6: Check cache status
  static Future<Map<String, dynamic>> getCacheStatus() async {
    final totalProducts = _hiveService.getCachedProductsCount();
    final allProducts = _hiveService.getCachedProducts();

    int productsWithReviews = 0;
    int productsWithStock = 0;
    int featuredProducts = 0;
    int expiredProducts = 0;

    for (final product in allProducts) {
      final cached = _hiveService.getCachedProductWithDetails(product.id);
      if (cached != null) {
        if (cached.hasReviews) productsWithReviews++;
        if (cached.hasStock) productsWithStock++;
        if (cached.isFeatured == true) featuredProducts++;
        if (cached.isExpired) expiredProducts++;
      }
    }

    return {
      'total_products': totalProducts,
      'products_with_reviews': productsWithReviews,
      'products_with_stock': productsWithStock,
      'featured_products': featuredProducts,
      'expired_products': expiredProducts,
      'cache_health': expiredProducts / totalProducts * 100,
    };
  }
}
