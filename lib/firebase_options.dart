// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCv86vxKH0t_VTzmUodO-jt49N7ewqaJ9I",
    authDomain: "nexoeshopee-7c6f6.firebaseapp.com",
    projectId: "nexoeshopee-7c6f6",
    storageBucket: "nexoeshopee-7c6f6.firebasestorage.app",
    messagingSenderId: "655019407854",
    appId: "1:655019407854:web:591b4cb2330cca9d95f6ff",
    measurementId: "G-4EKJ13SNZE",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCv86vxKH0t_VTzmUodO-jt49N7ewqaJ9I",
    projectId: "nexoeshopee-7c6f6",
    storageBucket: "nexoeshopee-7c6f6.firebasestorage.app",
    messagingSenderId: "655019407854",
    appId: "1:655019407854:android:<GENERATE_FROM_FIREBASE>",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyCv86vxKH0t_VTzmUodO-jt49N7ewqaJ9I",
    projectId: "nexoeshopee-7c6f6",
    storageBucket: "nexoeshopee-7c6f6.firebasestorage.app",
    messagingSenderId: "655019407854",
    appId: "1:655019407854:ios:<GENERATE_FROM_FIREBASE>",
    iosBundleId: "com.example.nexoeshopee",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyCv86vxKH0t_VTzmUodO-jt49N7ewqaJ9I",
    projectId: "nexoeshopee-7c6f6",
    storageBucket: "nexoeshopee-7c6f6.firebasestorage.app",
    messagingSenderId: "655019407854",
    appId: "1:655019407854:ios:<GENERATE_FROM_FIREBASE>",
    iosBundleId: "com.example.nexoeshopee",
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "AIzaSyCv86vxKH0t_VTzmUodO-jt49N7ewqaJ9I",
    authDomain: "nexoeshopee-7c6f6.firebaseapp.com",
    projectId: "nexoeshopee-7c6f6",
    storageBucket: "nexoeshopee-7c6f6.firebasestorage.app",
    messagingSenderId: "655019407854",
    appId: "1:655019407854:web:591b4cb2330cca9d95f6ff",
    measurementId: "G-4EKJ13SNZE",
  );
}
