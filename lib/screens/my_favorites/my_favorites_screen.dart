import 'package:flutter/material.dart';
import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/services/data_streams/favourite_products_stream.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/services/base64_image_service/base64_image_service.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:logger/logger.dart';

class MyFavoritesScreen extends StatefulWidget {
  @override
  _MyFavoritesScreenState createState() => _MyFavoritesScreenState();
}

class _MyFavoritesScreenState extends State<MyFavoritesScreen> {
  final FavouriteProductsStream favouriteProductsStream = FavouriteProductsStream();

  @override
  void initState() {
    super.initState();
    favouriteProductsStream.init();
  }

  @override
  void dispose() {
    favouriteProductsStream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Favorites"),
      ),
      body: RefreshIndicator(
        onRefresh: refreshPage,
        child: StreamBuilder<List<String>>(
          stream: favouriteProductsStream.stream as Stream<List<String>>,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<String> favoriteIds = snapshot.data ?? [];
              if (favoriteIds.isEmpty) {
                return Center(
                  child: Text(
                    "No favorites yet",
                    style: TextStyle(
                      fontSize: 16,
                      color: kTextColor,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: getProportionateScreenWidth(screenPadding),
                ),
                itemCount: favoriteIds.length,
                itemBuilder: (context, index) {
                  return buildFavoriteItem(favoriteIds[index]);
                },
              );
            } else if (snapshot.hasError) {
              final error = snapshot.error;
              Logger().w(error.toString());
              return Center(
                child: Text(
                  "Something went wrong",
                  style: TextStyle(
                    fontSize: 16,
                    color: kTextColor,
                  ),
                ),
              );
            }
            return Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  Future<void> refreshPage() {
    favouriteProductsStream.reload();
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
                        child: product.images != null && product.images!.isNotEmpty
                            ? Image(
                                image: Base64ImageService().base64ToImageProvider(product.images![0]),
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
                      icon: Icon(
                        Icons.favorite,
                        color: kPrimaryColor,
                      ),
                      onPressed: () async {
                        bool? confirmRemove = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Remove from Favorites?"),
                            content: Text("Are you sure you want to remove this item from your favorites?"),
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
                                UserDatabaseHelper().removeFavoriteProduct(productId),
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
              style: TextStyle(
                fontSize: 16,
                color: kTextColor,
              ),
            ),
          );
        }
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
