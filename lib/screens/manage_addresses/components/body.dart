import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fishkart/components/default_button.dart';
import 'package:fishkart/components/nothingtoshow_container.dart';
import 'package:fishkart/constants.dart';
import 'package:fishkart/screens/edit_address/edit_address_screen.dart';
import 'package:fishkart/screens/manage_addresses/components/address_short_details_card.dart';
import 'package:fishkart/services/data_streams/addresses_stream.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/services/cache/hive_service.dart';
import 'package:fishkart/size_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../components/address_box.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> with RouteAware {
  final AddressesStream addressesStream = AddressesStream();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    addressesStream.init();
    _reloadAndStartTimer();
  }

  void _reloadAndStartTimer() async {
    addressesStream.reload();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      addressesStream.reload();
      setState(() {});
    });
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeObserver = ModalRoute.of(context)?.navigator?.widget.observers
        .whereType<RouteObserver<PageRoute>>()
        .firstOrNull;
    routeObserver?.subscribe(this, ModalRoute.of(context) as PageRoute);
    _reloadAndStartTimer();
  }

  @override
  void dispose() {
    final routeObserver = ModalRoute.of(context)?.navigator?.widget.observers
        .whereType<RouteObserver<PageRoute>>()
        .firstOrNull;
    routeObserver?.unsubscribe(this);
    _refreshTimer?.cancel();
    addressesStream.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    _reloadAndStartTimer();
  }

  @override
  Widget build(BuildContext context) {
    // Try to get cached addresses instantly
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: refreshPage,
        child: Container(
          color: Color(0XFFEFF1F5),
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
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios, size: 28),
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
                    "Swipe Right to delete",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // Address list (cache-first)
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
                                      fontWeight: FontWeight.w500,
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
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditAddressScreen(
                                        key: UniqueKey(),
                                        addressIdToEdit: null,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    setState(() {
                                      addressesStream.reload();
                                    });
                                  }
                                },
                                child: const Text(
                                  "Add New Address",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditAddressScreen(key: Key(addressId), addressIdToEdit: addressId),
      ),
    );
    if (result == true) {
      setState(() {
        addressesStream.reload();
      });
    }
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
        direction: DismissDirection.startToEnd,
        background: buildDismissibleSecondaryBackground(),
        dismissThresholds: {DismissDirection.startToEnd: 0.65},
        child: FutureBuilder(
          future: UserDatabaseHelper().getAddressFromId(addressId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(height: 18, color: Colors.grey[300]),
                      ),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text('Unable to load address'),
                ),
              );
            }
            final address = snapshot.data;
            return Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await addressItemTapCallback(addressId);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              address?.title ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: SvgPicture.asset(
                              'assets/icons/edit.svg',
                              width: 18,
                              height: 18,
                              color: Color(0xFF5E5E5E),
                            ),
                            label: Text(
                              "Edit",
                              style: TextStyle(
                                color: Color(0xFF5E5E5E),
                                fontWeight: FontWeight.w400,
                                fontSize: 15,
                              ),
                            ),
                            onPressed: () async {
                              await editButtonCallback(context, addressId);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getAddressLine(address),
                        style: TextStyle(
                          color: Color(0XFF646161),
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            final status = await deleteButtonCallback(context, addressId);
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

  // Helper to get address line from Address model
  String _getAddressLine(dynamic address) {
    if (address == null) return '';
    String line = '';
    if (address.addressLine1 != null && address.addressLine1!.isNotEmpty) {
      line += address.addressLine1!;
    }
    if (address.addressLine2 != null && address.addressLine2!.isNotEmpty) {
      if (line.isNotEmpty) line += ', ';
      line += address.addressLine2!;
    }
    if (address.pincode != null && address.pincode!.isNotEmpty) {
      if (line.isNotEmpty) line += ', ';
      line += address.pincode!;
    }
    return line;
  }

  Widget buildDismissiblePrimaryBackground() {
    // Removed swipe-to-edit background
    return SizedBox.shrink();
  }

  Widget buildDismissibleSecondaryBackground() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            color: Color(0xFF5E5E5E),
            padding: EdgeInsets.only(left: 20),
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
          ),
        );
      },
    );
  }
}
