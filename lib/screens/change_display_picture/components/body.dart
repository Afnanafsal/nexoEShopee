import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:nexoeshopee/components/default_button.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/exceptions/local_files_handling/local_file_handling_exception.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/services/base64_image_service/base64_image_service.dart';
import 'package:nexoeshopee/services/local_files_access/local_files_access_service.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:nexoeshopee/providers/image_providers.dart';

class Body extends ConsumerStatefulWidget {
  const Body({Key? key}) : super(key: key);
  @override
  ConsumerState<Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<Body> {
  Uint8List? _chosenImageBytes;

  @override
  void initState() {
    super.initState();
    final userBox = Hive.box('user_box');
    String cachedBase64 = userBox.get('profile_picture') ?? '';
    if (cachedBase64.isNotEmpty) {
      _chosenImageBytes = Base64ImageService().base64ToBytes(cachedBase64);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (_chosenImageBytes != null) {
      avatar = CircleAvatar(
        radius: SizeConfig.screenWidth * 0.3,
        backgroundColor: kTextColor.withOpacity(0.5),
        backgroundImage: MemoryImage(_chosenImageBytes!),
      );
    } else {
      avatar = CircleAvatar(
        radius: SizeConfig.screenWidth * 0.3,
        backgroundColor: kTextColor.withOpacity(0.5),
        child: Icon(
          Icons.person,
          size: SizeConfig.screenWidth * 0.2,
          color: kTextColor.withOpacity(0.5),
        ),
      );
    }

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
                Text("Change Avatar", style: headingStyle),
                SizedBox(height: getProportionateScreenHeight(40)),
                GestureDetector(
                  child: avatar,
                  onTap: () {
                    getImageFromUser(context, ref);
                  },
                ),
                SizedBox(height: getProportionateScreenHeight(80)),
                buildChosePictureButton(context, ref),
                SizedBox(height: getProportionateScreenHeight(20)),
                buildUploadPictureButton(context, ref),
                SizedBox(height: getProportionateScreenHeight(20)),
                buildRemovePictureButton(context, ref),
                SizedBox(height: getProportionateScreenHeight(80)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void getImageFromUser(BuildContext context, WidgetRef ref) async {
    ImagePickResult? result;
    String? snackbarMessage;
    try {
      result = await choseImageFromLocalFiles(context);
    } on LocalFileHandlingException catch (e) {
      Logger().i("LocalFileHandlingException: $e");
      snackbarMessage = e.toString();
    } catch (e) {
      Logger().i("LocalFileHandlingException: $e");
      snackbarMessage = e.toString();
    } finally {
      if (snackbarMessage != null) {
        Logger().i(snackbarMessage);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }
    if (result == null) {
      return;
    }
    final bytes = await result.xFile.readAsBytes();
    setState(() {
      _chosenImageBytes = bytes;
    });
    Hive.box('user_box').put('profile_picture', base64Encode(bytes));
    ref.read(chosenImageProvider.notifier).setChosenImage(result.xFile);
  }

  Widget buildChosePictureButton(BuildContext context, WidgetRef ref) {
    return DefaultButton(
      text: "Choose Picture",
      press: () {
        getImageFromUser(context, ref);
      },
    );
  }

  Widget buildUploadPictureButton(BuildContext context, WidgetRef ref) {
    return DefaultButton(
      text: "Upload Picture",
      press: () {
        final Future uploadFuture = uploadImageToFirestorage(context, ref);
        showDialog(
          context: context,
          builder: (context) {
            return AsyncProgressDialog(
              uploadFuture,
              message: Text("Updating Display Picture"),
            );
          },
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Display Picture updated")));
      },
    );
  }

  Future<void> uploadImageToFirestorage(
    BuildContext context,
    WidgetRef ref,
  ) async {
    bool uploadDisplayPictureStatus = false;
    String snackbarMessage = "";
    final chosenImageState = ref.read(chosenImageProvider);

    try {
      if (chosenImageState.chosenImage == null) {
        throw "No image selected to upload.";
      }

      // Convert image to base64
      String base64String = await Base64ImageService().xFileToBase64(
        chosenImageState.chosenImage!,
      );

      uploadDisplayPictureStatus = await UserDatabaseHelper()
          .uploadDisplayPictureForCurrentUser(base64String);
      if (uploadDisplayPictureStatus == true) {
        snackbarMessage = "Display Picture updated successfully";
      } else {
        throw "Coulnd't update display picture due to unknown reason";
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
  }

  Widget buildRemovePictureButton(BuildContext context, WidgetRef ref) {
    return DefaultButton(
      text: "Remove Picture",
      press: () async {
        final Future uploadFuture = removeImageFromFirestorage(context, ref);
        await showDialog(
          context: context,
          builder: (context) {
            return AsyncProgressDialog(
              uploadFuture,
              message: Text("Deleting Display Picture"),
            );
          },
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Display Picture removed")));
        Navigator.pop(context);
      },
    );
  }

  Future<void> removeImageFromFirestorage(
    BuildContext context,
    WidgetRef ref,
  ) async {
    bool status = false;
    String snackbarMessage = "";
    try {
      // Since we're using base64 storage, we just need to remove the reference from the database
      status = await UserDatabaseHelper().removeDisplayPictureForCurrentUser();
      if (status == true) {
        snackbarMessage = "Picture removed successfully";
      } else {
        throw "Coulnd't removed due to unknown reason";
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
  }
}
