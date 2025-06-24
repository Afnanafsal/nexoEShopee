import 'package:nexoeshopee/models/Model.dart';

class Review extends Model {
  static const String REVIEWER_UID_KEY = "reviewer_uid";
  static const String RATING_KEY = "rating";
  static const String FEEDBACK_KEY = "review";

  String? reviewerUid;
  int rating;
  String? feedback;

  Review(
    String? id, {
    this.reviewerUid,
    this.rating = 3,
    this.feedback,
  }) : super(id ?? '');

  factory Review.fromMap(Map<String, dynamic> map, {String? id}) {
    return Review(
      id,
      reviewerUid: map[REVIEWER_UID_KEY],
      rating: map[RATING_KEY] ?? 3,
      feedback: map[FEEDBACK_KEY],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      REVIEWER_UID_KEY: reviewerUid,
      RATING_KEY: rating,
      FEEDBACK_KEY: feedback,
    };
  }

  @override
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (reviewerUid != null) map[REVIEWER_UID_KEY] = reviewerUid;
    map[RATING_KEY] = rating; // always include rating
    if (feedback != null) map[FEEDBACK_KEY] = feedback;
    return map;
  }

  Review copyWith({
    String? id,
    String? reviewerUid,
    int? rating,
    String? feedback,
  }) {
    return Review(
      id ?? this.id,
      reviewerUid: reviewerUid ?? this.reviewerUid,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
    );
  }
}
