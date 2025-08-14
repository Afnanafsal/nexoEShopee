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
    final uid = UserDatabaseHelper().firestore
        .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
        .doc(AuthentificationService().currentUser.uid);
    final snapshot = await uid
        .collection(UserDatabaseHelper.ORDERED_PRODUCTS_COLLECTION_NAME)
        .get();

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
    final sortedIds = countMap.keys.toList()
      ..sort((a, b) => countMap[b]!.compareTo(countMap[a]!));

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
      final ids = await ProductDatabaseHelper().searchInProducts(query);
      for (final id in ids) {
        final cached = HiveService.instance.getCachedProduct(id);
        if (cached != null) {
          products.add(cached);
        } else {
          missingIds.add(id);
        }
      }
      await HiveService.instance.cacheSearchResults(query, ids);
    }

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
    if (selectedAddressId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Please select a delivery address before adding to cart.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    UserDatabaseHelper()
        .addProductToCart(productId, addressId: selectedAddressId)
        .then((success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success ? 'Added to cart!' : 'Failed to add to cart.',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        })
        .catchError((e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add to cart: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }

  Widget _buildCustomSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 4.h,
      ), // reduced height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35.r), // increased radius
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
                size: 28, // slightly smaller
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Type your fish...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4.h),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
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
              child: const Icon(Icons.search, color: Colors.black, size: 28),
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
        borderRadius: BorderRadius.all(Radius.circular(15.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
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
              borderRadius: BorderRadius.circular(15.r),
              child: Container(
                height: 110.h, // reduced height
                width: double.infinity,
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Builder(
                    builder: (context) {
                      final img =
                          product.images != null && product.images!.isNotEmpty
                          ? product.images!.first
                          : null;
                      if (img == null || img.isEmpty) {
                        return Icon(
                          Icons.image,
                          size: 24.sp,
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
              padding: EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _truncateProductName(product.title ?? 'Product Name'),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    product.variant != null && product.variant!.isNotEmpty
                        ? product.variant!
                        : '500 gms',
                    style: TextStyle(fontSize: 10.sp, color: Color(0xFF8E8E93)),
                  ),
                  SizedBox(height: 4.h),
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
                                  fontSize: 12.sp,
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
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 12.sp,
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
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 70, height: 10, color: Colors.grey),
                        const SizedBox(height: 3),
                        Container(width: 50, height: 9, color: Colors.grey),
                      ],
                    ),
                    Container(width: 40, height: 10, color: Colors.grey),
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
      backgroundColor: const Color(0xFFEFF1F5),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(30.0), // slightly reduced
          child: Column(
            children: [
              _buildCustomSearchBar(),
              const SizedBox(height: 30),
              Expanded(
                child: isLoading
                    ? GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85, // reduced height
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 24,
                            ),
                        itemCount: 8,
                        itemBuilder: (context, index) => _buildShimmerCard(),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85, // reduced height
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 24,
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
