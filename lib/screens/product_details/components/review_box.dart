import 'package:firebase_auth/firebase_auth.dart';
import 'package:fishkart/models/Review.dart';
import 'package:flutter/material.dart';
// import '../../../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _ReviewBoxState extends State<ReviewBox> {
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
      avatar = userData['display_picture'] ?? null;
      name = userData['display_name'] ?? 'User';
    }
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to Review'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: 'Type your reply...'),
          onChanged: (val) => replyText = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
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
            child: Text('Post'),
          ),
        ],
      ),
    );
  }

  late Review review;

  @override
  void initState() {
    super.initState();
    review = widget.review;
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
      return AssetImage('assets/images/default_avatar.png');
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
    return AssetImage('assets/images/default_avatar.png');
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
        review = review.copyWith(likes: likedBy.length);
      });
      await reviewRef.update({'likes': likedBy.length, 'likedBy': likedBy});
    }
  }

  Future<String> _getCurrentUserId() async {
    // You may want to use your AuthentificationService here
    // For Firebase Auth:
    // import 'package:firebase_auth/firebase_auth.dart';
    // return FirebaseAuth.instance.currentUser?.uid ?? '';
    // For now, return empty string if not available
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> replyToReview() async {
    setState(() {
      review = review.copyWith(replyCount: review.replyCount + 1);
    });
    final db = FirebaseFirestore.instance;
    await db
        .collection('products')
        .doc(widget.productId)
        .collection('reviews')
        .doc(review.reviewerUid)
        .update({'replyCount': review.replyCount});
    // You can show a reply dialog here
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchReplies(),
      builder: (context, snapshot) {
        final replies = snapshot.data ?? [];
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: _getAvatarProvider(),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName ?? 'User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          review.review ?? '',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.favorite_border, color: Colors.redAccent),
                    onPressed: likeReview,
                  ),
                  Text(
                    '${review.likes}',
                    style: TextStyle(fontSize: 13, color: Colors.black),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    getTimeAgo(review.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: showReplyDialog,
                    child: Text(
                      'Reply',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (replies.isNotEmpty)
                ...replies.map(
                  (reply) => Padding(
                    padding: const EdgeInsets.only(left: 32, bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage:
                              (reply['userAvatar'] == null ||
                                  reply['userAvatar'].isEmpty)
                              ? AssetImage('assets/images/default_avatar.png')
                              : (reply['userAvatar'].toString().startsWith(
                                          'http',
                                        )
                                        ? NetworkImage(reply['userAvatar'])
                                        : AssetImage(
                                            'assets/images/default_avatar.png',
                                          ))
                                    as ImageProvider,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reply['userName'] ?? 'User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  reply['text'] ?? '',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'View Replies (${review.replyCount}) \u25BC',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
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
