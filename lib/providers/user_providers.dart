// Provider for selected address ID (for cart filtering)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/services/authentification/authentification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexoeshopee/services/cache/hive_service.dart';
import 'package:hive/hive.dart';
final selectedAddressIdProvider = StateProvider.autoDispose<String?>((ref) => null);

final userDatabaseHelperProvider = Provider.autoDispose<UserDatabaseHelper>((ref) {
  return UserDatabaseHelper();
});

final authServiceProvider = Provider.autoDispose<AuthentificationService>((ref) {
  return AuthentificationService();
});

final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Form state providers
class FormState {
  final bool isLoading;
  final String? error;
  final Map<String, String> formData;

  const FormState({
    this.isLoading = false,
    this.error,
    this.formData = const {},
  });

  FormState copyWith({
    bool? isLoading,
    String? error,
    Map<String, String>? formData,
  }) {
    return FormState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      formData: formData ?? this.formData,
    );
  }
}

class FormStateNotifier extends StateNotifier<FormState> {
  FormStateNotifier() : super(const FormState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void updateFormData(String key, String value) {
    final newFormData = Map<String, String>.from(state.formData);
    newFormData[key] = value;
    state = state.copyWith(formData: newFormData);
  }

  void clearForm() {
    state = const FormState();
  }
}

final signInFormProvider = StateNotifierProvider.autoDispose<FormStateNotifier, FormState>((
  ref,
) {
  return FormStateNotifier();
});

final signUpFormProvider = StateNotifierProvider.autoDispose<FormStateNotifier, FormState>((
  ref,
) {
  return FormStateNotifier();
});

// Sign up form data provider
class SignUpFormData {
  final String email;
  final String password;
  final String confirmPassword;
  final String displayName;
  final String phoneNumber;

  SignUpFormData({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.displayName = '',
    this.phoneNumber = '',
  });

  SignUpFormData copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? displayName,
    String? phoneNumber,
  }) {
    return SignUpFormData(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

class SignUpFormNotifier extends StateNotifier<SignUpFormData> {
  SignUpFormNotifier() : super(SignUpFormData());

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password);
  }

  void updateConfirmPassword(String confirmPassword) {
    state = state.copyWith(confirmPassword: confirmPassword);
  }

  void updateDisplayName(String displayName) {
    state = state.copyWith(displayName: displayName);
  }

  void updatePhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber);
  }

  void reset() {
    state = SignUpFormData();
  }
}

final signUpFormDataProvider =
    StateNotifierProvider.autoDispose<SignUpFormNotifier, SignUpFormData>((ref) {
      return SignUpFormNotifier();
    });

final cartItemsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  // Try to load from Hive cache first
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    final cachedUser = HiveService.instance.getCachedUser(userId);
    if (cachedUser != null && cachedUser.cartItems.isNotEmpty) {
      return cachedUser.cartItems;
    }
  }
  // Fallback to backend fetch and cache result
  final userHelper = ref.read(userDatabaseHelperProvider);
  final items = await userHelper.allCartItemsList;
  if (userId != null) {
    await HiveService.instance.updateUserCart(userId, items);
  }
  return items;
});

final favouriteProductsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    final cachedUser = HiveService.instance.getCachedUser(userId);
    if (cachedUser != null && cachedUser.favoriteProducts.isNotEmpty) {
      return cachedUser.favoriteProducts;
    }
  }
  final userHelper = ref.read(userDatabaseHelperProvider);
  final favs = await userHelper.usersFavouriteProductsList;
  if (userId != null) {
    await HiveService.instance.updateUserFavorites(userId, favs);
  }
  return favs;
});

// Helper functions for cache access (fixes lint errors)
extension HiveOrderCacheExtension on HiveService {
  List<Map<String, dynamic>> getOrdersCache() {
    try {
      return Hive.box<dynamic>('orders').values.toList().cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
  Future<void> setOrdersCache(List<Map<String, dynamic>> orders) async {
    try {
      final Map<String, Map<String, dynamic>> ordersMap = {
        for (var order in orders) order['id'] as String: order,
      };
      await Hive.box<dynamic>('orders').putAll(ordersMap);
    } catch (_) {}
  }
}

final orderedProductsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  // Optimized: cache orders per user for instant load
  if (userId != null) {
    final cachedOrders = HiveService.instance.getOrdersCache();
    // Only return orders for current user
    final userOrders = cachedOrders.where((order) => order['userId'] == userId).toList();
    if (userOrders.isNotEmpty) {
      return userOrders.map((order) => order['id'] as String).toList();
    }
  }
  // Fallback to backend fetch and cache result
  final userHelper = ref.read(userDatabaseHelperProvider);
  final orders = await userHelper.orderedProductsList;
  // Batch cache update for speed
  if (orders.isNotEmpty && userId != null) {
    await HiveService.instance.setOrdersCache(
      orders.map((id) => {'id': id, 'userId': userId}).toList(),
    );
  }
  return orders;
});

final cartTotalProvider = FutureProvider.autoDispose<num>((ref) async {
  // Try cache first
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final cachedUser = userId != null ? HiveService.instance.getCachedUser(userId) : null;
  if (cachedUser != null && cachedUser.cartItems.isNotEmpty) {
    // You may want to cache cart total separately for more accuracy
    // For now, fallback to backend
  }
  final userHelper = ref.read(userDatabaseHelperProvider);
  final total = await userHelper.cartTotal;
  // Optionally cache total
  return total;
});

final isProductFavouriteProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  productId,
) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    final cachedUser = HiveService.instance.getCachedUser(userId);
    if (cachedUser != null && cachedUser.favoriteProducts.contains(productId)) {
      return true;
    }
  }
  final userHelper = ref.read(userDatabaseHelperProvider);
  return await userHelper.isProductFavourite(productId);
});

// Cart stream provider
final cartItemsStreamProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final userHelper = ref.read(userDatabaseHelperProvider);
  final selectedAddressId = ref.watch(selectedAddressIdProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  final cartCollection = userHelper.firestore
      .collection(UserDatabaseHelper.USERS_COLLECTION_NAME)
      .doc(uid)
      .collection(UserDatabaseHelper.CART_COLLECTION_NAME);
  Query query;
  if (selectedAddressId != null) {
    query = cartCollection.where('address_id', isEqualTo: selectedAddressId);
  } else {
    query = cartCollection;
  }
  return query.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => doc.id).toList();
  });
});
