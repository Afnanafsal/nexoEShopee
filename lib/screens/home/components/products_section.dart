import 'package:fishkart/components/nothingtoshow_container.dart';
import 'package:fishkart/components/product_card.dart';
import 'package:fishkart/screens/home/components/section_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';

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
              if (showViewAll) {}
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
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: useHorizontalView
            ? SizedBox(
                height: getProportionateScreenWidth(180),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: getProportionateScreenWidth(150),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Card(
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(height: 100, color: Colors.grey[300]),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 16,
                                      color: Colors.grey[300],
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      width: 60,
                                      height: 14,
                                      color: Colors.grey[300],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 4,
                itemBuilder: (context, index) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Card(
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(height: 100, color: Colors.grey[300]),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 16,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 8),
                              Container(
                                width: 60,
                                height: 14,
                                color: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
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
