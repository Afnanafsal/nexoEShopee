import 'package:fishkart/screens/manage_addresses/manage_addresses_screen.dart';
import 'package:flutter/material.dart';
// ...existing code...
import 'package:fishkart/providers/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishkart/constants.dart';
// import 'package:fishkart/screens/manage_addresses/manage_addresses_screen.dart';
import 'package:fishkart/providers/product_providers.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/size_config.dart';

final _addressesListProvider = FutureProvider<List<String>>((ref) async {
  return await UserDatabaseHelper().addressesList;
});

final selectedAddressFutureProvider = FutureProvider((ref) async {
  final selectedAddressId = ref.watch(selectedAddressIdProvider);
  if (selectedAddressId == null) return null;
  return await UserDatabaseHelper().getAddressFromId(selectedAddressId);
});

class DeliveryAddressBar extends ConsumerStatefulWidget {
  const DeliveryAddressBar({Key? key}) : super(key: key);

  @override
  ConsumerState<DeliveryAddressBar> createState() => _DeliveryAddressBarState();
}

class _DeliveryAddressBarState extends ConsumerState<DeliveryAddressBar>
    with RouteAware {
  bool _dialogShown = false;
  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      try {
        ref.invalidate(selectedAddressFutureProvider);
        ref.invalidate(_addressesListProvider);
      } catch (_) {}
      return mounted;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeObserver = ModalRoute.of(context)?.navigator?.widget.observers
        .whereType<RouteObserver<PageRoute>>()
        .firstOrNull;
    routeObserver?.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    final routeObserver = ModalRoute.of(context)?.navigator?.widget.observers
        .whereType<RouteObserver<PageRoute>>()
        .firstOrNull;
    routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    ref.invalidate(selectedAddressFutureProvider);
    ref.invalidate(_addressesListProvider);
  }

  Future<void> _showAddressSelectionDialog() async {
    final addressesListAsync = ref.read(_addressesListProvider);
    final selectedAddressId = ref.read(selectedAddressIdProvider);

    await addressesListAsync.when(
      data: (addresses) async {
        if (addresses.isEmpty) return;
        final selected = await showDialog<String>(
          context: context,
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 8),
                        Text(
                          'Select Delivery Address',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ...addresses.map((addressId) {
                      return FutureBuilder(
                        future: UserDatabaseHelper().getAddressFromId(
                          addressId,
                        ),
                        builder: (context, snapshot) {
                          final address = snapshot.data;
                          final title =
                              (address != null &&
                                  address.title != null &&
                                  address.title!.isNotEmpty)
                              ? address.title!
                              : (address != null &&
                                    address.addressLine1 != null &&
                                    address.addressLine1!.isNotEmpty)
                              ? address.addressLine1!
                              : 'Loading...';
                          final details = address != null
                              ? [
                                      address.addressLine1,
                                      address.city,
                                      address.state,
                                      address.pincode,
                                    ]
                                    .whereType<String>()
                                    .where((e) => e.isNotEmpty)
                                    .join(', ')
                              : '';
                          final isSelected = addressId == selectedAddressId;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.pop(context, addressId);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kPrimaryColor.withOpacity(0.08)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? kPrimaryColor
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.home,
                                        color: isSelected
                                            ? kPrimaryColor
                                            : Colors.grey[500],
                                        size: 22,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isSelected
                                                    ? kPrimaryColor
                                                    : Colors.black,
                                              ),
                                            ),
                                            if (details.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2.0,
                                                ),
                                                child: Text(
                                                  details,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: kPrimaryColor,
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        );
        if (selected != null && selected != selectedAddressId) {
          ref.read(selectedAddressIdProvider.notifier).state = selected;
          ref.invalidate(latestProductsProvider);
        }
      },
      loading: () {},
      error: (err, stack) {},
    );
  }

  void _navigateToSearch() {
    // Navigate to search screen - replace with your actual search screen
    Navigator.pushNamed(context, '/search');
    // or Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final selectedAddressId = ref.watch(selectedAddressIdProvider);
    final addressAsync = ref.watch(selectedAddressFutureProvider);
    final addressesListAsync = ref.watch(_addressesListProvider);

    // If only one address exists, select it automatically
    addressesListAsync.when(
      data: (addresses) {
        if (addresses.length == 1 && selectedAddressId != addresses[0]) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedAddressIdProvider.notifier).state = addresses[0];
            ref.invalidate(latestProductsProvider);
          });
        }
      },
      loading: () {},
      error: (err, stack) {},
    );
    return addressesListAsync.when(
      data: (addresses) {
        if (addresses.isEmpty) {
          if (!_dialogShown) {
            _dialogShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text("No address found"),
                  content: const Text(
                    "Please add a delivery address to continue.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageAddressesScreen(),
                          ),
                        );
                      },
                      child: const Text("Add Address"),
                    ),
                  ],
                ),
              );
            });
          }
          return Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "No address found. Please add a delivery address.",
                    style: TextStyle(
                      fontSize: 16,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _navigateToSearch,
                  icon: Icon(Icons.search, color: kPrimaryColor, size: 24),
                ),
              ],
            ),
          );
        } else {
          _dialogShown = false;
        }

        return Container(
          padding: EdgeInsets.only(
            left: getProportionateScreenWidth(8),
            right: getProportionateScreenWidth(10),
            top: getProportionateScreenHeight(8),
            bottom: getProportionateScreenHeight(8),
          ),
          decoration: BoxDecoration(color: Colors.white),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageAddressesScreen(),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with dropdown arrow inline
                      InkWell(
                        onTap: addresses.length > 1
                            ? _showAddressSelectionDialog
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            addressAsync.when(
                              data: (address) {
                                String title = "Address";
                                if (address != null &&
                                    address.title != null &&
                                    address.title!.isNotEmpty) {
                                  title = address.title!;
                                }
                                return Text(
                                  "${title[0].toUpperCase()}${title.substring(1)}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              },
                              loading: () => Text(
                                "Loading...",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              error: (err, stack) => Text(
                                "Error loading address",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            // Dropdown arrow directly next to title - show only if multiple addresses
                            if (addresses.length > 1)
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: kPrimaryColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                      // Address details
                      if (selectedAddressId == null)
                        Text(
                          "Add delivery address",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        )
                      else
                        addressAsync.when(
                          data: (address) {
                            String formattedAddress = selectedAddressId;
                            if (address != null) {
                              formattedAddress =
                                  [
                                        address.addressLine1,
                                        address.city,
                                        address.state,
                                        address.pincode,
                                      ]
                                      .whereType<String>()
                                      .where((e) => e.isNotEmpty)
                                      .join(', ');
                            }
                            // Truncate address to 30 chars with ellipsis
                            String displayAddress = formattedAddress;
                            const int maxLen = 30;
                            if (displayAddress.length > maxLen) {
                              displayAddress =
                                  displayAddress.substring(0, maxLen - 3) +
                                  '...';
                            }
                            return Text(
                              displayAddress,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF646161),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                          loading: () => Text(
                            "Loading...",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[400],
                            ),
                          ),
                          error: (err, stack) => Text(
                            "Error loading address",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Search icon
              IconButton(
                onPressed: _navigateToSearch,
                icon: Icon(Icons.search, color: kPrimaryColor, size: 32),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 12),
            Expanded(child: Text('Loading addresses...')),
            IconButton(
              onPressed: _navigateToSearch,
              icon: Icon(Icons.search, color: kPrimaryColor, size: 32),
            ),
          ],
        ),
      ),
      error: (err, stack) => Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 12),
            Expanded(child: Text('Error loading addresses')),
            IconButton(
              onPressed: _navigateToSearch,
              icon: Icon(Icons.search, color: kPrimaryColor, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
