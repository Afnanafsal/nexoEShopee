import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ChosenImageState {
  final XFile? chosenImage;
  final File? chosenFile;

  const ChosenImageState({this.chosenImage, this.chosenFile});

  ChosenImageState copyWith({XFile? chosenImage, File? chosenFile}) {
    return ChosenImageState(
      chosenImage: chosenImage ?? this.chosenImage,
      chosenFile: chosenFile ?? this.chosenFile,
    );
  }
}

class ChosenImageNotifier extends StateNotifier<ChosenImageState> {
  ChosenImageNotifier() : super(const ChosenImageState());

  void setChosenImage(XFile xFile) {
    File? imageFile;
    if (!kIsWeb) {
      imageFile = File(xFile.path);
    }
    state = ChosenImageState(chosenImage: xFile, chosenFile: imageFile);
  }

  void setChosenFile(File file) {
    state = state.copyWith(chosenFile: file);
  }

  void clear() {
    state = const ChosenImageState();
  }
}

final chosenImageProvider =
    StateNotifierProvider<ChosenImageNotifier, ChosenImageState>((ref) {
      return ChosenImageNotifier();
    });
