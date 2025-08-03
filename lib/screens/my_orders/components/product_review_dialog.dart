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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth < 400
            ? constraints.maxWidth * 0.98
            : 400.0;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
                      Icon(
                        Icons.rate_review,
                        color: Color(0xFF23395D),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Product Review",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                            color: Color(0xFF232323),
                          ),
                        ),
                      ),
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
                      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) =>
                          Icon(Icons.star, color: Color(0xFF23395D)),
                      onRatingUpdate: (rating) {
                        review.rating = rating.round();
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
                                border: Border.all(color: Color(0xFFE0E0E0)),
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
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Feedback cannot be empty';
                                  }
                                  return null;
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
                  SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.send, size: 18, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF23395D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
                          return;
                        }
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
                        // Ensure reviewerUid is set
                        if (review.reviewerUid == null ||
                            review.reviewerUid!.isEmpty) {
                          try {
                            review.reviewerUid =
                                AuthentificationService().currentUser.uid;
                          } catch (e) {}
                        }
                        review.createdAt = DateTime.now();
                        if (review.feedback == null || review.feedback!.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Feedback cannot be empty')),
                          );
                          return;
                        }
                        Navigator.pop(context, review);
                      },
                      label: Text(
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
          ),
        ));
      },
    );
  }
}
