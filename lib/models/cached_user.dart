import 'package:hive/hive.dart';

part 'cached_user.g.dart';

@HiveType(typeId: 1)
class CachedUser extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String? displayName;

  @HiveField(2)
  String? email;

  @HiveField(3)
  String? profilePicture;

  @HiveField(4)
  List<String> favoriteProducts;

  @HiveField(5)
  List<String> cartItems;

  @HiveField(6)
  DateTime cachedAt;

  @HiveField(7)
  Duration cacheDuration;

  @HiveField(8)
  Map<String, dynamic>? preferences;

  CachedUser({
    required this.userId,
    this.displayName,
    this.email,
    this.profilePicture,
    this.favoriteProducts = const [],
    this.cartItems = const [],
    required this.cachedAt,
    this.cacheDuration = const Duration(hours: 6),
    this.preferences,
  });

  factory CachedUser.create({
    required String userId,
    String? displayName,
    String? email,
    String? profilePicture,
    List<String>? favoriteProducts,
    List<String>? cartItems,
    Duration? cacheDuration,
    Map<String, dynamic>? preferences,
  }) {
    return CachedUser(
      userId: userId,
      displayName: displayName,
      email: email,
      profilePicture: profilePicture,
      favoriteProducts: favoriteProducts ?? [],
      cartItems: cartItems ?? [],
      cachedAt: DateTime.now(),
      cacheDuration: cacheDuration ?? const Duration(hours: 6),
      preferences: preferences,
    );
  }

  bool get isExpired {
    return DateTime.now().difference(cachedAt) > cacheDuration;
  }

  void updateCacheTime() {
    cachedAt = DateTime.now();
    save();
  }

  CachedUser copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? profilePicture,
    List<String>? favoriteProducts,
    List<String>? cartItems,
    Duration? cacheDuration,
    Map<String, dynamic>? preferences,
  }) {
    return CachedUser(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      cartItems: cartItems ?? this.cartItems,
      cachedAt: DateTime.now(),
      cacheDuration: cacheDuration ?? this.cacheDuration,
      preferences: preferences ?? this.preferences,
    );
  }
}
