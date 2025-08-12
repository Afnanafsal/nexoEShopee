// ...existing code...

import 'package:fishkart/services/authentification/authentification_service.dart';
import 'package:fishkart/services/base64_image_service/base64_image_service.dart';
import 'package:fishkart/services/database/user_database_helper.dart';
import 'package:fishkart/services/local_files_access/local_files_access_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = true;
  String? _cachedDisplayPicture;
  final TextEditingController _dobController = TextEditingController();
  DateTime? _dob;

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  void initState() {
    super.initState();
    UserDatabaseHelper().currentUserDataStream.listen((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        _nameController.text = data['display_name'] ?? '';
        _emailController.text =
            (data['email'] != null && data['email'].isNotEmpty)
            ? data['email']
            : AuthentificationService().currentUser.email ?? '';
        _phoneController.text = data['phone'] ?? '';
        final fetched = data['display_picture'] as String?;
        _cachedDisplayPicture = (fetched != null && fetched.isNotEmpty)
            ? fetched
            : null;
        // Prefill DOB if available
        final dobString = data['dob'] as String?;
        if (dobString != null && dobString.isNotEmpty) {
          try {
            final parts = dobString.split('/');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              _dob = DateTime(year, month, day);
              _dobController.text = dobString;
            }
          } catch (_) {
            _dobController.text = '';
          }
        }
      } else {
        _cachedDisplayPicture = null;
      }
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final uid = AuthentificationService().currentUser.uid;
    await UserDatabaseHelper().updateUser(uid, {
      'display_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'dob': _dobController.text.trim(),
    });
    setState(() => _loading = false);
    Navigator.pop(context);
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _loading = true);
      final result = await choseImageFromLocalFiles(context);
      final base64String = await Base64ImageService().xFileToBase64(
        result.xFile,
      );
      await UserDatabaseHelper().uploadDisplayPictureForCurrentUser(
        base64String,
      );
      setState(() {
        _cachedDisplayPicture = base64String;
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update picture: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 0,
                        top: 16.h,
                        right: 0,
                        bottom: 0,
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(
                            CupertinoIcons.back,
                            color: Colors.black,
                            size: 32.sp,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          tooltip: 'Back',
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Profile Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7F9),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15.r,
                            offset: Offset(0, 15.h),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 40.r,
                                backgroundImage:
                                    _cachedDisplayPicture != null &&
                                        _cachedDisplayPicture!.isNotEmpty
                                    ? (_cachedDisplayPicture!.startsWith('http')
                                          ? NetworkImage(_cachedDisplayPicture!)
                                          : _cachedDisplayPicture!.startsWith(
                                              'blob:',
                                            )
                                          ? null
                                          : MemoryImage(
                                                  Base64ImageService()
                                                      .base64ToBytes(
                                                        _cachedDisplayPicture!,
                                                      ),
                                                )
                                                as ImageProvider)
                                    : null,
                              ),
                              Positioned(
                                top: 0.h,
                                left: 56.w,
                                child: GestureDetector(
                                  onTap: _pickAndUploadImage,
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    child: Icon(
                                      Icons.edit_square,
                                      color: Colors.black,
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 16.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Text(
                                  'Hi, there!',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _nameController.text.toLowerCase(),
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    // Edit Profile Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 8.h,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4.h),
                              Text(
                                'Edit profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 40.w,
                                  vertical: 32.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 20.r,
                                      offset: Offset(0, 10.h),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("Name"),
                                    SizedBox(height: 5.h),
                                    _buildInput(_nameController, "name"),
                                    SizedBox(height: 14.h),
                                    _buildLabel("Email"),
                                    SizedBox(height: 5.h),
                                    _buildInput(_emailController, "@gmail.com"),
                                    SizedBox(height: 14.h),
                                    _buildLabel("Password"),
                                    SizedBox(height: 5.h),
                                    _buildInput(
                                      TextEditingController(
                                        text: "***********",
                                      ),
                                      "***********",
                                      enabled: false,
                                    ),
                                    SizedBox(height: 14.h),
                                    _buildLabel("Phone Number"),
                                    SizedBox(height: 5.h),
                                    _buildInput(
                                      _phoneController,
                                      "Enter Phone Number",
                                    ),
                                    SizedBox(height: 14.h),
                                    _buildLabel("Date of Birth"),
                                    SizedBox(height: 5.h),
                                    GestureDetector(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _dob ?? DateTime(2000, 1, 1),
                                          firstDate: DateTime(1900),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            _dob = picked;
                                            _dobController.text = _formatDate(
                                              picked,
                                            );
                                          });
                                        }
                                      },
                                      child: AbsorbPointer(
                                        child: TextField(
                                          controller: _dobController,
                                          style: TextStyle(fontSize: 14.sp),
                                          decoration: InputDecoration(
                                            hintText: "Select Date of Birth",
                                            hintStyle: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 14.sp,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: 12.h,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(
                                                color: Colors.black,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            disabledBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(
                                                color: Colors.black,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                            suffixIcon: Icon(
                                              Icons.keyboard_arrow_down_outlined,
                                              size: 18.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 24.h),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.w,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _save,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            padding: EdgeInsets.symmetric(
                                              vertical: 18.h,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                            ),
                                          ),
                                          child: Text(
                                            "Save Changes",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14.sp,
        color: Colors.black,
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint, {
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black54, fontSize: 14.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(12.r),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}
