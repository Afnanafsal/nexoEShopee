import 'package:hive/hive.dart';

part 'cached_user.g.dart';

@HiveType(typeId: 1)
class CachedUser extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? displayName;

  @HiveField(2)
  String? email;

  @HiveField(3)
  String? phone;

  @HiveField(4)
  String? profilePicture;

  @HiveField(5)
  List<String> favoriteProducts;

  @HiveField(6)
  List<String> cartItems;

  @HiveField(7)
  DateTime cachedAt;

  @HiveField(8)
  Map<String, dynamic>? preferences;

  CachedUser({
    required this.id,
    this.displayName,
    this.email,
    this.phone,
    this.profilePicture,
    this.favoriteProducts = const [],
    this.cartItems = const [],
    required this.cachedAt,
    this.preferences,
  });

  bool get isExpired {
    // Cache expires after 30 minutes
    return DateTime.now().difference(cachedAt).inMinutes > 30;
  }
}
