import 'package:flutter/material.dart';

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
                ? Icon(Icons.home, size: 38)
                : Icon(Icons.home_outlined, size: 38),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/icons/cart.png'),
              size: 44,
              color: selectedIndex == 1 ? Color(0xFF294157) : Color(0xFF757575),
            ),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                selectedIndex == 2
                    ? Icon(Icons.person, size: 38)
                    : Icon(Icons.person, size: 38),
              ],
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
