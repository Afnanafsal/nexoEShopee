import 'package:nexoeshopee/components/nothingtoshow_container.dart';
import 'package:nexoeshopee/components/product_card.dart';
import 'package:nexoeshopee/components/rounded_icon_button.dart';
import 'package:nexoeshopee/components/search_field.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/product_details/product_details_screen.dart';
import 'package:nexoeshopee/screens/search_result/search_result_screen.dart';
import 'package:nexoeshopee/providers/providers.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class Body extends ConsumerWidget {
  final ProductType productType;

  const Body({super.key, required this.productType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryProductsAsync = ref.watch(
      categoryProductsProvider(productType),
    );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryProductsProvider(productType));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(screenPadding),
            ),
            child: Column(
              children: [
                SizedBox(height: getProportionateScreenHeight(20)),
                buildHeadBar(context, ref),
                SizedBox(height: getProportionateScreenHeight(20)),
                SizedBox(
                  height: SizeConfig.screenHeight * 0.13,
                  child: buildCategoryBanner(),
                ),
                SizedBox(height: getProportionateScreenHeight(20)),
                _buildProductsSection(categoryProductsAsync),
                SizedBox(height: getProportionateScreenHeight(20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsSection(AsyncValue<List<String>> categoryProductsAsync) {
    return categoryProductsAsync.when(
      data: (productIds) {
        Logger().d('Displaying ${productIds.length} products in grid');

        if (productIds.isEmpty) {
          return SizedBox(
            height: 200,
            child: NothingToShowContainer(
              secondaryMessage:
                  "No products in ${EnumToString.convertToString(productType)}",
            ),
          );
        }

        return buildProductsGrid(productIds);
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        Logger().e('Error loading products: $error');
        return SizedBox(
          height: 200,
          child: NothingToShowContainer(
            iconPath: "assets/icons/network_error.svg",
            primaryMessage: "Something went wrong",
            secondaryMessage: "Unable to connect to Database",
          ),
        );
      },
    );
  }

  Widget buildHeadBar(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RoundedIconButton(
          iconData: Icons.arrow_back_ios,
          press: () => Navigator.pop(context),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: SearchField(
            onSubmit: (value) async {
              final query = value.toString().trim();
              if (query.isEmpty) return;
              try {
                final searchParams = ProductSearchParams(
                  query: query.toLowerCase(),
                  productType: productType,
                );
                final searchedProductsId = await ref.read(
                  productSearchProvider(searchParams).future,
                );

                if (context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchResultScreen(
                        searchQuery: query,
                        searchResultProductsId: searchedProductsId,
                        searchIn: EnumToString.convertToString(productType),
                      ),
                    ),
                  );
                  ref.invalidate(categoryProductsProvider(productType));
                }
              } catch (e) {
                Logger().e(e.toString());
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget buildCategoryBanner() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(bannerFromProductType()),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(kPrimaryColor, BlendMode.hue),
            ),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              EnumToString.convertToString(productType),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildProductsGrid(List<String> productIds) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      itemCount: productIds.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 2,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return Consumer(
          builder: (context, ref, child) {
            return ProductCard(
              productId: productIds[index],
              press: () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(
                        key: UniqueKey(),
                        productId: productIds[index],
                      ),
                    ),
                  ).then((_) {
                    ref.invalidate(categoryProductsProvider(productType));
                  }),
            );
          },
        );
      },
    );
  }

  String bannerFromProductType() {
    switch (productType) {
      case ProductType.Freshwater:
        return "assets/icons/rohu.png";
      case ProductType.Saltwater:
        return "assets/icons/Mackerel.png";
      case ProductType.Shellfish:
        return "assets/icons/prawns.png";
      case ProductType.Exotic:
        return "assets/icons/salmon.png";
      case ProductType.Dried:
        return "assets/icons/Anchovies.png";
      case ProductType.Others:
        return "assets/icons/canned.png";
      // Add other cases as needed
      default:
        return "assets/icons/canned.png";
    }
  }
}
