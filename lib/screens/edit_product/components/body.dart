import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:flutter/material.dart';

import 'edit_product_form.dart';

class Body extends StatelessWidget {
  final Product? productToEdit;

  const Body({Key? key, this.productToEdit}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(screenPadding),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(height: getProportionateScreenHeight(10)),
                Text("Fill Product Details", style: headingStyle),
                SizedBox(height: getProportionateScreenHeight(30)),
                EditProductForm(
                  product: productToEdit,
                ),
                SizedBox(height: getProportionateScreenHeight(30)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
