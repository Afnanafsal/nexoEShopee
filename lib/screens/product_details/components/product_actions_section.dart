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
    final isFavouriteAsync = ref.watch(isProductFavouriteProvider(product.id));

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
            Align(
              alignment: Alignment.topCenter,
              child: buildFavouriteButton(context, ref, isFavouriteAsync),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildFavouriteButton(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<bool> isFavouriteAsync,
  ) {
    return isFavouriteAsync.when(
      data: (isFavourite) {
        return InkWell(
          onTap: () async {
            bool allowed = AuthentificationService().currentUserVerified;
            if (!allowed) {
              final reverify = await showConfirmationDialog(
                context,
                "You haven't verified your email address. This action is only allowed for verified users.",
                positiveResponse: "Resend verification email",
                negativeResponse: "Go back",
              );
              if (reverify) {
                final future = AuthentificationService()
                    .sendVerificationEmailToCurrentUser();
                await showDialog(
                  context: context,
                  builder: (context) {
                    return AsyncProgressDialog(
                      future,
                      message: Text("Resending verification email"),
                    );
                  },
                );
              }
              return;
            }
            bool success = false;
            final future = UserDatabaseHelper()
                .switchProductFavouriteStatus(product.id, !isFavourite)
                .then((status) {
                  success = status;
                })
                .catchError((e) {
                  Logger().e(e.toString());
                  success = false;
                });
            await showDialog(
              context: context,
              builder: (context) {
                return AsyncProgressDialog(
                  future,
                  message: Text(
                    isFavourite
                        ? "Removing from Favourites"
                        : "Adding to Favourites",
                  ),
                );
              },
            );
            if (success) {
              ref.invalidate(isProductFavouriteProvider(product.id));
              ref.invalidate(favouriteProductsProvider);
            }
          },
          child: Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(8)),
            decoration: BoxDecoration(
              color: isFavourite ? Color(0xFFFFE6E6) : Color(0xFFF5F6F9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Padding(
              padding: EdgeInsets.all(getProportionateScreenWidth(8)),
              child: Icon(
                Icons.favorite,
                color: isFavourite ? Color(0xFFFF4848) : Color(0xFFD8DEE4),
              ),
            ),
          ),
        );
      },
      loading: () => Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(8)),
        decoration: BoxDecoration(
          color: Color(0xFFF5F6F9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(8)),
          child: Icon(Icons.favorite, color: Color(0xFFD8DEE4)),
        ),
      ),
      error: (err, stack) => Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(8)),
        decoration: BoxDecoration(
          color: Color(0xFFF5F6F9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(8)),
          child: Icon(Icons.favorite, color: Color(0xFFD8DEE4)),
        ),
      ),
    );
  }
}
