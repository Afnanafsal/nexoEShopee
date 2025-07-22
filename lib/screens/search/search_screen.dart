import 'package:flutter/material.dart';
import 'package:fishkart/screens/product_details/product_details_screen.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/components/product_card.dart';
import 'package:fishkart/components/search_field.dart';
import 'package:fishkart/components/nothingtoshow_container.dart';
import 'package:fishkart/providers/providers.dart';
import 'package:fishkart/providers/providers.dart'; // Ensure cartProvider is imported
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/cache/hive_service.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Product> frequentlyBoughtProducts = [];
  List<Product> searchResults = [];
  bool isSearching = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFrequentlyBoughtProducts();
  }

  Future<void> fetchFrequentlyBoughtProducts() async {
    setState(() {
      isLoading = true;
    });
    // Fetch ordered product documents from Firestore
    final uid = UserDatabaseHelper().firestore
        .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
        .doc(AuthentificationService().currentUser.uid);
    final snapshot = await uid
        .collection(UserDatabaseHelper.ORDERED_PRODUCTS_COLLECTION_NAME)
        .get();
    // Extract product_uid from each order
    final List<String> productUids = [];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('product_uid') && data['product_uid'] != null) {
        productUids.add(data['product_uid'] as String);
      }
    }
    final Map<String, int> countMap = {};
    for (final id in productUids) {
      countMap[id] = (countMap[id] ?? 0) + 1;
    }
    // Sort by count descending
    final sortedIds = countMap.keys.toList()
      ..sort((a, b) => countMap[b]!.compareTo(countMap[a]!));

    // Batch fetch cached products first
    List<Product> products = [];
    List<String> missingIds = [];
    for (final id in sortedIds) {
      final cached = HiveService.instance.getCachedProduct(id);
      if (cached != null) {
        products.add(cached);
      } else {
        missingIds.add(id);
      }
    }
    // Batch fetch missing products from DB and cache them
    if (missingIds.isNotEmpty) {
      final fetchedProducts = await Future.wait(
        missingIds.map((id) => ProductDatabaseHelper().getProductWithID(id)),
      );
      for (int i = 0; i < fetchedProducts.length; i++) {
        final product = fetchedProducts[i];
        if (product != null) {
          products.add(product);
          await HiveService.instance.cacheProduct(product);
        }
      }
    }
    setState(() {
      frequentlyBoughtProducts = products;
      isLoading = false;
    });
  }

  Future<void> onSearch(String query) async {
    setState(() {
      isSearching = true;
      isLoading = true;
    });
    // Try cache first
    final cachedIds = HiveService.instance.getCachedSearchResults(query);
    List<Product> products = [];
    List<String> missingIds = [];
    if (cachedIds != null && cachedIds.isNotEmpty) {
      for (final id in cachedIds) {
        final cached = HiveService.instance.getCachedProduct(id);
        if (cached != null) {
          products.add(cached);
        } else {
          missingIds.add(id);
        }
      }
    } else {
      // No cache, search backend
      final ids = await ProductDatabaseHelper().searchInProducts(query);
      for (final id in ids) {
        final cached = HiveService.instance.getCachedProduct(id);
        if (cached != null) {
          products.add(cached);
        } else {
          missingIds.add(id);
        }
      }
      // Cache search result ids for next time
      await HiveService.instance.cacheSearchResults(query, ids);
    }
    // Batch fetch missing products and cache them
    if (missingIds.isNotEmpty) {
      final fetchedProducts = await Future.wait(
        missingIds.map((id) => ProductDatabaseHelper().getProductWithID(id)),
      );
      for (int i = 0; i < fetchedProducts.length; i++) {
        final product = fetchedProducts[i];
        if (product != null) {
          products.add(product);
          await HiveService.instance.cacheProduct(product);
        }
      }
    }
    setState(() {
      searchResults = products;
      isLoading = false;
    });
  }

  void addToCart(BuildContext context, String productId) {
    String? selectedAddressId;
    try {
      final container = ProviderScope.containerOf(context);
      selectedAddressId = container.read(selectedAddressIdProvider);
    } catch (_) {}
    UserDatabaseHelper()
        .addProductToCart(productId, addressId: selectedAddressId)
        .then((success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Added to cart' : 'Failed to add to cart',
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Products')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SearchField(
              onSubmit: (value) {
                if (value.trim().isNotEmpty) {
                  onSearch(value.trim());
                }
              },
            ),
            SizedBox(height: 16),
            if (!isSearching) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Frequently Bought Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 8),
            ],
            if (isLoading)
              Builder(
                builder: (context) {
                  // Show cached products instantly if available
                  final products = !isSearching
                      ? frequentlyBoughtProducts
                      : searchResults;
                  if (products.isNotEmpty) {
                    return Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Stack(
                            children: [
                              ProductCard(
                                productId: product.id,
                                press: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductDetailsScreen(
                                            key: Key(product.id),
                                            productId: product.id,
                                          ),
                                    ),
                                  );
                                },
                                showDiscountTag: false,
                              ),
                              Positioned(
                                bottom: isSearching ? 10 : 4,
                                right: isSearching ? 16 : 4,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 2,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      addToCart(context, product.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.add,
                                        size: 32,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }
                  // Otherwise show shimmer
                  final screenWidth = MediaQuery.of(context).size.width;
                  final cardWidth =
                      (screenWidth - 10 * 3) / 2; // 2 cards, 3 spacings
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Card(
                              elevation: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    height: cardWidth * 0.7,
                                    width: cardWidth,
                                    color: Colors.grey[300],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: cardWidth * 0.8,
                                          height: 16,
                                          color: Colors.grey[300],
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          width: cardWidth * 0.5,
                                          height: 14,
                                          color: Colors.grey[300],
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          width: cardWidth * 0.3,
                                          height: 14,
                                          color: Colors.grey[300],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            if (!isSearching && !isLoading)
              Expanded(
                child: frequentlyBoughtProducts.isEmpty
                    ? NothingToShowContainer(
                        secondaryMessage: 'No frequently bought products',
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: frequentlyBoughtProducts.length,
                        itemBuilder: (context, index) {
                          final product = frequentlyBoughtProducts[index];
                          return Stack(
                            children: [
                              ProductCard(
                                productId: product.id,
                                press: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductDetailsScreen(
                                            key: Key(product.id),
                                            productId: product.id,
                                          ),
                                    ),
                                  );
                                },
                                showDiscountTag: false,
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 2,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      addToCart(context, product.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.add,
                                        size: 32,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            if (isSearching && !isLoading)
              Expanded(
                child: searchResults.isEmpty
                    ? NothingToShowContainer(
                        secondaryMessage: 'No products found',
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final product = searchResults[index];
                          return Stack(
                            children: [
                              ProductCard(
                                productId: product.id,
                                press: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductDetailsScreen(
                                            key: Key(product.id),
                                            productId: product.id,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 10,
                                right: 16,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 2,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      addToCart(context, product.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.add,
                                        size: 32,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
