import 'package:nexoeshopee/components/rounded_icon_button.dart';
import 'package:nexoeshopee/components/search_field.dart';
import 'package:flutter/material.dart';

import '../../../components/icon_button_with_counter.dart';
import 'package:nexoeshopee/screens/home/components/delivery_address_bar.dart';
import 'package:nexoeshopee/screens/search/search_screen.dart';

class HomeHeader extends StatelessWidget {
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onCartButtonPressed;
  const HomeHeader({
    Key? key,
    required this.onSearchSubmitted,
    required this.onCartButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: DeliveryAddressBar()),
          SizedBox(width: 8),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              icon: Icon(Icons.search, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
