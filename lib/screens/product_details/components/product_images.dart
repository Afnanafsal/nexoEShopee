import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/providers/product_details_providers.dart';
import 'package:nexoeshopee/services/base64_image_service/base64_image_service.dart';
import 'package:nexoeshopee/size_config.dart';

class ProductImages extends ConsumerWidget {
  final Product product;

  const ProductImages({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swiperState = ref.watch(productImageSwiperProvider(product.id));
    return Container(
      color: const Color(0xFFF6F7FA),
      child: _ProductDetailsContent(
        product: product,
        swiperState: swiperState,
        ref: ref,
      ),
    );
  }
}

class _ProductDetailsContent extends StatefulWidget {
  final Product product;
  final dynamic swiperState;
  final WidgetRef ref;

  const _ProductDetailsContent({
    Key? key,
    required this.product,
    required this.swiperState,
    required this.ref,
  }) : super(key: key);

  @override
  State<_ProductDetailsContent> createState() => _ProductDetailsContentState();
}

class _ProductDetailsContentState extends State<_ProductDetailsContent> {
  late PageController _pageController;
  int _currentPage = 0;
  int cartCount = 0;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _loadFavoriteStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteStatus() async {
    final db = FirebaseFirestore.instance;
    final userId = await _getCurrentUserId();
    final userDoc = await db.collection('users').doc(userId).get();
    final favList = List<String>.from(
      userDoc.data()?['favourite_products'] ?? [],
    );
    setState(() {
      isFavorite = favList.contains(widget.product.id);
    });
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      isFavorite = !isFavorite;
    });
    final db = FirebaseFirestore.instance;
    final userId = await _getCurrentUserId();
    final userRef = db.collection('users').doc(userId);
    if (isFavorite) {
      await userRef.update({
        'favourite_products': FieldValue.arrayUnion([widget.product.id]),
      });
    } else {
      await userRef.update({
        'favourite_products': FieldValue.arrayRemove([widget.product.id]),
      });
    }
  }

  Future<String> _getCurrentUserId() async {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  void _incrementCounter() {
    setState(() {
      cartCount++;
    });
  }

  void _decrementCounter() {
    if (cartCount > 0) {
      setState(() {
        cartCount--;
      });
    }
  }

  void _addToCart() {
    if (cartCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least 1 item to add to cart.'),
        ),
      );
      return;
    }
    // Add to cart logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $cartCount item(s) to cart.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images ?? [];
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: Container(
            color: const Color(0xFFF6F7FA),
            height: getProportionateScreenHeight(260),
            child: images.isNotEmpty
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final img = images[index];
                      return img.isNotEmpty
                          ? SizedBox.expand(
                              child: Base64ImageService().base64ToImage(img),
                            )
                          : Center(
                              child: Icon(
                                Icons.image,
                                size: getProportionateScreenWidth(120),
                                color: Colors.grey,
                              ),
                            );
                    },
                  )
                : Center(
                    child: Icon(
                      Icons.image,
                      size: getProportionateScreenWidth(120),
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
        // Dot pagination overlay
        if (images.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? kPrimaryColor : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        // Back button
        Positioned(
          top: 16,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
        // Favorite button
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: () async {
              await _toggleFavorite();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite
                        ? 'Added to favorites'
                        : 'Removed from favorites',
                  ),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              padding: EdgeInsets.all(8),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
