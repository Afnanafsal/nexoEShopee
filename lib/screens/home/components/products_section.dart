import 'package:nexoeshopee/components/nothingtoshow_container.dart';
import 'package:nexoeshopee/components/product_card.dart';
import 'package:nexoeshopee/screens/home/components/section_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../size_config.dart';

class ProductsSection extends ConsumerWidget {
  final String sectionTitle;
  final AsyncValue<List<String>> productsAsync;
  final String emptyListMessage;
  final Function onProductCardTapped;
  final bool showViewAll;
  final bool useHorizontalView;

  const ProductsSection({
    super.key,
    required this.sectionTitle,
    required this.productsAsync,
    this.emptyListMessage = "No Products to show here",
    required this.onProductCardTapped,
    this.showViewAll = true,
    this.useHorizontalView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F6F9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          SectionTile(
            key: Key(sectionTitle),
            title: sectionTitle,
            press: () {
              if (showViewAll) {
                // TODO: Implement view all functionality
              }
            },
          ),
          SizedBox(height: getProportionateScreenHeight(15)),
          Expanded(child: buildProductsList()),
        ],
      ),
    );
  }

  Widget buildProductsList() {
    return productsAsync.when(
      data: (productIds) {
        if (productIds.isEmpty) {
          return Center(
            child: NothingToShowContainer(secondaryMessage: emptyListMessage),
          );
        }
        return useHorizontalView
            ? buildProductHorizontalList(productIds)
            : buildProductGrid(productIds);
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        Logger().w(error.toString());
        return Center(
          child: NothingToShowContainer(
            iconPath: "assets/icons/network_error.svg",
            primaryMessage: "Something went wrong",
            secondaryMessage: "Unable to connect to Database",
          ),
        );
      },
    );
  }

  Widget buildProductGrid(List<String> productsId) {
    return GridView.builder(
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: productsId.length,
      itemBuilder: (context, index) {
        return ProductCard(
          productId: productsId[index],
          press: () {
            onProductCardTapped.call(productsId[index]);
          },
        );
      },
    );
  }

  Widget buildProductHorizontalList(List<String> productsId) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: BouncingScrollPhysics(),
      itemCount: productsId.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(right: 10),
          child: SizedBox(
            width: getProportionateScreenWidth(150),
            child: ProductCard(
              productId: productsId[index],
              press: () {
                onProductCardTapped.call(productsId[index]);
              },
            ),
          ),
        );
      },
    );
  }
}
