import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Base64ImageService {
  Base64ImageService._privateConstructor();
  static final Base64ImageService _instance =
      Base64ImageService._privateConstructor();
  factory Base64ImageService() => _instance;

  /// Convert a file to base64 string
  Future<String> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Error converting file to base64: $e');
    }
  }

  /// Convert a file path to base64 string (platform-aware)
  Future<String> pathToBase64(String path) async {
    try {
      Uint8List bytes;
      if (kIsWeb) {
        // On web, we need to handle this differently
        // This is a fallback - ideally we should use XFile directly
        throw Exception(
          'Direct path conversion not supported on web. Use XFile instead.',
        );
      } else {
        // On mobile platforms, use File
        final file = File(path);
        bytes = await file.readAsBytes();
      }
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Error converting path to base64: $e');
    }
  }

  /// Convert base64 string to bytes
  Uint8List base64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      throw Exception('Error converting base64 to bytes: $e');
    }
  }

  /// Convert XFile to base64 string
  Future<String> xFileToBase64(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Error converting XFile to base64: $e');
    }
  }

  /// Create an Image widget from base64 string
  Widget base64ToImage(
    String base64String, {
    BoxFit? fit,
    double? width,
    double? height,
  }) {
    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: fit ?? BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.error, color: Colors.red),
          );
        },
      );
    } catch (e) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  /// Get image provider from base64 string
  ImageProvider base64ToImageProvider(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      throw Exception('Error creating image provider from base64: $e');
    }
  }

  /// Validate if string is valid base64
  bool isValidBase64(String base64String) {
    try {
      base64Decode(base64String);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Compress image and convert to base64
  Future<String> compressImageToBase64(File file, {int quality = 85}) async {
    try {
      // For now, we'll just convert to base64 without compression
      // In a production app, you might want to use image compression libraries
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Error compressing image to base64: $e');
    }
  }

  /// Get file size from base64 string (in bytes)
  int getBase64FileSize(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      return bytes.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get file size in KB from base64 string
  double getBase64FileSizeInKB(String base64String) {
    final sizeInBytes = getBase64FileSize(base64String);
    return sizeInBytes / 1024;
  }

  /// Get file size in MB from base64 string
  double getBase64FileSizeInMB(String base64String) {
    final sizeInBytes = getBase64FileSize(base64String);
    return sizeInBytes / (1024 * 1024);
  }
}
