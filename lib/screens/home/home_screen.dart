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
    final localContext = context;
    if (selectedAddressId == null) {
      final addressIds = await UserDatabaseHelper().addressesList;
      if (addressIds.isEmpty) {
        // No addresses, prompt to add
        if (!mounted) return;
        showDialog(
          context: localContext,
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
        if (!mounted) return;
        // Prefetch all address details in parallel
        final addressDetails = await Future.wait(addressIds.map((id) => UserDatabaseHelper().getAddressFromId(id)));
        await showDialog(
          context: localContext,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                final theme = Theme.of(context);
                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  backgroundColor: theme.scaffoldBackgroundColor,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.08),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.location_on, color: theme.primaryColor, size: 28),
                            ),
                            SizedBox(width: 12),
                            Text('Select Delivery Address',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18),
                        ...List.generate(addressIds.length, (i) {
                          final id = addressIds[i];
                          final address = addressDetails[i];
                          String display = id;
                          if (address != null) {
                            display = [
                              address.addressLine1,
                              address.city,
                              address.state,
                              address.pincode,
                            ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
                          }
                          return Card(
                            color: selectedId == id ? theme.primaryColor.withOpacity(0.08) : theme.cardColor,
                            elevation: 0,
                            margin: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: RadioListTile<String>(
                              title: Text(display,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: selectedId == id ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
                                  fontWeight: selectedId == id ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              value: id,
                              groupValue: selectedId,
                              onChanged: (val) {
                                setState(() => selectedId = val);
                              },
                              secondary: Icon(Icons.home, color: selectedId == id ? theme.primaryColor : theme.iconTheme.color),
                              activeColor: theme.primaryColor,
                            ),
                          );
                        }),
                        SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel', style: theme.textTheme.labelLarge?.copyWith(color: theme.primaryColor)),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: selectedId == null
                                  ? null
                                  : () {
                                      ref.read(selectedAddressIdProvider.notifier).state = selectedId;
                                      Navigator.of(context).pop();
                                    },
                              icon: Icon(Icons.check, color: Colors.white),
                              label: Text('Select', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
