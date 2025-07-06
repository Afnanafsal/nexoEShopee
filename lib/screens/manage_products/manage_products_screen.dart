import 'package:flutter/material.dart';
import 'package:nexoeshopee/screens/add_product/add_product_screen.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/components/default_button.dart';
import 'package:nexoeshopee/size_config.dart';

class ManageProductsScreen extends StatelessWidget {
  static String routeName = "/manage_products";

  const ManageProductsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Products"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          );
        },
        label: Text("Add Product"),
        icon: Icon(Icons.add),
      ),
      body: ProductsList(),
    );
  }
}

class ProductsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: ProductDatabaseHelper().usersProductsList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 100, color: kPrimaryColor),
                SizedBox(height: 20),
                Text(
                  'No products yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Start by adding your first product'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(getProportionateScreenWidth(10)),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return FutureBuilder<Product?>(
              future: ProductDatabaseHelper().getProductWithID(snapshot.data![index]),
              builder: (context, productSnapshot) {
                if (!productSnapshot.hasData || productSnapshot.data == null) {
                  return SizedBox.shrink();
                }

                final product = productSnapshot.data!;
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: product.images != null && product.images!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              Uri.parse(product.images![0]).data!.contentAsBytes(),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.image_not_supported, color: kPrimaryColor),
                          ),
                    title: Text(
                      product.title ?? 'Untitled Product',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          'Price: \$${product.discountPrice ?? product.originalPrice ?? 0}',
                          style: TextStyle(color: kPrimaryColor),
                        ),
                        Text(
                          'Category: ${product.productType?.toString().split('.').last ?? 'Uncategorized'}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete', style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddProductScreen(productToEdit: product),
                            ),
                          );
                        } else if (value == 'delete') {
                          // Show confirmation dialog
                          final confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Product'),
                              content: Text('Are you sure you want to delete this product?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await ProductDatabaseHelper().deleteUserProduct(product.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Product deleted successfully')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete product')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
