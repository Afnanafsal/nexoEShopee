import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:fishkart/components/async_progress_dialog.dart';
import 'package:fishkart/components/default_button.dart';
import 'package:fishkart/constants.dart';
import 'package:fishkart/exceptions/local_files_handling/local_file_handling_exception.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/services/base64_image_service/base64_image_service.dart';
import 'package:fishkart/services/local_files_access/local_files_access_service.dart';
import 'package:fishkart/size_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:fishkart/providers/image_providers.dart';
import 'package:fishkart/screens/profile/profile_screen.dart';

class Body extends ConsumerStatefulWidget {
  const Body({Key? key}) : super(key: key);
  @override
  ConsumerState<Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<Body> {
  Uint8List? _chosenImageBytes;
  String displayName = '';
  late Future<void> _initFuture;

  Future<void> _initHiveAndUser() async {
    if (!Hive.isBoxOpen('user_box')) {
      await Hive.openBox('user_box');
    }
    final userBox = Hive.box('user_box');
    final user = FirebaseAuth.instance.currentUser;
    displayName = user?.displayName ?? 'No Name';

    // Try to fetch image from Firestore
    String? firestoreBase64;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      firestoreBase64 = doc.data()?['profile_picture'] as String?;
    }
    String cachedBase64 = userBox.get('profile_picture') ?? '';
    String? base64ToUse = firestoreBase64?.isNotEmpty == true
        ? firestoreBase64
        : (cachedBase64.isNotEmpty ? cachedBase64 : null);
    if (base64ToUse != null && base64ToUse.isNotEmpty) {
      try {
        // Convert base64 string to Uint8List
        _chosenImageBytes = base64Decode(base64ToUse);
      } catch (e) {
        _chosenImageBytes = null;
      }
    } else {
      _chosenImageBytes = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _initFuture = _initHiveAndUser();
  }

  Future<void> _fetchAndStoreDisplayName(Box userBox) async {
    // No longer needed; fetching from FirebaseAuth
    return;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        Widget avatar = _chosenImageBytes != null
            ? CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: MemoryImage(_chosenImageBytes!),
              )
            : CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.person,
                  size: 80,
                  color: kTextColor.withOpacity(0.3),
                ),
              );
        // ...existing code...
        return SafeArea(
          child: Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 235, 235, 235),
            child: Column(
              children: [
                const SizedBox(height: 80),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Shadows Into Light Two',
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Fish',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextSpan(
                        text: 'Kart',
                        style: TextStyle(color: Color(0xFF29465B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 249, 250, 251),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          child: avatar,
                          onTap: () {
                            getImageFromUser(context, ref);
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: const Color(0xFF527085),
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    side: BorderSide(color: Colors.transparent),
                                  ),
                                  onPressed: () {
                                    getImageFromUser(context, ref);
                                  },
                                  child: const Text(
                                    "Choose Picture",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    side: BorderSide(color: Colors.transparent),
                                  ),
                                  onPressed: () async {
                                    final Future uploadFuture = uploadImageToFirestorage(context, ref);
                                    await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AsyncProgressDialog(
                                          uploadFuture,
                                          message: const Text(
                                            "Updating Display Picture",
                                          ),
                                        );
                                      },
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Display Picture updated"),
                                      ),
                                    );
                                    setState(() {
                                      _initFuture = _initHiveAndUser();
                                    });
                                  },
                                  child: const Text(
                                    "Upload Picture",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    side: BorderSide(color: Colors.transparent),
                                  ),
                                  onPressed: () async {
                                    final Future uploadFuture = removeImageFromFirestorage(context, ref);
                                    await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AsyncProgressDialog(
                                          uploadFuture,
                                          message: const Text(
                                            "Deleting Display Picture",
                                          ),
                                        );
                                      },
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Display Picture removed"),
                                      ),
                                    );
                                    setState(() {
                                      _initFuture = _initHiveAndUser();
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "Remove Picture",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      press: () async {
        final Future uploadFuture = uploadImageToFirestorage(context, ref);
        await showDialog(
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
        await _initHiveAndUser();
        setState(() {});
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
      if (snackbarMessage == "Display Picture updated successfully") {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => ProfileScreen()),
            (route) => false,
          );
        }
      }
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
        await _initHiveAndUser();
        setState(() {});
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
