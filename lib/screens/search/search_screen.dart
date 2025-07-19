import 'package:flutter/material.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/components/product_card.dart';
import 'package:nexoeshopee/components/search_field.dart';
import 'package:nexoeshopee/components/nothingtoshow_container.dart';

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
    final orderedIds = await UserDatabaseHelper().orderedProductsList;
    final Map<String, int> countMap = {};
    for (final id in orderedIds) {
      countMap[id] = (countMap[id] ?? 0) + 1;
    }
    // Sort by count descending
    final sortedIds = countMap.keys.toList()
      ..sort((a, b) => countMap[b]!.compareTo(countMap[a]!));
    // Fetch product details
    List<Product> products = [];
    for (final id in sortedIds) {
      final product = await ProductDatabaseHelper().getProductWithID(id);
      if (product != null) products.add(product);
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
    final ids = await ProductDatabaseHelper().searchInProducts(query);
    List<Product> products = [];
    for (final id in ids) {
      final product = await ProductDatabaseHelper().getProductWithID(id);
      if (product != null) products.add(product);
    }
    setState(() {
      searchResults = products;
      isLoading = false;
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
            if (isLoading) Center(child: CircularProgressIndicator()),
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
                          return ProductCard(
                            productId: product.id,
                            press: () {
                              // Navigate to product details
                            },
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
                          return ProductCard(
                            productId: product.id,
                            press: () {
                              // Navigate to product details
                            },
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
