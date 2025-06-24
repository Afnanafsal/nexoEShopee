import 'package:nexoeshopee/components/rounded_icon_button.dart';
import 'package:nexoeshopee/components/search_field.dart';
import 'package:flutter/material.dart';

import '../../../components/icon_button_with_counter.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RoundedIconButton(
            iconData: Icons.menu,
            press: () {
              Scaffold.of(context).openDrawer();
            }),
        Expanded(
          child: SearchField(
            onSubmit: onSearchSubmitted,
          ),
        ),
        SizedBox(width: 5),
        IconButtonWithCounter(
          key: const Key('cart_button'),
          svgSrc: "assets/icons/Cart Icon.svg",
          numOfItems: 0,
          press: onCartButtonPressed,
        ),
      ],
    );
  }
}
