import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/edit_product/provider_models/ProductDetails.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'components/body.dart';

class EditProductScreen extends StatelessWidget {
  final Product? productToEdit;

  const EditProductScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final details = ProductDetails();
        // Initialize product details if editing
        if (productToEdit != null) {
          details.initialSelectedImages = productToEdit!.images?.map((e) => 
            CustomImage(imgType: ImageType.network, path: e)).toList() ?? [];
          details.initialProductType = productToEdit!.productType ?? ProductType.Others;
          details.initSearchTags = productToEdit!.searchTags ?? [];
        }
        return details;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(productToEdit == null ? 'Add Product' : 'Edit Product'),
        ),
        body: Body(
          key: UniqueKey(),
          productToEdit: productToEdit,
        ),
      ),
    );
  }
}
