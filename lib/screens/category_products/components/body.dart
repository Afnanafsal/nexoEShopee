import 'package:nexoeshopee/components/nothingtoshow_container.dart';
import 'package:nexoeshopee/components/product_card.dart';
import 'package:nexoeshopee/components/rounded_icon_button.dart';
import 'package:nexoeshopee/components/search_field.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/product_details/product_details_screen.dart';
import 'package:nexoeshopee/screens/search_result/search_result_screen.dart';
import 'package:nexoeshopee/services/data_streams/category_products_stream.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class Body extends StatefulWidget {
  final ProductType productType;

  const Body({super.key, required this.productType});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  late final CategoryProductsStream categoryProductsStream;
  List<String> _cachedProductIds = [];
  bool _isInitialLoad = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    categoryProductsStream = CategoryProductsStream(widget.productType);
    _preloadProducts();
  }

  Future<void> _preloadProducts() async {
    try {
      // Use the stream to get initial data instead of a direct method call
      final streamData = await categoryProductsStream.stream.first;
      if (mounted) {
        setState(() {
          _cachedProductIds = streamData;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialLoad = false;
        });
      }
      Logger().e('Error preloading products: $e');
    }
  }

  Future<void> refreshPage() async {
    setState(() {
      _isInitialLoad = true;
      _hasError = false;
    });
    categoryProductsStream.reload();
    await _preloadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refreshPage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(screenPadding),
            ),
            child: Column(
              children: [
                SizedBox(height: getProportionateScreenHeight(20)),
                buildHeadBar(),
                SizedBox(height: getProportionateScreenHeight(20)),
                SizedBox(
                  height: SizeConfig.screenHeight * 0.13,
                  child: buildCategoryBanner(),
                ),
                SizedBox(height: getProportionateScreenHeight(20)),
                _buildProductsSection(),
                SizedBox(height: getProportionateScreenHeight(20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    if (_isInitialLoad) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return SizedBox(
        height: 200,
        child: NothingToShowContainer(
          iconPath: "assets/icons/network_error.svg",
          primaryMessage: "Something went wrong",
          secondaryMessage: "Unable to connect to Database",
        ),
      );
    }

    if (_cachedProductIds.isEmpty) {
      return SizedBox(
        height: 200,
        child: NothingToShowContainer(
          secondaryMessage:
              "No products in ${EnumToString.convertToString(widget.productType)}",
        ),
      );
    }

    return StreamBuilder<List<String>>(
      stream: categoryProductsStream.stream,
      initialData: _cachedProductIds,
      builder: (context, snapshot) {
        List<String> productIds = _cachedProductIds;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          productIds = snapshot.data!;
          // Update cache with fresh data
          _cachedProductIds = productIds;
        }

        // If no products after stream update, show empty state
        if (productIds.isEmpty) {
          return SizedBox(
            height: 200,
            child: NothingToShowContainer(
              secondaryMessage:
                  "No products in ${EnumToString.convertToString(widget.productType)}",
            ),
          );
        }

        return buildProductsGrid(productIds);
      },
    );
  }

  Widget buildHeadBar() {
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
                final searchedProductsId = await ProductDatabaseHelper()
                    .searchInProducts(
                      query.toLowerCase(),
                      productType: widget.productType,
                    );
                if (mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchResultScreen(
                        searchQuery: query,
                        searchResultProductsId: searchedProductsId,
                        searchIn: EnumToString.convertToString(
                          widget.productType,
                        ),
                      ),
                    ),
                  );
                  await refreshPage();
                }
              } catch (e) {
                Logger().e(e.toString());
                if (mounted) {
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
              EnumToString.convertToString(widget.productType),
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
        return ProductCard(
          productId: productIds[index],
          press: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(
                key: UniqueKey(),
                productId: productIds[index],
              ),
            ),
          ).then((_) => refreshPage()),
        );
      },
    );
  }

  String bannerFromProductType() {
    switch (widget.productType) {
      case ProductType.Chicken:
        return "assets/images/chicken_banner.jpg";
      case ProductType.Mutton:
        return "assets/images/mutton_banner.jpg";
      case ProductType.Beef:
        return "assets/images/beef_banner.jpg";
      case ProductType.Fish:
        return "assets/images/fish_banner.jpg";
      case ProductType.Eggs:
        return "assets/images/eggs_banner.jpg";
      case ProductType.MarinatedItems:
        return "assets/images/marinated_banner.jpg";
      case ProductType.ReadyToEat:
        return "assets/images/ready_to_eat_banner.jpg";
      case ProductType.Others:
        return "assets/images/others_banner.jpg";
    }
  }
}
