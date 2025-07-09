import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingState {
  final bool isLoading;
  final String? message;
  final String? error;

  LoadingState({this.isLoading = false, this.message, this.error});

  LoadingState copyWith({bool? isLoading, String? message, String? error}) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }
}

class LoadingStateNotifier extends StateNotifier<LoadingState> {
  LoadingStateNotifier() : super(LoadingState());

  void setLoading(bool isLoading, {String? message}) {
    state = state.copyWith(isLoading: isLoading, message: message, error: null);
  }

  void setError(String error) {
    state = state.copyWith(isLoading: false, error: error, message: null);
  }

  void reset() {
    state = LoadingState();
  }
}

final loadingStateProvider =
    StateNotifierProvider<LoadingStateNotifier, LoadingState>((ref) {
      return LoadingStateNotifier();
    });

final selectedProductTypeProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final cartItemCountProvider = StateProvider<int>((ref) => 0);
