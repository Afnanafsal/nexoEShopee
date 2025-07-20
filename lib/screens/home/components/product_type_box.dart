import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../size_config.dart';

class ProductTypeBox extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onPress;
  const ProductTypeBox({
    super.key,
    required this.icon,
    required this.title,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      child: Container(
        width: getProportionateScreenWidth(89.91),
        height: getProportionateScreenHeight(202.5),
            margin: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(4),
        ),
        padding: EdgeInsets.symmetric(
          vertical: getProportionateScreenHeight(18),
          horizontal: getProportionateScreenWidth(10),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFE0E3EA), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  icon,
                  fit: BoxFit.contain,
                  width: getProportionateScreenWidth(75),
                  height: getProportionateScreenHeight(75),
                ),
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(10)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: getProportionateScreenWidth(10),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
