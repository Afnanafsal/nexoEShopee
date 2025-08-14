import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fishkart/components/default_button.dart';
import 'package:fishkart/models/Address.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/size_config.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:string_validator/string_validator.dart';
import '../../../constants.dart';

class AddressDetailsForm extends StatefulWidget {
  final Address? addressToEdit;
  AddressDetailsForm({Key? key, this.addressToEdit}) : super(key: key);

  @override
  _AddressDetailsFormState createState() => _AddressDetailsFormState();
}

class _AddressDetailsFormState extends State<AddressDetailsForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleFieldController = TextEditingController();

  final TextEditingController receiverFieldController = TextEditingController();

  final TextEditingController addressLine1FieldController =
      TextEditingController();

  final TextEditingController addressLine2FieldController =
      TextEditingController();

  final TextEditingController cityFieldController = TextEditingController();

  final TextEditingController districtFieldController = TextEditingController();

  final TextEditingController stateFieldController = TextEditingController();

  final TextEditingController landmarkFieldController = TextEditingController();

  final TextEditingController pincodeFieldController = TextEditingController();

  final TextEditingController phoneFieldController = TextEditingController();

  @override
  void dispose() {
    titleFieldController.dispose();
    receiverFieldController.dispose();
    addressLine1FieldController.dispose();
    addressLine2FieldController.dispose();
    cityFieldController.dispose();
    stateFieldController.dispose();
    districtFieldController.dispose();
    landmarkFieldController.dispose();
    pincodeFieldController.dispose();
    phoneFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: _formKey,
      child: Column(
        children: [
          SizedBox(height: getProportionateScreenHeight(5)),
          buildTitleField(),
          SizedBox(height: getProportionateScreenHeight(15)),
          buildReceiverField(),
          SizedBox(height: getProportionateScreenHeight(15)),
          buildAddressLine1Field(),
          SizedBox(height: getProportionateScreenHeight(15)),
          buildAddressLine2Field(),
          SizedBox(height: getProportionateScreenHeight(15)),
          buildCityField(),
          SizedBox(height: getProportionateScreenHeight(15)),
          buildDistrictField(),
          SizedBox(height: getProportionateScreenHeight(15)),
          buildStateField(),
          SizedBox(height: getProportionateScreenHeight(15)),
          buildLandmarkField(),
          SizedBox(height: getProportionateScreenHeight(15)),
          buildPincodeField(),
          SizedBox(height: getProportionateScreenHeight(15)),
          buildPhoneField(),
          SizedBox(height: getProportionateScreenHeight(15)),
          DefaultButton(
            text: "Save Address",
            press: widget.addressToEdit == null
                ? saveNewAddressButtonCallback
                : saveEditedAddressButtonCallback,
          ),
        ],
      ),
    );
    if (widget.addressToEdit != null) {
      titleFieldController.text = widget.addressToEdit!.title!;
      receiverFieldController.text = widget.addressToEdit!.receiver!;
      addressLine1FieldController.text = widget.addressToEdit!.addressLine1!;
      addressLine2FieldController.text = widget.addressToEdit!.addressLine2!;
      cityFieldController.text = widget.addressToEdit!.city!;
      districtFieldController.text = widget.addressToEdit!.district!;
      stateFieldController.text = widget.addressToEdit!.state!;
      landmarkFieldController.text = widget.addressToEdit!.landmark!;
      pincodeFieldController.text = widget.addressToEdit!.pincode!;
      phoneFieldController.text = widget.addressToEdit!.phone!;
    }
    return form;
  }

  Widget buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Title"),
        SizedBox(height: 5),
        _buildInput(
          titleFieldController,
          "Enter a title for address",
          maxLength: 8,
        ),
      ],
    );
  }

  Widget buildReceiverField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Receiver Name"),
        SizedBox(height: 5),
        _buildInput(receiverFieldController, "Enter Full Name of Receiver"),
      ],
    );
  }

  Widget buildAddressLine1Field() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Address Line 1"),
        SizedBox(height: 5),
        _buildInput(addressLine1FieldController, "Enter Address Line No. 1"),
      ],
    );
  }

  Widget buildAddressLine2Field() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Address Line 2"),
        SizedBox(height: 5),
        _buildInput(addressLine2FieldController, "Enter Address Line No. 2"),
      ],
    );
  }

  Widget buildCityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("City"),
        SizedBox(height: 5),
        _buildInput(cityFieldController, "Enter City"),
      ],
    );
  }

  Widget buildDistrictField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("District"),
        SizedBox(height: 5),
        _buildInput(districtFieldController, "Enter District"),
      ],
    );
  }

  Widget buildStateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("State"),
        SizedBox(height: 5),
        _buildInput(stateFieldController, "Enter State"),
      ],
    );
  }

  Widget buildPincodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("PINCODE"),
        SizedBox(height: 5),
        _buildInput(
          pincodeFieldController,
          "Enter PINCODE",
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget buildLandmarkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Landmark"),
        SizedBox(height: 5),
        _buildInput(landmarkFieldController, "Enter Landmark"),
      ],
    );
  }

  Widget buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Phone Number"),
        SizedBox(height: 5),
        _buildInput(
          phoneFieldController,
          "Enter Phone Number",
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.black,
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint, {
    bool enabled = true,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black54, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        // Keep original validation logic
        if (controller == titleFieldController && controller.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        if (controller == receiverFieldController && controller.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        if (controller == addressLine1FieldController &&
            controller.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        if (controller == addressLine2FieldController &&
            controller.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        if (controller == cityFieldController && controller.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        if (controller == districtFieldController && controller.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        if (controller == stateFieldController && controller.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        if (controller == landmarkFieldController && controller.text.isEmpty) {
          return FIELD_REQUIRED_MSG;
        }
        if (controller == pincodeFieldController) {
          if (controller.text.isEmpty) {
            return FIELD_REQUIRED_MSG;
          } else if (!isNumeric(controller.text)) {
            return "Only digits field";
          } else if (controller.text.length != 6) {
            return "PINCODE must be of 6 Digits only";
          }
        }
        if (controller == phoneFieldController) {
          if (controller.text.isEmpty) {
            return FIELD_REQUIRED_MSG;
          } else if (controller.text.length != 10) {
            return "Only 10 Digits";
          }
        }
        return null;
      },
    );
  }

  Future<void> saveNewAddressButtonCallback() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final Address newAddress = generateAddressObject(
        id: UniqueKey().toString(),
      );
      bool status = false;
      String snackbarMessage = "";
      try {
        status = await UserDatabaseHelper().addAddressForCurrentUser(
          newAddress,
        );
        if (!mounted) return;
        if (status == true) {
          snackbarMessage = "Address saved successfully";
          Navigator.of(context).pop(true); // Go back and trigger refresh
        } else {
          throw "Coundn't save the address due to unknown reason";
        }
      } on FirebaseException catch (e) {
        Logger().w("Firebase Exception: $e");
        snackbarMessage = "Something went wrong";
      } catch (e) {
        Logger().w("Unknown Exception: $e");
        snackbarMessage = "Something went wrong";
      } finally {
        if (!mounted) return;
        Logger().i(snackbarMessage);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }
  }

  Future<void> saveEditedAddressButtonCallback() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final Address newAddress = generateAddressObject(
        id: widget.addressToEdit!.id,
      );

      bool status = false;
      String snackbarMessage = "";
      try {
        status = await UserDatabaseHelper().updateAddressForCurrentUser(
          newAddress,
        );
        if (!mounted) return;
        if (status == true) {
          snackbarMessage = "Address updated successfully";
          Navigator.of(context).pop(true); // Go back and trigger refresh
        } else {
          throw "Couldn't update address due to unknown reason";
        }
      } on FirebaseException catch (e) {
        Logger().w("Firebase Exception: $e");
        snackbarMessage = "Something went wrong";
      } catch (e) {
        Logger().w("Unknown Exception: $e");
        snackbarMessage = "Something went wrong";
      } finally {
        if (!mounted) return;
        Logger().i(snackbarMessage);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
    }
  }

  Address generateAddressObject({required String id}) {
    return Address(
      id: id,
      title: titleFieldController.text,
      receiver: receiverFieldController.text,
      addressLine1: addressLine1FieldController.text,
      addressLine2: addressLine2FieldController.text,
      city: cityFieldController.text,
      district: districtFieldController.text,
      state: stateFieldController.text,
      landmark: landmarkFieldController.text,
      pincode: pincodeFieldController.text,
      phone: phoneFieldController.text,
    );
  }
}
