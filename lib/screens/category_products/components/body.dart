import 'package:fishkart/components/nothingtoshow_container.dart';
import 'package:fishkart/components/product_card.dart';
import 'package:fishkart/components/rounded_icon_button.dart';
import 'package:fishkart/components/search_field.dart';
import 'package:fishkart/constants.dart';
import 'package:fishkart/models/Product.dart';
import 'package:fishkart/screens/product_details/product_details_screen.dart';
import 'package:fishkart/screens/search_result/search_result_screen.dart';
import 'package:fishkart/providers/providers.dart';
import 'package:fishkart/size_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                buildHeadBar(context, ref),
                SizedBox(height: 20.h),
                SizedBox(height: 120.h, child: buildCategoryBanner()),
                SizedBox(height: 20.h),
                _buildProductsSection(categoryProductsAsync),
                SizedBox(height: 20.h),
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
            height: 200.h,
            child: NothingToShowContainer(
              secondaryMessage:
                  "No products in ${EnumToString.convertToString(productType)}",
            ),
          );
        }

        return buildProductsGrid(productIds);
      },
      loading: () => Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: const CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        Logger().e('Error loading products: $error');
        return SizedBox(
          height: 200.h,
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
        SizedBox(width: 5.w),
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
            borderRadius: BorderRadius.circular(30.r),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: Text(
              EnumToString.convertToString(productType),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildProductsGrid(List<String> productIds) {
    // Filter out any null or empty productIds
    final filteredIds = productIds.where((id) => id.isNotEmpty).toList();
    if (filteredIds.isEmpty) {
      return Center(child: Text('No products to show.'));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
      itemCount: filteredIds.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 16.h,
      ),
      itemBuilder: (context, index) {
        return Consumer(
          builder: (context, ref, child) {
            return ProductCard(
              productId: filteredIds[index],
              press: () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(
                        key: UniqueKey(),
                        productId: filteredIds[index],
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
        return "assets/icons/mackerel.png";
      case ProductType.Shellfish:
        return "assets/icons/Prawns.png";
      case ProductType.Exotic:
        return "assets/icons/salmon.png";
      case ProductType.Dried:
        return "assets/icons/Anchovies.png";
      case ProductType.Others:
        return "assets/icons/canned.png";
      // Add other cases as needed
      // Removed redundant default clause as previous cases cover all possibilities.
    }
  }
}
