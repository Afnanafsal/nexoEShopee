import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexoeshopee/components/default_button.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/size_config.dart';

class AddProductScreen extends StatefulWidget {
  final Product? productToEdit;

  const AddProductScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  List<String> _images = [];
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  ProductType _selectedType = ProductType.Others;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product data if editing
    _titleController = TextEditingController(text: widget.productToEdit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.productToEdit?.description ?? '');
    _priceController = TextEditingController(text: widget.productToEdit?.originalPrice?.toString() ?? '');
    _discountPriceController = TextEditingController(text: widget.productToEdit?.discountPrice?.toString() ?? '');
    
    if (widget.productToEdit != null) {
      _images = widget.productToEdit!.images ?? [];
      _selectedType = widget.productToEdit!.productType ?? ProductType.Others;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum 3 images allowed')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() {
        _images.add(base64Image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }


  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one product image')),
      );
      return;
    }

    try {
      final product = Product(
        widget.productToEdit?.id ?? '',
        images: _images,
        title: _titleController.text,
        description: _descriptionController.text,
        originalPrice: double.parse(_priceController.text),
        discountPrice: _discountPriceController.text.isNotEmpty 
            ? double.parse(_discountPriceController.text)
            : null,
        productType: _selectedType,
        rating: widget.productToEdit?.rating ?? 0.0,
      );

      if (widget.productToEdit == null) {
        // Add new product
        await ProductDatabaseHelper().addUsersProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added successfully')),
        );
      } else {
        // Update existing product
        await ProductDatabaseHelper().updateUsersProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product updated successfully')),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving product: $e')),
      );
    }
  }



  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Images', style: headingStyle),
        SizedBox(height: 10),
        Container(
          height: 120,
          child: Row(
            children: [
              ...List.generate(_images.length, (index) {
                return Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(
                            Uri.parse(_images[index]).data!.contentAsBytes(),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeImage(index),
                      ),
                    ),
                  ],
                );
              }),
              if (_images.length < 3)
                InkWell(
                  onTap: _addImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_photo_alternate, color: kPrimaryColor),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Product Title',
        hintText: 'Enter product title',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter product title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Enter product description',
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter product description';
        }
        return null;
      },
    );
  }

  Widget _buildPriceFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'Original Price',
              hintText: 'Enter price',
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter price';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter valid price';
              }
              return null;
            },
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: TextFormField(
            controller: _discountPriceController,
            decoration: InputDecoration(
              labelText: 'Discount Price (Optional)',
              hintText: 'Enter discount price',
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (double.tryParse(value) == null) {
                  return 'Please enter valid price';
                }
                if (double.parse(value) >= double.parse(_priceController.text)) {
                  return 'Discount price should be less than original price';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductTypeDropdown() {
    return DropdownButtonFormField<ProductType>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'Product Category',
      ),
      items: ProductType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.toString().split('.').last),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedType = value!;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productToEdit != null ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(getProportionateScreenWidth(20)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              SizedBox(height: getProportionateScreenHeight(20)),
              _buildTitleField(),
              SizedBox(height: getProportionateScreenHeight(20)),
              _buildDescriptionField(),
              SizedBox(height: getProportionateScreenHeight(20)),
              _buildPriceFields(),
              SizedBox(height: getProportionateScreenHeight(20)),
              _buildProductTypeDropdown(),
              SizedBox(height: getProportionateScreenHeight(30)),
              DefaultButton(
                text: widget.productToEdit != null ? 'Update Product' : 'Add Product',
                press: _saveProduct,
              ),
              SizedBox(height: getProportionateScreenHeight(20)),
            ],
          ),
        ),
      ),
    );
  }
}
