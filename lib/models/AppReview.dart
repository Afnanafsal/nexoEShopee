import 'Model.dart';

class AppReview extends Model {
  static const String LIKED_KEY = "liked";
  static const String FEEDBACK_KEY = "feedback";

  bool? liked;
  String? feedback;

  AppReview(
    String id, {
    this.liked,
    this.feedback,
  }) : super(id);

  factory AppReview.fromMap(Map<String, dynamic> map, {required String id}) {
    return AppReview(
      id,
      liked: map[LIKED_KEY],
      feedback: map[FEEDBACK_KEY],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      LIKED_KEY: liked,
      FEEDBACK_KEY: feedback,
    };
  }

  @override
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (liked != null) map[LIKED_KEY] = liked;
    if (feedback != null) map[FEEDBACK_KEY] = feedback;
    return map;
  }
}
