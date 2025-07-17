import 'package:flutter/material.dart';

import '../../size_config.dart';

import '../cart/cart_screen.dart';
import 'components/body.dart';
import 'components/home_screen_drawer.dart';
import 'components/custom_bottom_nav_bar.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = "/home";
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [Body(), CartScreen(), ProfileScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
