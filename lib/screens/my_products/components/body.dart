import 'package:flutter/material.dart';
import 'package:fishkart/screens/edit_product/edit_product_screen.dart';
import 'package:fishkart/screens/manage_products/manage_products_screen.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ManageProductsScreen(key: UniqueKey());
  }
}
