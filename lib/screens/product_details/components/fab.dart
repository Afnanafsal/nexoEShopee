import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/providers/user_providers.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
//import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:logger/logger.dart';

import '../../../utils.dart';

class AddToCartFAB extends ConsumerWidget {
  const AddToCartFAB({required this.key, required this.productId})
    : super(key: key);

  final Key key;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () async {
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
        final selectedAddressId = ref.read(selectedAddressIdProvider);
        if (selectedAddressId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Please select a delivery address before adding to cart.",
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        bool addedSuccessfully = false;
        String snackbarMessage = "";
        try {
          addedSuccessfully = await UserDatabaseHelper().addProductToCart(
            productId,
            addressId: selectedAddressId,
          );
          if (addedSuccessfully == true) {
            String addressMsg = " for address: $selectedAddressId";
            snackbarMessage = "Product added successfully" + addressMsg;
          } else {
            throw "Coulnd't add product due to unknown reason";
          }
        } on FirebaseException catch (e) {
          Logger().w("Firebase Exception: $e");
          snackbarMessage = "Something went wrong";
        } catch (e) {
          Logger().w("Unknown Exception: $e");
          snackbarMessage = "Something went wrong";
        } finally {
          Logger().i(snackbarMessage);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
        }
      },
      label: Text(
        "Add to Cart",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      icon: const Icon(Icons.shopping_cart),
    );
  }
}
