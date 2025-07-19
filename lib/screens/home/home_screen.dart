import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/providers/user_providers.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';

import '../../size_config.dart';

import '../cart/cart_screen.dart';
import 'components/body.dart';
import 'components/home_screen_drawer.dart';
import 'components/custom_bottom_nav_bar.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const String routeName = "/home";
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [Body(), CartScreen(), ProfileScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptAddress();
    });
  }

  Future<void> _checkAndPromptAddress() async {
    final selectedAddressId = ref.read(selectedAddressIdProvider);
    if (selectedAddressId == null) {
      final addressIds = await UserDatabaseHelper().addressesList;
      if (addressIds.isEmpty) {
        // No addresses, prompt to add
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('No delivery address found'),
            content: Text('Please add a delivery address to continue.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/manage_addresses');
                },
                child: Text('Add Address'),
              ),
            ],
          ),
        );
      } else {
        String? selectedId;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('Select Delivery Address'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: addressIds
                          .map(
                            (id) => FutureBuilder(
                              future: UserDatabaseHelper().getAddressFromId(id),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return ListTile(title: Text('Loading...'));
                                }
                                final address = snapshot.data;
                                String display = id;
                                if (address != null) {
                                  display =
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
                                return RadioListTile<String>(
                                  title: Text(display),
                                  value: id,
                                  groupValue: selectedId,
                                  onChanged: (val) {
                                    setState(() => selectedId = val);
                                  },
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: selectedId == null
                          ? null
                          : () {
                              ref
                                      .read(selectedAddressIdProvider.notifier)
                                      .state =
                                  selectedId;
                              Navigator.of(context).pop();
                            },
                      child: Text('Select'),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: _screens[_selectedIndex],
      drawer: HomeScreenDrawer(key: Key('home_screen_drawer')),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
