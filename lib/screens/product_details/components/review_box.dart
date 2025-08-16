import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishkart/models/Review.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'dart:typed_data';

class ReviewBox extends StatefulWidget {
  final Review review;
  final String productId;

  const ReviewBox({
    required Key key,
    required this.review,
    required this.productId,
  }) : super(key: key);

  @override
  State<ReviewBox> createState() => _ReviewBoxState();
}

bool _showReplies = false;

class _ReviewBoxState extends State<ReviewBox> {
  late Review review;

  @override
  void initState() {
    super.initState();
    review = widget.review;
  }

  Uint8List _decodeBase64(String base64String) {
    try {
      return base64Decode(base64String.split(',').last);
    } catch (_) {
      return Uint8List(0);
    }
  }

  Future<List<Map<String, dynamic>>> fetchReplies() async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db
        .collection('products')
        .doc(widget.productId)
        .collection('reviews')
        .doc(review.reviewerUid)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<String> _getCurrentUserId() async {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> showReplyDialog() async {
    String replyText = '';
    final currentUserId = await _getCurrentUserId();
    String? avatar;
    String? name;

    // Fetch user avatar and name from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    final userData = userDoc.data();
    if (userData != null) {
      avatar = userData['display_picture'];
      name = userData['display_name'] ?? 'User';
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.reply, color: Colors.black),
            const SizedBox(width: 8),
            const Text(
              'Reply to Review',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Type your reply...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 15, color: Colors.black),
            onChanged: (val) => replyText = val,
            maxLines: 3,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.black12),
              ),
            ),
            onPressed: () async {
              if (replyText.trim().isNotEmpty) {
                final db = FirebaseFirestore.instance;
                await db
                    .collection('products')
                    .doc(widget.productId)
                    .collection('reviews')
                    .doc(review.reviewerUid)
                    .collection('replies')
                    .add({
                      'text': replyText.trim(),
                      'createdAt': DateTime.now().toIso8601String(),
                      'userAvatar': avatar,
                      'userName': name,
                    });

                setState(() {
                  review = review.copyWith(replyCount: review.replyCount + 1);
                });

                await db
                    .collection('products')
                    .doc(widget.productId)
                    .collection('reviews')
                    .doc(review.reviewerUid)
                    .update({'replyCount': review.replyCount});
              }
              Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> likeReview() async {
    final db = FirebaseFirestore.instance;
    final currentUserId = await _getCurrentUserId();
    final reviewRef = db
        .collection('products')
        .doc(widget.productId)
        .collection('reviews')
        .doc(review.reviewerUid);

    final reviewDoc = await reviewRef.get();
    List<dynamic> likedBy = reviewDoc.data()?['likedBy'] ?? [];

    if (!likedBy.contains(currentUserId)) {
      likedBy.add(currentUserId);
      setState(() {
        review = review.copyWith(
          likes: likedBy.length,
          likedBy: likedBy.map((e) => e.toString()).toList(),
        );
      });
      await reviewRef.update({'likes': likedBy.length, 'likedBy': likedBy});
    }
  }

  String getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }

  ImageProvider _getAvatarProvider() {
    if (review.userAvatar == null || review.userAvatar!.isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }
    if (review.userAvatar!.startsWith('http')) {
      return NetworkImage(review.userAvatar!);
    }
    try {
      final bytes = Uri.parse(review.userAvatar!).data?.contentAsBytes();
      if (bytes != null) {
        return MemoryImage(bytes);
      }
    } catch (_) {}
    return const AssetImage('assets/images/default_avatar.png');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchReplies(),
      builder: (context, snapshot) {
        final replies = snapshot.data ?? [];

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          margin: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Review Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundImage: _getAvatarProvider(),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Show only first name
                        Text(
                          (review.userName ?? 'User').split(' ')[0],
                          style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12.sp,
                          ),
                        ),
                        // Review text
                        Text(
                          review.review ?? '',
                          style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
                          child: Row(
                          children: [
                            Text(
                            getTimeAgo(review.createdAt),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Color(0XFF646161),
                              fontWeight: FontWeight.w400,
                            ),
                            ),
                            SizedBox(width: 12.w),
                            GestureDetector(
                            onTap: showReplyDialog,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                              color: Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Color(0XFF646161),
                                fontWeight: FontWeight.w400,
                              ),
                              ),
                            ),
                            ),
                          ],
                          ),
                        ),

                        // View Replies Button directly under review text
                        Padding(
                          padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
                          child: GestureDetector(
                          onTap: () {
                            setState(() {
                            _showReplies = !_showReplies;
                            });
                            if (_showReplies) {
                            // Scroll the whole screen to this widget
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final box = context.findRenderObject() as RenderBox?;
                              if (box != null) {
                              final offset = box.localToGlobal(Offset.zero);
                              Scrollable.ensureVisible(
                                context,
                                alignment: 0.0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                              }
                            });
                            }
                          },
                          child: Text(
                            _showReplies
                              ? 'Hide Replies (${review.replyCount}) \u25B2'
                              : 'View Replies (${review.replyCount}) \u25BC',
                            style: TextStyle(
                            fontSize: 14.sp,
                            color: Color(0XFF646161),
                            fontWeight: FontWeight.w400,
                            ),
                          ),
                          ),
                        ),
                        ],
                      
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          review.likedBy?.contains(
                                    FirebaseAuth.instance.currentUser?.uid,
                                  ) ==
                                  true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              review.likedBy?.contains(
                                    FirebaseAuth.instance.currentUser?.uid,
                                  ) ==
                                  true
                              ? Colors.red
                              : Colors.grey,
                          size: 22.sp,
                        ),
                        onPressed: likeReview,
                      ),
                      Text(
                        '${review.likes}',
                        style: TextStyle(fontSize: 13.sp, color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              /// Replies (only show if toggled)
              if (_showReplies && replies.isNotEmpty)
                ...replies.map(
                  (reply) => Padding(
                    padding: EdgeInsets.only(left: 32.w, bottom: 6.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14.r,
                          backgroundImage:
                              (reply['userAvatar'] == null ||
                                  reply['userAvatar'].isEmpty)
                              ? const AssetImage(
                                  'assets/images/default_avatar.png',
                                )
                              : (reply['userAvatar'].toString().startsWith(
                                      'http',
                                    )
                                    ? NetworkImage(reply['userAvatar'])
                                    : MemoryImage(
                                        _decodeBase64(reply['userAvatar']),
                                      )),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reply['userName'] ?? 'User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  reply['text'] ?? '',
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
