import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/components/top_rounded_container.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/screens/product_details/components/product_description.dart';
import 'package:fishkart/providers/user_providers.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../size_config.dart';
import '../../../utils.dart';

class ProductActionsSection extends ConsumerWidget {
  final Product product;

  const ProductActionsSection({required Key key, required this.product})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Stack(
          children: [
            TopRoundedContainer(
              key: const Key('top_rounded_container'),
              child: ProductDescription(
                key: const Key('product_description'),
                product: product,
              ),
            ),
            Align(alignment: Alignment.topCenter),
          ],
        ),
      ],
    );
  }
}
