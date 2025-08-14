import 'package:fishkart/constants.dart';
import 'package:fishkart/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NothingToShowContainer extends StatelessWidget {
  final String iconPath;
  final String primaryMessage;
  final String secondaryMessage;

  const NothingToShowContainer({
    Key? key,
    this.iconPath = "assets/icons/empty_box.svg",
    this.primaryMessage = "Nothing to show",
    this.secondaryMessage = "",
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: SizeConfig.screenWidth * 0.75,
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            color: kTextColor,
            width: getProportionateScreenWidth(75),
          ),
          SizedBox(height: 16),
          Text(
            "$primaryMessage",
            style: TextStyle(color: kTextColor, fontSize: 15),
          ),
          Text(
            "$secondaryMessage",
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: TextStyle(
              color: kTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
