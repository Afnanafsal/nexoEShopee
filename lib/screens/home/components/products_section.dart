import 'package:nexoeshopee/components/nothingtoshow_container.dart';
import 'package:nexoeshopee/components/product_card.dart';
import 'package:nexoeshopee/screens/home/components/section_tile.dart';
import 'package:nexoeshopee/services/data_streams/data_stream.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../../size_config.dart';

class ProductsSection extends StatelessWidget {
  final String sectionTitle;
  final DataStream productsStreamController;
  final String emptyListMessage;
  final Function onProductCardTapped;
  final bool showViewAll;
  final bool useHorizontalView;

  const ProductsSection({
    super.key,
    required this.sectionTitle,
    required this.productsStreamController,
    this.emptyListMessage = "No Products to show here",
    required this.onProductCardTapped,
    this.showViewAll = true,
    this.useHorizontalView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
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
          Expanded(
            child: buildProductsList(),
          ),
        ],
      ),
    );
  }

  Widget buildProductsList() {
    return StreamBuilder<List<String>>(
      stream: productsStreamController.stream as Stream<List<String>>,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return Center(
              child: NothingToShowContainer(
                secondaryMessage: emptyListMessage,
              ),
            );
          }
          return useHorizontalView
              ? buildProductHorizontalList(snapshot.data!)
              : buildProductGrid(snapshot.data!);
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          final error = snapshot.error;
          Logger().w(error.toString());
        }
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
