import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// State for chosen image functionality
class ChosenImageState {
  final XFile? chosenImage;
  final String? imagePath;
  final bool isLoading;
  final String? error;

  const ChosenImageState({
    this.chosenImage,
    this.imagePath,
    this.isLoading = false,
    this.error,
  });

  ChosenImageState copyWith({
    XFile? chosenImage,
    String? imagePath,
    bool? isLoading,
    String? error,
  }) {
    return ChosenImageState(
      chosenImage: chosenImage ?? this.chosenImage,
      imagePath: imagePath ?? this.imagePath,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ChosenImageNotifier extends StateNotifier<ChosenImageState> {
  ChosenImageNotifier() : super(const ChosenImageState());

  void setChosenImage(XFile? image) {
    state = state.copyWith(chosenImage: image);
  }

  void setImagePath(String? path) {
    state = state.copyWith(imagePath: path);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const ChosenImageState();
  }
}

final chosenImageProvider =
    StateNotifierProvider<ChosenImageNotifier, ChosenImageState>((ref) {
      return ChosenImageNotifier();
    });

// State for image picker actions
class ImagePickerState {
  final bool isLoading;
  final String? error;

  const ImagePickerState({this.isLoading = false, this.error});

  ImagePickerState copyWith({bool? isLoading, String? error}) {
    return ImagePickerState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ImagePickerNotifier extends StateNotifier<ImagePickerState> {
  final ImagePicker _picker = ImagePicker();

  ImagePickerNotifier() : super(const ImagePickerState());

  Future<XFile?> pickImageFromGallery() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      state = state.copyWith(isLoading: false);
      return image;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      state = state.copyWith(isLoading: false);
      return image;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<List<XFile>?> pickMultipleImages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      state = state.copyWith(isLoading: false);
      return images;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final imagePickerProvider =
    StateNotifierProvider<ImagePickerNotifier, ImagePickerState>((ref) {
      return ImagePickerNotifier();
    });
