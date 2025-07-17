import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/body.dart';
import 'components/fab.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailsScreen({required Key key, required this.productId})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6F9),
      body: Body(key: key!, productId: productId),
      floatingActionButton: AddToCartFAB(productId: productId, key: key!),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
