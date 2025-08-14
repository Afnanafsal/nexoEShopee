import 'package:fishkart/components/default_button.dart';
import 'package:fishkart/models/Review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../size_config.dart';
import 'package:fishkart/services/authentification/authentification_service.dart';

class ProductReviewDialog extends StatelessWidget {
  final Review review;
  ProductReviewDialog({required Key key, required this.review})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    ValueNotifier<bool> isLoading = ValueNotifier(false);
    // Local state for feedback and rating
    String feedback = review.review ?? '';
    int rating = review.rating;
    final feedbackController = TextEditingController(text: review.review ?? '');
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth < 400
            ? constraints.maxWidth * 0.98
            : 400.0;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Review",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Color(0xFF232323),
                          ),
                        ),
                        Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close,
                              size: 22,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: RatingBar.builder(
                        initialRating: review.rating.toDouble(),
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 28,
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) =>
                            Icon(Icons.star, color: Color(0xFF23395D)),
                        onRatingUpdate: (r) {
                          rating = r.round();
                        },
                      ),
                    ),
                    SizedBox(height: 14),
                    Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                    SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: review.userAvatar != null
                              ? NetworkImage(review.userAvatar!)
                              : null,
                          child: review.userAvatar == null
                              ? Icon(Icons.person, size: 22)
                              : null,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Feedback",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF232323),
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: Stack(
                                  children: [
                                    TextFormField(
                                      controller: feedbackController,
                                      decoration: InputDecoration(
                                        hintText: "Write your feedback...",
                                        border: InputBorder.none,
                                        isDense: true,
                                        counterText: "",
                                      ),
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF232323),
                                      ),
                                      onChanged: (value) {
                                        feedback = value;
                                      },
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Feedback cannot be empty';
                                        }
                                        return null;
                                      },
                                      maxLines: null,
                                      maxLength: 150,
                                    ),
                                    Positioned(
                                      right: 5,
                                      bottom: 10,
                                      child:
                                          ValueListenableBuilder<
                                            TextEditingValue
                                          >(
                                            valueListenable: feedbackController,
                                            builder: (context, value, _) {
                                              return Text(
                                                "${value.text.length}/150",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              );
                                            },
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    ValueListenableBuilder<bool>(
                      valueListenable: isLoading,
                      builder: (context, loading, _) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              elevation: 2,
                            ),
                            onPressed: loading
                                ? null
                                : () async {
                                    if (_formKey.currentState != null &&
                                        !_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    isLoading.value = true;
                                    try {
                                      String? reviewerUid = review.reviewerUid;
                                      String? userAvatar = review.userAvatar;
                                      String? userName = review.userName;
                                      if (reviewerUid != null) {
                                        final userDoc = await FirebaseFirestore
                                            .instance
                                            .collection('users')
                                            .doc(reviewerUid)
                                            .get();
                                        final data = userDoc.data();
                                        if (data != null) {
                                          userAvatar =
                                              data['display_picture'] ?? null;
                                          userName =
                                              data['display_name'] ?? 'User';
                                        }
                                      }
                                      // Ensure reviewerUid is set
                                      if (reviewerUid == null ||
                                          reviewerUid.isEmpty) {
                                        try {
                                          reviewerUid =
                                              AuthentificationService()
                                                  .currentUser
                                                  .uid;
                                        } catch (e) {}
                                      }
                                      if (feedback.trim().isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Feedback cannot be empty',
                                            ),
                                          ),
                                        );
                                        isLoading.value = false;
                                        return;
                                      }
                                      print(
                                        'DEBUG: feedback before save: ' +
                                            feedback,
                                      );
                                      final newReview = Review(
                                        review.id,
                                        reviewerUid: reviewerUid,
                                        rating: rating,
                                        review: feedback,
                                        createdAt: DateTime.now(),
                                        likes: review.likes,
                                        replyCount: review.replyCount,
                                        userAvatar: userAvatar,
                                        userName: userName,
                                      );
                                      Navigator.pop(context, newReview);
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: ���${e.toString()}',
                                          ),
                                        ),
                                      );
                                    } finally {
                                      isLoading.value = false;
                                    }
                                  },
                            child: Text(
                              loading ? "Submitting..." : "Submit",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
