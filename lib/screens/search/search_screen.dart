import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fishkart/screens/product_details/product_details_screen.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/services/database/product_database_helper.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/providers/providers.dart';
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
  // Helper to truncate product name at '/' or '('
  String _truncateProductName(String name) {
    final slashIdx = name.indexOf('/');
    final parenIdx = name.indexOf('(');
    int cutIdx = name.length;
    if (slashIdx != -1 && parenIdx != -1) {
      cutIdx = slashIdx < parenIdx ? slashIdx : parenIdx;
    } else if (slashIdx != -1) {
      cutIdx = slashIdx;
    } else if (parenIdx != -1) {
      cutIdx = parenIdx;
    }
    return name.substring(0, cutIdx).trim();
  }

  List<Product> frequentlyBoughtProducts = [];
  List<Product> searchResults = [];
  bool isSearching = false;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFrequentlyBoughtProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        });
  }

  Widget _buildCustomSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Type your fish...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              style: TextStyle(fontSize: 16.sp, color: Colors.black),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  onSearch(value.trim());
                }
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_searchController.text.trim().isNotEmpty) {
                onSearch(_searchController.text.trim());
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.search, color: Colors.black, size: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          12.r,
        ), // Slightly smaller border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Reduced shadow opacity
            blurRadius: 4, // Reduced blur radius
            offset: const Offset(0, 1), // Smaller shadow offset
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(
                key: Key(product.id),
                productId: product.id,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                height: 100.h, // Reduced image height significantly
                width: double.infinity,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(8.w), // Reduced padding
                  child: Builder(
                    builder: (context) {
                      final img =
                          product.images != null && product.images!.isNotEmpty
                          ? product.images!.first
                          : null;
                      if (img == null || img.isEmpty) {
                        return Icon(
                          Icons.image,
                          size: 24.sp, // Smaller icon
                          color: Colors.grey,
                        );
                      } else if (img.startsWith('http')) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image,
                              size: 24.sp,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      } else if (img.startsWith('assets/')) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.asset(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image,
                              size: 24.sp,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      } else if (img.startsWith('data:image') ||
                          img.length > 100) {
                        try {
                          final base64Str = img.contains(',')
                              ? img.split(',').last
                              : img;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.memory(
                              base64Decode(base64Str),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.image,
                                    size: 24.sp,
                                    color: Colors.grey,
                                  ),
                            ),
                          );
                        } catch (_) {
                          return Icon(
                            Icons.image,
                            size: 24,
                            color: Colors.grey,
                          );
                        }
                      } else {
                        return Icon(Icons.image, size: 24, color: Colors.grey);
                      }
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                8.w,
                6.h,
                8.w,
                8.h,
              ), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _truncateProductName(product.title ?? 'Product Name'),
                    style: TextStyle(
                      fontSize: 12.sp, // Smaller font size
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1, // Reduced to 1 line
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h), // Smaller spacing
                  Text(
                    product.variant != null && product.variant!.isNotEmpty
                        ? product.variant!
                        : '500 gms',
                    style: TextStyle(
                      fontSize: 10.sp, // Smaller variant text
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 4.h), // Small spacing before price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.originalPrice != null &&
                                product.originalPrice! > 0 &&
                                product.originalPrice != product.discountPrice)
                              Text(
                                '₹${product.discountPrice?.toStringAsFixed(2) ?? product.originalPrice?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontSize: 12.sp, // Smaller price text
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => addToCart(context, product.id),
                        child: Container(
                          width: 20.w, // Smaller add button
                          height: 20.w,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.all(
                              Radius.circular(4.r), // Smaller border radius
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 12.sp, // Smaller icon
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2, // Adjusted flex ratio for smaller image area
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              flex: 2, // Adjusted flex ratio
              child: Padding(
                padding: const EdgeInsets.all(8), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 12,
                          color: Colors.grey,
                        ), // Smaller shimmer blocks
                        const SizedBox(height: 3),
                        Container(width: 50, height: 10, color: Colors.grey),
                      ],
                    ),
                    Container(width: 40, height: 12, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0XFFEFF1F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
          child: Column(
            children: [
              _buildCustomSearchBar(),
              const SizedBox(height: 24),
              Expanded(
                child: isLoading
                    ? GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio:
                                  0.9, // Adjusted aspect ratio for smaller cards
                              crossAxisSpacing:
                                  24, // Increased horizontal spacing
                              mainAxisSpacing: 24, // Increased vertical spacing
                            ),
                        itemCount: 8,
                        itemBuilder: (context, index) => _buildShimmerCard(),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio:
                                  0.9, // Adjusted aspect ratio for smaller cards
                              crossAxisSpacing:
                                  24, // Increased horizontal spacing
                              mainAxisSpacing: 24, // Increased vertical spacing
                            ),
                        itemCount: isSearching
                            ? searchResults.length
                            : frequentlyBoughtProducts.length,
                        itemBuilder: (context, index) {
                          final product = isSearching
                              ? searchResults[index]
                              : frequentlyBoughtProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
