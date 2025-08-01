import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../size_config.dart';

class CategoryCard extends StatelessWidget {
  final String icon;
  final String text;
  final GestureTapCallback press;
  const CategoryCard({
    required Key key,
    required this.icon,
    required this.text,
    required this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: SizedBox(
        width: getProportionateScreenWidth(55),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: EdgeInsets.all(getProportionateScreenWidth(15)),
                decoration: BoxDecoration(
                  color: Color(0xFFFFECDF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: icon.endsWith('.png')
                    ? Image.asset(
                        icon,
                        errorBuilder: (context, error, stackTrace) {
                          if (icon.contains('mackerel.png')) {
                            return Image.asset('assets/icons/Pomfret.png');
                          } else if (icon.contains('Prawns.png')) {
                            return Image.asset('assets/icons/Lobster.png');
                          } else {
                            return Icon(Icons.error, color: Colors.red);
                          }
                        },
                      )
                    : SvgPicture.asset(
                        icon,
                        placeholderBuilder: (context) =>
                            Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
