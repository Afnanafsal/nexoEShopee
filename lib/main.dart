import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nexoeshopee/app.dart';
import 'firebase_options.dart'; // This must exist

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ✅ Important
  );

  runApp(App());
}
