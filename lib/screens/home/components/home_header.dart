import 'package:fishkart/components/rounded_icon_button.dart';
import 'package:fishkart/components/search_field.dart';
import 'package:flutter/material.dart';

import '../../../components/icon_button_with_counter.dart';
import 'package:fishkart/screens/home/components/delivery_address_bar.dart';
import 'package:fishkart/screens/search/search_screen.dart';

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
            
          ),
        ],
      ),
    );
  }
}
