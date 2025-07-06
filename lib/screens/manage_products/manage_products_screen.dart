import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nexoeshopee/screens/add_product/add_product_screen.dart';
import 'package:nexoeshopee/screens/edit_product/edit_product_screen.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/components/default_button.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexoeshopee/services/authentification/authentification_service.dart';
import 'package:nexoeshopee/services/base64_image_service/base64_image_service.dart';

class ManageProductsScreen extends StatelessWidget {
  static String routeName = "/manage_products";

  const ManageProductsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Products"),
        automaticallyImplyLeading: false,
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
  final base64Service = Base64ImageService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(ProductDatabaseHelper.PRODUCTS_COLLECTION_NAME)
          .where(Product.OWNER_KEY, isEqualTo: AuthentificationService().currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

        final products = snapshot.data!.docs.map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return Product.fromMap(data, id: doc.id);
          } catch (e) {
            print('Error parsing product ${doc.id}: $e');
            return null;
          }
        }).where((product) => product != null).cast<Product>().toList();

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 100, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'Error loading products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('There was an error loading your products'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(getProportionateScreenWidth(10)),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              elevation: 2,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Builder(
                  builder: (context) {
                    if (product.images == null || product.images!.isEmpty) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.image_not_supported, color: kPrimaryColor),
                      );
                    }
                    
                    try {
                      final base64Image = product.images![0];
                      // Remove data URI prefix if present
                      final imageData = base64Image.startsWith('data:image') 
                          ? base64Image.split(',')[1]
                          : base64Image;
                      
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(imageData),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.broken_image, color: kPrimaryColor),
                            );
                          },
                        ),
                      );
                    } catch (e) {
                      print('Error loading image: $e');
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.error, color: kPrimaryColor),
                      );
                    }
                  },
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
                          builder: (context) => EditProductScreen(productToEdit: product),
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
  }
}
