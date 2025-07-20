import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:nexoeshopee/components/default_button.dart';
import 'package:nexoeshopee/exceptions/local_files_handling/local_file_handling_exception.dart';
import 'package:nexoeshopee/models/Product.dart';
import 'package:nexoeshopee/screens/edit_product/provider_models/ProductDetails.dart';
import 'package:nexoeshopee/services/database/product_database_helper.dart';
import 'package:nexoeshopee/services/base64_image_service/base64_image_service.dart';
import 'package:nexoeshopee/services/local_files_access/local_files_access_service.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../size_config.dart';

class EditProductForm extends ConsumerStatefulWidget {
  final Product? product;
  const EditProductForm({Key? key, this.product}) : super(key: key);

  @override
  ConsumerState<EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends ConsumerState<EditProductForm> {
  final _basicDetailsFormKey = GlobalKey<FormState>();
  final _describeProductFormKey = GlobalKey<FormState>();

  final TextEditingController titleFieldController = TextEditingController();
  final TextEditingController variantFieldController = TextEditingController();
  final TextEditingController discountPriceFieldController =
      TextEditingController();
  final TextEditingController originalPriceFieldController =
      TextEditingController();
  final TextEditingController highlightsFieldController =
      TextEditingController();
  final TextEditingController desciptionFieldController =
      TextEditingController();
  final TextEditingController sellerFieldController = TextEditingController();

  bool newProduct = true;
  late Product product;

  @override
  void dispose() {
    titleFieldController.dispose();
    variantFieldController.dispose();
    discountPriceFieldController.dispose();
    originalPriceFieldController.dispose();
    highlightsFieldController.dispose();
    desciptionFieldController.dispose();
    sellerFieldController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.product == null) {
      product = Product('');
      newProduct = true;
    } else {
      product = widget.product!;
      newProduct = false;

      // Initialize form fields with existing product data
      titleFieldController.text = product.title ?? '';
      variantFieldController.text = product.variant ?? '';
      originalPriceFieldController.text =
          product.originalPrice?.toString() ?? '';
      discountPriceFieldController.text =
          product.discountPrice?.toString() ?? '';
      highlightsFieldController.text = product.highlights ?? '';
      desciptionFieldController.text = product.description ?? '';
      sellerFieldController.text = product.seller ?? '';
    }

    // Note: ProductDetails provider is now initialized in EditProductScreen
  }

  @override
  Widget build(BuildContext context) {
    final column = Column(
      children: [
        buildBasicDetailsTile(context),
        SizedBox(height: getProportionateScreenHeight(10)),
        buildDescribeProductTile(context),
        SizedBox(height: getProportionateScreenHeight(10)),
        buildUploadImagesTile(context),
        SizedBox(height: getProportionateScreenHeight(20)),
        buildProductTypeDropdown(),
        SizedBox(height: getProportionateScreenHeight(20)),
        SizedBox(height: getProportionateScreenHeight(80)),
        DefaultButton(
          text: "Save Product",
          press: () {
            saveProductButtonCallback(context);
          },
        ),
        SizedBox(height: getProportionateScreenHeight(10)),
      ],
    );
    if (newProduct == false) {
      titleFieldController.text = product.title!;
      variantFieldController.text = product.variant!;
      discountPriceFieldController.text = product.discountPrice.toString();
      originalPriceFieldController.text = product.originalPrice.toString();
      highlightsFieldController.text = product.highlights!;
      desciptionFieldController.text = product.description!;
      sellerFieldController.text = product.seller!;
    }
    return column;
  }

  Widget buildBasicDetailsTile(BuildContext context) {
    return Form(
      key: _basicDetailsFormKey,
      child: ExpansionTile(
        maintainState: true,
        title: Text(
          "Basic Details",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: Icon(Icons.shop),
        childrenPadding: EdgeInsets.symmetric(
          vertical: getProportionateScreenHeight(20),
        ),
        children: [
          buildTitleField(),
          SizedBox(height: getProportionateScreenHeight(20)),
          buildVariantField(),
          SizedBox(height: getProportionateScreenHeight(20)),
          buildOriginalPriceField(),
          SizedBox(height: getProportionateScreenHeight(20)),
          buildDiscountPriceField(),
          SizedBox(height: getProportionateScreenHeight(20)),
          buildSellerField(),
          SizedBox(height: getProportionateScreenHeight(20)),
        ],
      ),
    );
  }

  bool validateBasicDetailsForm() {
    if (_basicDetailsFormKey.currentState!.validate()) {
      _basicDetailsFormKey.currentState!.save();
      product.title = titleFieldController.text;
      product.variant = variantFieldController.text;
      product.originalPrice = double.parse(originalPriceFieldController.text);
      product.discountPrice = double.parse(discountPriceFieldController.text);
      product.seller = sellerFieldController.text;
      return true;
    }
    return false;
  }

  Widget buildDescribeProductTile(BuildContext context) {
    return Form(
      key: _describeProductFormKey,
      child: ExpansionTile(
        maintainState: true,
        title: Text(
          "Describe Product",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: Icon(Icons.description),
        childrenPadding: EdgeInsets.symmetric(
          vertical: getProportionateScreenHeight(20),
        ),
        children: [
          buildHighlightsField(),
          SizedBox(height: getProportionateScreenHeight(20)),
          buildDescriptionField(),
          SizedBox(height: getProportionateScreenHeight(20)),
        ],
      ),
    );
  }

  bool validateDescribeProductForm() {
    if (_describeProductFormKey.currentState!.validate()) {
      _describeProductFormKey.currentState!.save();
      product.highlights = highlightsFieldController.text;
      product.description = desciptionFieldController.text;
      return true;
    }
    return false;
  }

  Widget buildProductTypeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: kTextColor, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Consumer(
        builder: (context, ref, child) {
          final productDetailsState = ref.watch(productDetailsProvider);
          final productDetailsNotifier = ref.read(
            productDetailsProvider.notifier,
          );
          return DropdownButton(
            value: productDetailsState.productType,
            items: ProductType.values
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(EnumToString.convertToString(e)),
                  ),
                )
                .toList(),
            hint: Text("Chose Product Type"),
            style: TextStyle(color: kTextColor, fontSize: 16),
            onChanged: (value) {
              productDetailsNotifier.setProductType(value!);
            },
            elevation: 0,
            underline: SizedBox(width: 0, height: 0),
          );
        },
      ),
    );
  }

  Widget buildUploadImagesTile(BuildContext context) {
    return ExpansionTile(
      title: Text(
        "Upload Images",
        style: Theme.of(context).textTheme.titleLarge,
      ),
      leading: Icon(Icons.image),
      childrenPadding: EdgeInsets.symmetric(
        vertical: getProportionateScreenHeight(20),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: IconButton(
            icon: Icon(Icons.add_a_photo),
            color: kTextColor,
            onPressed: () {
              addImageButtonCallback(index: null);
            },
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final productDetailsState = ref.watch(productDetailsProvider);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(
                  productDetailsState.selectedImages.length,
                  (index) => SizedBox(
                    width: 80,
                    height: 80,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: GestureDetector(
                        onTap: () {
                          addImageButtonCallback(index: index);
                        },
                        child:
                            productDetailsState.selectedImages[index].imgType ==
                                ImageType.local
                            ? kIsWeb
                                  ? (productDetailsState
                                                .selectedImages[index]
                                                .xFile !=
                                            null
                                        ? FutureBuilder<Uint8List>(
                                            future: productDetailsState
                                                .selectedImages[index]
                                                .xFile!
                                                .readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Image.memory(
                                                  snapshot.data!,
                                                );
                                              } else {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: Icon(
                                                    Icons.image,
                                                    color: Colors.grey[600],
                                                  ),
                                                );
                                              }
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.image,
                                              color: Colors.grey[600],
                                            ),
                                          ))
                                  : Image.file(
                                      File(
                                        productDetailsState
                                            .selectedImages[index]
                                            .path,
                                      ),
                                    )
                            : Base64ImageService().base64ToImage(
                                productDetailsState.selectedImages[index].path,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget buildTitleField() {
    return TextFormField(
      controller: titleFieldController,
      keyboardType: TextInputType.name,
      decoration: InputDecoration(
        hintText: "e.g., Fresh Rohu Fish 1kg",
        labelText: "Product Title",
        prefixIcon: Icon(Icons.shopping_bag),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (titleFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildVariantField() {
    return TextFormField(
      controller: variantFieldController,
      keyboardType: TextInputType.name,
      decoration: InputDecoration(
        hintText: "e.g., Large Size, Boneless",
        labelText: "Variant",
        prefixIcon: Icon(Icons.category),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (variantFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildHighlightsField() {
    return TextFormField(
      controller: highlightsFieldController,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: "e.g., Wild caught | Cleaned & gutted | Rich in Omega-3",
        labelText: "Highlights",
        prefixIcon: Icon(Icons.star),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (highlightsFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      maxLines: null,
    );
  }

  Widget buildDescriptionField() {
    return TextFormField(
      controller: desciptionFieldController,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText:
            "e.g., Fresh Rohu fish sourced from local waters. Cleaned, gutted, and packed hygienically. Perfect for curries and fries.",
        labelText: "Description",
        prefixIcon: Icon(Icons.description),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (desciptionFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      maxLines: null,
    );
  }

  Widget buildSellerField() {
    return TextFormField(
      controller: sellerFieldController,
      keyboardType: TextInputType.name,
      decoration: InputDecoration(
        hintText: "e.g., FreshFish Mart",
        labelText: "Seller",
        prefixIcon: Icon(Icons.store),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (sellerFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildOriginalPriceField() {
    return TextFormField(
      controller: originalPriceFieldController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "e.g., 499.0",
        labelText: "Original Price (in INR)",
        prefixIcon: Icon(Icons.price_change),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (originalPriceFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget buildDiscountPriceField() {
    return TextFormField(
      controller: discountPriceFieldController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "e.g., 399.0",
        labelText: "Discount Price (in INR)",
        prefixIcon: Icon(Icons.discount),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      validator: (_) {
        if (discountPriceFieldController.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Future<void> saveProductButtonCallback(BuildContext context) async {
    if (validateBasicDetailsForm() == false) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erros in Basic Details Form")));
      return;
    }
    if (validateDescribeProductForm() == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errors in Describe Product Form")),
      );
      return;
    }
    final productDetailsState = ref.read(productDetailsProvider);
    final productDetailsNotifier = ref.read(productDetailsProvider.notifier);
    if (productDetailsState.selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload atleast One Image of Product")),
      );
      return;
    }
    if (productDetailsState.productType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select Product Type")));
      return;
    }
    String? productId;
    String snackbarMessage = "";
    try {
      product.productType = productDetailsState.productType;
      final productUploadFuture = newProduct
          ? ProductDatabaseHelper().addUsersProduct(product)
          : ProductDatabaseHelper().updateUsersProduct(product);
      productId = await showDialog(
        context: context,
        builder: (context) {
          return AsyncProgressDialog(
            productUploadFuture,
            message: Text(
              newProduct ? "Uploading Product" : "Updating Product",
            ),
          );
        },
      );
      if (productId != null) {
        snackbarMessage = "Product Info updated successfully";
      } else {
        throw "Couldn't update product info due to some unknown issue";
      }
    } on FirebaseException catch (e) {
      Logger().w("Firebase Exception: $e");
      snackbarMessage = "Something went wrong";
    } catch (e) {
      Logger().w("Unknown Exception: $e");
      snackbarMessage = e.toString();
    } finally {
      Logger().i(snackbarMessage);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }
    if (productId == null) return;
    bool allImagesUploaded = false;
    try {
      allImagesUploaded = await uploadProductImages(productId);
      if (allImagesUploaded) {
        snackbarMessage = "All images uploaded successfully";
      } else {
        throw "Some images couldn't be uploaded, please try again";
      }
    } on FirebaseException catch (e) {
      Logger().w("Firebase Exception: $e");
      snackbarMessage = "Something went wrong";
    } catch (e) {
      Logger().w("Unknown Exception: $e");
      snackbarMessage = "Something went wrong";
    } finally {
      Logger().i(snackbarMessage);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }
    List<String> base64Images = productDetailsState.selectedImages
        .map((e) => e.imgType == ImageType.network ? e.path : e.path)
        .toList();
    bool productFinalizeUpdate = false;
    try {
      final updateProductFuture = ProductDatabaseHelper().updateProductsImages(
        productId,
        base64Images,
      );
      productFinalizeUpdate = await showDialog(
        context: context,
        builder: (context) {
          return AsyncProgressDialog(
            updateProductFuture,
            message: Text("Saving Product"),
          );
        },
      );
      if (productFinalizeUpdate) {
        snackbarMessage = "Product uploaded successfully";
      } else {
        throw "Couldn't upload product properly, please retry";
      }
    } on FirebaseException catch (e) {
      Logger().w("Firebase Exception: $e");
      snackbarMessage = "Something went wrong";
    } catch (e) {
      Logger().w("Unknown Exception: $e");
      snackbarMessage = e.toString();
    } finally {
      Logger().i(snackbarMessage);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<bool> uploadProductImages(String productId) async {
    bool allImagesUpdated = true;
    final productDetailsState = ref.read(productDetailsProvider);
    final productDetailsNotifier = ref.read(productDetailsProvider.notifier);
    for (int i = 0; i < productDetailsState.selectedImages.length; i++) {
      if (productDetailsState.selectedImages[i].imgType == ImageType.local) {
        Logger().i(
          "Image being processed: ${productDetailsState.selectedImages[i].path}",
        );
        String? base64Image;
        try {
          // Convert image to base64 - use XFile when available
          if (productDetailsState.selectedImages[i].xFile != null) {
            // Use XFile for conversion (works on all platforms)
            base64Image = await Base64ImageService().xFileToBase64(
              productDetailsState.selectedImages[i].xFile!,
            );
          } else {
            // Fallback to file path method
            if (kIsWeb) {
              Logger().w("No XFile available for web image, skipping");
              base64Image = null;
            } else {
              // On mobile platforms, use File normally
              final file = File(productDetailsState.selectedImages[i].path);
              base64Image = await Base64ImageService().fileToBase64(file);
            }
          }
        } catch (e) {
          Logger().w("Error converting image to base64: $e");
        } finally {
          if (base64Image != null) {
            productDetailsNotifier.setSelectedImageAtIndex(
              CustomImage(imgType: ImageType.network, path: base64Image),
              i,
            );
          } else {
            allImagesUpdated = false;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Couldn't process image ${i + 1} due to some issue",
                  ),
                ),
              );
            }
          }
        }
      }
    }
    return allImagesUpdated;
  }

  Future<void> addImageButtonCallback({int? index}) async {
    final productDetailsState = ref.read(productDetailsProvider);
    final productDetailsNotifier = ref.read(productDetailsProvider.notifier);
    if (index == null && productDetailsState.selectedImages.length >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Max 3 images can be uploaded")));
      }
      return;
    }
    ImagePickResult? result;
    String snackbarMessage = '';
    try {
      result = await choseImageFromLocalFiles(context);
    } on LocalFileHandlingException catch (e) {
      Logger().i("Local File Handling Exception: $e");
      snackbarMessage = e.toString();
    } catch (e) {
      Logger().i("Unknown Exception: $e");
      snackbarMessage = e.toString();
    } finally {
      if (snackbarMessage.isNotEmpty) {
        Logger().i(snackbarMessage);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
        }
      }
    }
    if (result == null) {
      return;
    }
    if (index == null) {
      productDetailsNotifier.addNewSelectedImage(
        CustomImage(
          imgType: ImageType.local,
          path: result.path,
          xFile: result.xFile,
        ),
      );
    } else {
      productDetailsNotifier.setSelectedImageAtIndex(
        CustomImage(
          imgType: ImageType.local,
          path: result.path,
          xFile: result.xFile,
        ),
        index,
      );
    }
  }
}
