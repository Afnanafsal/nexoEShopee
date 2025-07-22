import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/services/base64_image_service/base64_image_service.dart';
import 'package:nexoeshopee/services/cache/hive_service.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:nexoeshopee/providers/user_providers.dart';
import 'package:logger/logger.dart';

class MyFavoritesScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyFavoritesScreen> createState() => _MyFavoritesScreenState();
}

class _MyFavoritesScreenState extends ConsumerState<MyFavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Favorites")),
      body: RefreshIndicator(
        onRefresh: refreshPage,
        child: buildFavoritesList(),
      ),
    );
  }

  Widget buildFavoritesList() {
    final favoritesAsync = ref.watch(favouriteProductsProvider);
    return favoritesAsync.when(
      data: (favoriteIds) {
        if (favoriteIds.isEmpty) {
          return Center(
            child: Text(
              "No favorites yet",
              style: TextStyle(fontSize: 16, color: kTextColor),
            ),
          );
        }
        // Try to get all products from cache synchronously
        List<Product> cachedProducts = [];
        List<String> missingIds = [];
        for (final id in favoriteIds) {
          final cached = HiveService.instance.getCachedProduct(id);
          if (cached != null) {
            cachedProducts.add(cached);
          } else {
            missingIds.add(id);
          }
        }
        if (missingIds.isEmpty) {
          // All products are cached, show instantly
          return ListView.builder(
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: getProportionateScreenWidth(screenPadding),
            ),
            itemCount: cachedProducts.length,
            itemBuilder: (context, index) {
              return buildFavoriteProductItem(cachedProducts[index]);
            },
          );
        } else {
          // Some products missing, fetch them
          return FutureBuilder<List<Product>>(
            future: () async {
              List<Product> allProducts = List.from(cachedProducts);
              if (missingIds.isNotEmpty) {
                final fetched = await Future.wait(
                  missingIds.map(
                    (id) => ProductDatabaseHelper().getProductWithID(id),
                  ),
                );
                for (int i = 0; i < fetched.length; i++) {
                  final product = fetched[i];
                  if (product != null) {
                    allProducts.add(product);
                    await HiveService.instance.cacheProduct(product);
                  }
                }
              }
              return allProducts;
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show cached products instantly while waiting for missing
                if (cachedProducts.isNotEmpty) {
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: getProportionateScreenWidth(screenPadding),
                    ),
                    itemCount: cachedProducts.length,
                    itemBuilder: (context, index) {
                      return buildFavoriteProductItem(cachedProducts[index]);
                    },
                  );
                }
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                Logger().w(snapshot.error.toString());
                return Center(
                  child: Text(
                    "Something went wrong",
                    style: TextStyle(fontSize: 16, color: kTextColor),
                  ),
                );
              }
              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return Center(
                  child: Text(
                    "No favorites yet",
                    style: TextStyle(fontSize: 16, color: kTextColor),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: getProportionateScreenWidth(screenPadding),
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return buildFavoriteProductItem(products[index]);
                },
              );
            },
          );
        }
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        Logger().w(error.toString());
        return Center(
          child: Text(
            "Something went wrong",
            style: TextStyle(fontSize: 16, color: kTextColor),
          ),
        );
      },
    );
  }

  Widget buildFavoriteProductItem(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  child: product.images != null && product.images!.isNotEmpty
                      ? Image(
                          image: Base64ImageService().base64ToImageProvider(
                            product.images![0],
                          ),
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.image_not_supported),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title ?? "No Title",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${product.variant ?? ""} - ₹${product.discountPrice ?? product.originalPrice}",
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.favorite, color: kPrimaryColor),
                onPressed: () async {
                  bool? confirmRemove = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Remove from Favorites?"),
                      content: Text(
                        "Are you sure you want to remove this item from your favorites?",
                      ),
                      actions: [
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: Text(
                            "Remove",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    ),
                  );

                  if (confirmRemove == true) {
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AsyncProgressDialog(
                          UserDatabaseHelper().removeFavoriteProduct(
                            product.id,
                          ),
                          message: Text("Removing from favorites"),
                        );
                      },
                    );
                    await refreshPage();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> refreshPage() {
    ref.invalidate(favouriteProductsProvider);
    return Future<void>.value();
  }

  Widget buildFavoriteItem(String productId) {
    return FutureBuilder<Product?>(
      future: ProductDatabaseHelper().getProductWithID(productId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final product = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 80,
                        child:
                            product.images != null && product.images!.isNotEmpty
                            ? Image(
                                image: Base64ImageService()
                                    .base64ToImageProvider(product.images![0]),
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.image_not_supported),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title ?? "No Title",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "${product.variant ?? ""} - ₹${product.discountPrice ?? product.originalPrice}",
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.favorite, color: kPrimaryColor),
                      onPressed: () async {
                        bool? confirmRemove = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Remove from Favorites?"),
                            content: Text(
                              "Are you sure you want to remove this item from your favorites?",
                            ),
                            actions: [
                              TextButton(
                                child: Text("Cancel"),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                              TextButton(
                                child: Text(
                                  "Remove",
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                              ),
                            ],
                          ),
                        );

                        if (confirmRemove == true) {
                          await showDialog(
                            context: context,
                            builder: (context) {
                              return AsyncProgressDialog(
                                UserDatabaseHelper().removeFavoriteProduct(
                                  productId,
                                ),
                                message: Text("Removing from favorites"),
                              );
                            },
                          );
                          await refreshPage();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          final error = snapshot.error;
          Logger().w(error.toString());
          return Center(
            child: Text(
              "Something went wrong",
              style: TextStyle(fontSize: 16, color: kTextColor),
            ),
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
