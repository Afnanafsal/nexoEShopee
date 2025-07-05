import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ChosenImage extends ChangeNotifier {
  File? _chosenImage;
  XFile? _chosenXFile;

  File? get chosenImage => _chosenImage;
  XFile? get chosenXFile => _chosenXFile;

  set setChosenImage(File img) {
    _chosenImage = img;
    _chosenXFile = null;
    notifyListeners();
  }

  set setChosenXFile(XFile xFile) {
    _chosenXFile = xFile;
    if (!kIsWeb) {
      _chosenImage = File(xFile.path);
    } else {
      _chosenImage = null;
    }
    notifyListeners();
  }
}
