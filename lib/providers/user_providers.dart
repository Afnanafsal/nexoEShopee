import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexoeshopee/services/database/user_database_helper.dart';
import 'package:nexoeshopee/services/authentification/authentification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userDatabaseHelperProvider = Provider<UserDatabaseHelper>((ref) {
  return UserDatabaseHelper();
});

final authServiceProvider = Provider<AuthentificationService>((ref) {
  return AuthentificationService();
});

final authStateProvider = StreamProvider<User?>((ref) {
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

final signInFormProvider = StateNotifierProvider<FormStateNotifier, FormState>((
  ref,
) {
  return FormStateNotifier();
});

final signUpFormProvider = StateNotifierProvider<FormStateNotifier, FormState>((
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
    StateNotifierProvider<SignUpFormNotifier, SignUpFormData>((ref) {
      return SignUpFormNotifier();
    });

final cartItemsProvider = FutureProvider<List<String>>((ref) async {
  final userHelper = ref.watch(userDatabaseHelperProvider);
  return await userHelper.allCartItemsList;
});

final favouriteProductsProvider = FutureProvider<List<String>>((ref) async {
  final userHelper = ref.watch(userDatabaseHelperProvider);
  return await userHelper.usersFavouriteProductsList;
});

final orderedProductsProvider = FutureProvider<List<String>>((ref) async {
  final userHelper = ref.watch(userDatabaseHelperProvider);
  return await userHelper.orderedProductsList;
});

final cartTotalProvider = FutureProvider<num>((ref) async {
  final userHelper = ref.watch(userDatabaseHelperProvider);
  return await userHelper.cartTotal;
});

final isProductFavouriteProvider = FutureProvider.family<bool, String>((
  ref,
  productId,
) async {
  final userHelper = ref.watch(userDatabaseHelperProvider);
  return await userHelper.isProductFavourite(productId);
});

// Cart stream provider
final cartItemsStreamProvider = StreamProvider<List<String>>((ref) {
  final userHelper = ref.watch(userDatabaseHelperProvider);
  return Stream.fromFuture(userHelper.allCartItemsList);
});
