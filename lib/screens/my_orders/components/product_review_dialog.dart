import 'package:fishkart/components/default_button.dart';
import 'package:fishkart/models/Review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../size_config.dart';

class ProductReviewDialog extends StatelessWidget {
  final Review review;
  ProductReviewDialog({required Key key, required this.review})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 300,
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                "Review",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF232323),
                ),
              ),
            ),
            SizedBox(height: 16),
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
                itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) =>
                    Icon(Icons.star, color: Color(0xFF23395D)),
                onRatingUpdate: (rating) {
                  review.rating = rating.round();
                },
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
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
                          child: TextFormField(
                            initialValue: review.feedback,
                            decoration: InputDecoration(
                              hintText: "Write your feedback...",
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF232323),
                            ),
                            onChanged: (value) {
                              review.feedback = value;
                            },
                            maxLines: null,
                            maxLength: 150,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF23395D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  // Fetch user avatar and name from Firestore
                  final uid = review.reviewerUid;
                  if (uid != null) {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .get();
                    final data = userDoc.data();
                    if (data != null) {
                      review.userAvatar = data['display_picture'] ?? null;
                      review.userName = data['display_name'] ?? 'User';
                    }
                  }
                  Navigator.pop(context, review);
                },
                child: Text(
                  "Submit",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
