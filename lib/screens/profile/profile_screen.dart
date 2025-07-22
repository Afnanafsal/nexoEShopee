import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexoeshopee/screens/sign_in/sign_in_screen.dart';
import 'package:nexoeshopee/services/authentification/authentification_service.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/services/base64_image_service/base64_image_service.dart';
import '../../constants.dart';
import '../about_developer/about_developer_screen.dart';
import '../change_display_picture/change_display_picture_screen.dart';
import '../change_email/change_email_screen.dart';
import '../my_favorites/my_favorites_screen.dart';
import '../change_password/change_password_screen.dart';
import '../change_phone/change_phone_screen.dart';
import '../edit_product/edit_product_screen.dart';
import '../manage_addresses/manage_addresses_screen.dart';
import '../my_orders/my_orders_screen.dart';
import '../my_products/my_products_screen.dart';
import '../../utils.dart';
import '../change_display_name/change_display_name_screen.dart';
import 'package:nexoeshopee/components/async_progress_dialog.dart';

import '../home/home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _ProfileHeader(avatarOverlap: true),
                    ],
                  ),
                ),
                Positioned(
                  top: 32,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 22,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                children: [const SizedBox(height: 8), _ProfileActions()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final bool avatarOverlap;
  const _ProfileHeader({this.avatarOverlap = false});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthentificationService().userChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return Column(
            children: [
              FutureBuilder<String?>(
                future: UserDatabaseHelper().displayPictureForCurrentUser,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      radius: 40,
                      backgroundColor: kTextColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person_rounded,
                        size: 44,
                        color: kTextColor,
                      ),
                    );
                  }
                  if (snap.hasData &&
                      snap.data != null &&
                      (snap.data as String).isNotEmpty) {
                    return CircleAvatar(
                      radius: 40,
                      backgroundImage: Base64ImageService()
                          .base64ToImageProvider(snap.data as String),
                    );
                  }
                  return CircleAvatar(
                    radius: 40,
                    backgroundColor: kTextColor.withOpacity(0.2),
                    child: Icon(
                      Icons.person_rounded,
                      size: 44,
                      color: kTextColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                user.displayName ?? 'No Name',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? 'No Email',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else {
          return Center(child: Icon(Icons.error));
        }
      },
    );
  }
}

class _ProfileActions extends StatelessWidget {
  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileExpansion(
          icon: Icons.person,
          title: 'Edit Account',
          children: [
            _ProfileActionTile(
              title: 'Change Display Picture',
              icon: Icons.image,
              onTap: () => _push(context, ChangeDisplayPictureScreen()),
            ),
            _ProfileActionTile(
              title: 'Change Display Name',
              icon: Icons.edit,
              onTap: () => _push(context, ChangeDisplayNameScreen()),
            ),
            _ProfileActionTile(
              title: 'Change Phone Number',
              icon: Icons.phone,
              onTap: () => _push(context, ChangePhoneScreen()),
            ),
            _ProfileActionTile(
              title: 'Change Email',
              icon: Icons.email,
              onTap: () => _push(context, ChangeEmailScreen()),
            ),
            _ProfileActionTile(
              title: 'Change Password',
              icon: Icons.lock,
              onTap: () => _push(context, ChangePasswordScreen()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ProfileActionTile(
          title: 'Manage Addresses',
          icon: Icons.edit_location,
          onTap: () => _handleVerifiedAction(context, ManageAddressesScreen()),
        ),
        _ProfileActionTile(
          title: 'My Favorites',
          icon: Icons.favorite,
          onTap: () => _handleVerifiedAction(context, MyFavoritesScreen()),
        ),
        _ProfileActionTile(
          title: 'My Orders',
          icon: Icons.receipt_long,
          onTap: () => _handleVerifiedAction(context, MyOrdersScreen()),
        ),
        const SizedBox(height: 8),
        _ProfileExpansion(
          icon: Icons.business,
          title: 'I am Seller',
          children: [
            _ProfileActionTile(
              title: 'Add New Product',
              icon: Icons.add_box,
              onTap: () => _handleVerifiedAction(
                context,
                EditProductScreen(key: UniqueKey(), productToEdit: null),
              ),
            ),
            _ProfileActionTile(
              title: 'Manage My Products',
              icon: Icons.inventory,
              onTap: () => _handleVerifiedAction(context, MyProductsScreen()),
            ),
          ],
        ),

        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(Icons.logout),
          label: Text(
            'Sign Out',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            final confirmation = await showConfirmationDialog(
              context,
              "Confirm Sign out ?",
            );
            if (confirmation) {
              await AuthentificationService().signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => SignInScreen()),
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }

  void _handleVerifiedAction(BuildContext context, Widget screen) async {
    bool allowed = AuthentificationService().currentUserVerified;
    if (!allowed) {
      final reverify = await showConfirmationDialog(
        context,
        "You haven't verified your email address. This action is only allowed for verified users.",
        positiveResponse: "Resend verification email",
        negativeResponse: "Go back",
      );
      if (reverify) {
        final future = AuthentificationService()
            .sendVerificationEmailToCurrentUser();
        await showDialog(
          context: context,
          builder: (context) => AsyncProgressDialog(
            future,
            message: Text("Resending verification email"),
          ),
        );
      }
      return;
    }
    _push(context, screen);
  }
}

class _ProfileActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _ProfileActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF294157)),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 32,
      horizontalTitleGap: 12,
    );
  }
}

class _ProfileExpansion extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _ProfileExpansion({
    required this.title,
    required this.icon,
    required this.children,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: Color(0xFF294157)),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        children: children,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
      ),
    );
  }
}
