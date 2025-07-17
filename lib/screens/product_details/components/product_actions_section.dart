import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:nexoeshopee/components/top_rounded_container.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/product_details/components/product_description.dart';
import 'package:nexoeshopee/providers/user_providers.dart';
import 'package:nexoeshopee/services/authentification/authentification_service.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
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
