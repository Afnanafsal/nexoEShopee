import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexoeshopee/components/async_progress_dialog.dart';
import 'package:nexoeshopee/components/default_button.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../../size_config.dart';

class ChangePhoneNumberForm extends StatefulWidget {
  const ChangePhoneNumberForm({required Key key}) : super(key: key);

  @override
  _ChangePhoneNumberFormState createState() => _ChangePhoneNumberFormState();
}

class _ChangePhoneNumberFormState extends State<ChangePhoneNumberForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController newPhoneNumberController =
      TextEditingController();

  @override
  void dispose() {
    newPhoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        color: const Color(0xFFF7F8FA),
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Logo
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Shadows Into Light Two',
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
                children: const [
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
            const SizedBox(height: 80),
            Center(
              child: Container(
                width: 380,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Current Phone Number",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Current phone number field (masked)
                      StreamBuilder<DocumentSnapshot>(
                        stream: UserDatabaseHelper().currentUserDataStream,
                        builder: (context, snapshot) {
                          String currentPhone = "";
                          if (snapshot.hasData && snapshot.data != null) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            currentPhone =
                                data?[UserDatabaseHelper.PHONE_KEY] ?? "";
                          }
                          String masked = currentPhone.isNotEmpty
                              ? ("*" * (currentPhone.length - 2)) +
                                    currentPhone.substring(
                                      currentPhone.length - 2,
                                    )
                              : "**********";
                          return Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              masked,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "New Phone Number",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: newPhoneNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          hintText: 'Enter new phone number',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Phone Number cannot be empty";
                          } else if (value.length != 10) {
                            return "Only 10 digits allowed";
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 220,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34495E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final updateFuture =
                                  updatePhoneNumberButtonCallback();
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AsyncProgressDialog(
                                    updateFuture,
                                    message: const Text(
                                      "Updating Phone Number",
                                    ),
                                  );
                                },
                              );
                            },
                            child: const Text(
                              "Update",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updatePhoneNumberButtonCallback() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      bool status = false;
      String snackbarMessage = "";
      try {
        status = await UserDatabaseHelper().updatePhoneForCurrentUser(
          newPhoneNumberController.text,
        );
        if (status == true) {
          snackbarMessage = "Phone updated successfully";
        } else {
          throw "Coulnd't update phone due to unknown reason";
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
}
