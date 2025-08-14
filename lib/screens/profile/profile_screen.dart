import 'dart:convert';
import 'dart:typed_data';
import 'package:fishkart/screens/manage_addresses/manage_addresses_screen.dart';
import 'package:fishkart/screens/my_orders/my_orders_screen.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../utils.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F5),
      body: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0.h),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                const _ProfileCard(),
                SizedBox(height: 44.h),
                _ProfileMenuItem(
                  icon: Icon(Icons.person, size: 22.sp, color: Colors.black),
                  title: 'Edit Account',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditProfileScreen()),
                    );
                  },
                ),
                SizedBox(height: 20.h),
                _ProfileMenuItem(
                  icon: Icon(
                    Icons.location_on,
                    size: 22.sp,
                    color: Colors.black,
                  ),
                  title: 'Manage Addresses',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageAddressesScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20.h),
                _ProfileMenuItem(
                  icon: Icon(Icons.list_alt, size: 22.sp, color: Colors.black),
                  title: 'My Orders',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MyOrdersScreen()),
                    );
                  },
                ),
                SizedBox(height: 20.h),
                _ProfileMenuItem(
                  icon: ImageIcon(
                    AssetImage('assets/icons/signout.png'),
                    color: Colors.black,
                    size: 22.sp,
                  ),
                  title: 'Sign Out',
                  onTap: () async {
                    final confirmation = await showConfirmationDialog(
                      context,
                      "Confirm Sign out?",
                    );
                    if (confirmation) {
                      await AuthentificationService().signOut();
                      try {
                        final googleSignIn = GoogleSignIn();
                        await googleSignIn.disconnect();
                      } catch (_) {}
                      Future.delayed(const Duration(milliseconds: 300), () {
                        SystemNavigator.pop();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = AuthentificationService().currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        Uint8List? chosenImageBytes;
        String? displayPictureUrl;
        String displayName = 'No Name';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data();
        if (data != null) {
          displayName = data['display_name'] ?? user.displayName ?? 'No Name';
          final fetched = data['display_picture'] as String?;
          if (fetched != null && fetched.isNotEmpty) {
            if (fetched.startsWith('http')) {
              displayPictureUrl = fetched;
              chosenImageBytes = null;
            } else if (!fetched.startsWith('blob:')) {
              try {
                chosenImageBytes = base64Decode(fetched);
                displayPictureUrl = null;
              } catch (_) {
                chosenImageBytes = null;
                displayPictureUrl = null;
              }
            } else {
              // blob: url, treat as no image
              chosenImageBytes = null;
              displayPictureUrl = null;
            }
          }
        }

        Widget avatar;
        if (chosenImageBytes != null) {
          avatar = CircleAvatar(
            radius: 30.r,
            backgroundImage: MemoryImage(chosenImageBytes),
          );
        } else if (displayPictureUrl != null && displayPictureUrl.isNotEmpty) {
          avatar = CircleAvatar(
            radius: 30.r,
            backgroundImage: NetworkImage(displayPictureUrl),
          );
        } else {
          avatar = CircleAvatar(radius: 40.r, backgroundColor: Colors.grey);
        }

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, there!',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    displayName.toLowerCase(),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          children: [
            icon,
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
