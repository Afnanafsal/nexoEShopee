import 'package:shimmer/shimmer.dart';
import 'package:nexoeshopee/components/default_button.dart';
import 'package:nexoeshopee/components/nothingtoshow_container.dart';
import 'package:nexoeshopee/constants.dart';
import 'package:nexoeshopee/screens/edit_address/edit_address_screen.dart';
import 'package:nexoeshopee/screens/manage_addresses/components/address_short_details_card.dart';
import 'package:nexoeshopee/services/data_streams/addresses_stream.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/services/cache/hive_service.dart';
import 'package:nexoeshopee/size_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../components/address_box.dart';

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final AddressesStream addressesStream = AddressesStream();

  @override
  void initState() {
    super.initState();
    addressesStream.init();
    addressesStream.reload();
  }

  @override
  void dispose() {
    super.dispose();
    addressesStream.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Try to get cached addresses instantly
    final cachedAddresses = HiveService.instance.getCachedAddresses();
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refreshPage,
        child: Container(
          color: Colors.transparent,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Back button
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Title and subtitle
                  const Text(
                    "Manage Addresses",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Swipe LEFT to edit, swipe Right to delete",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  // Address list (cache-first)
                  if (cachedAddresses.isNotEmpty)
                    Column(
                      children: [
                        ...cachedAddresses
                            .map(
                              (address) =>
                                  buildAddressItemCard(address['id'] as String),
                            )
                            .toList(),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34495E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditAddressScreen(
                                    key: UniqueKey(),
                                    addressIdToEdit: null,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              "Add New Address",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    )
                  else
                    StreamBuilder<List<String>>(
                      stream: addressesStream.stream.cast<List<String>>(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final addresses = snapshot.data;
                          if (addresses!.isEmpty) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                NothingToShowContainer(
                                  iconPath: "assets/icons/add_location.svg",
                                  secondaryMessage: "Add your first Address",
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF34495E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () async {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditAddressScreen(
                                                key: UniqueKey(),
                                                addressIdToEdit: null,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Add New Address",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              ...addresses
                                  .map((id) => buildAddressItemCard(id))
                                  .toList(),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34495E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () async {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditAddressScreen(
                                          key: UniqueKey(),
                                          addressIdToEdit: null,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Add New Address",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        } else if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Column(
                                children: List.generate(
                                  2,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    width: double.infinity,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          final error = snapshot.error;
                          Logger().w(error.toString());
                        }
                        return Center(
                          child: NothingToShowContainer(
                            iconPath: "assets/icons/network_error.svg",
                            primaryMessage: "Something went wrong",
                            secondaryMessage: "Unable to connect to Database",
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> refreshPage() {
    addressesStream.reload();
    return Future<void>.value();
  }

  Future<bool> deleteButtonCallback(
    BuildContext context,
    String addressId,
  ) async {
    final confirmDeletion = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text("Are you sure you want to delete this Address ?"),
          actions: [
            TextButton(
              child: Text("Yes"),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            TextButton(
              child: Text("No"),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );

    if (confirmDeletion) {
      bool status = false;
      String snackbarMessage = "";
      try {
        status = await UserDatabaseHelper().deleteAddressForCurrentUser(
          addressId,
        );
        if (status == true) {
          snackbarMessage = "Address deleted successfully";
        } else {
          throw "Coulnd't delete address due to unknown reason";
        }
      } on FirebaseException catch (e) {
        Logger().w("Firebase Exception: $e");
        snackbarMessage = "Something went wrong";
      } catch (e) {
        Logger().w("Unknown Exception: $e");
        snackbarMessage = e.toString();
      } finally {
        Logger().i(snackbarMessage);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
      }
      await refreshPage();
      return status;
    }
    return false;
  }

  Future<bool> editButtonCallback(
    BuildContext context,
    String addressId,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditAddressScreen(key: Key(addressId), addressIdToEdit: addressId),
      ),
    );
    await refreshPage();
    return false;
  }

  Future<void> addressItemTapCallback(String addressId) async {
    // Only show dialog if there are multiple addresses
    final addresses = await UserDatabaseHelper().addressesList;
    if (addresses.length > 1) {
      await showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            backgroundColor: Colors.transparent,
            title: AddressBox(key: Key(addressId), addressId: addressId),
            titlePadding: EdgeInsets.zero,
          );
        },
      );
    }
    await refreshPage();
  }

  Widget buildAddressItemCard(String addressId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Dismissible(
        key: Key(addressId),
        direction: DismissDirection.horizontal,
        background: buildDismissibleSecondaryBackground(),
        secondaryBackground: buildDismissiblePrimaryBackground(),
        dismissThresholds: {
          DismissDirection.endToStart: 0.65,
          DismissDirection.startToEnd: 0.65,
        },
        child: AddressShortDetailsCard(
          key: Key(addressId),
          addressId: addressId,
          onTap: () async {
            await addressItemTapCallback(addressId);
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, color: Colors.grey[700]),
              const SizedBox(width: 4),
              const Text(
                "Edit",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            final status = await deleteButtonCallback(context, addressId);
            return status;
          } else if (direction == DismissDirection.endToStart) {
            final status = await editButtonCallback(context, addressId);
            return status;
          }
          return false;
        },
        onDismissed: (direction) async {
          await refreshPage();
        },
      ),
    );
  }

  Widget buildDismissiblePrimaryBackground() {
    return Container(
      padding: EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.edit, color: Colors.white),
          SizedBox(width: 4),
          Text(
            "Edit",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDismissibleSecondaryBackground() {
    return Container(
      padding: EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "Delete",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.delete, color: Colors.white),
        ],
      ),
    );
  }
}
