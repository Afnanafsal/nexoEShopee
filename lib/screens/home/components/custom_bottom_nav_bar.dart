import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double navBarHeight = MediaQuery.of(context).size.height < 700
        ? 65
        : 89;
    return Container(
      height: navBarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Color(0xFF294157),
        unselectedItemColor: Color(0xFF757575),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        iconSize: 38,
        currentIndex: selectedIndex,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
            icon: selectedIndex == 0
                ? SvgPicture.asset(
                    'assets/icons/home_outlined-2.svg',
                    width: 28,
                    height: 28,
                  )
                : SvgPicture.asset(
                    'assets/icons/home-2.svg',
                    width: 28,
                    height: 28,
                  ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: selectedIndex == 1
                ? SvgPicture.asset(
                    'assets/icons/bag_outlined-2.svg',
                    width: 28,
                    height: 28,
                  )
                : SvgPicture.asset(
                    'assets/icons/bag-2.svg',
                    width: 28,
                    height: 28,
                  ),
            label: 'Cart',
          ),

          BottomNavigationBarItem(
            icon: selectedIndex == 2
                ? SvgPicture.asset(
                    'assets/icons/User.svg',
                    width: 28,
                    height: 28,
                  )
                : SvgPicture.asset(
                    'assets/icons/user_outlined.svg',
                    width: 28,
                    height: 28,
                  ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
