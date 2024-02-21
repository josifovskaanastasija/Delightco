import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Application is not supported on this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuomOJtOmgFdaNyRJ4l3IF5ibRn_wekJc',
    appId: '1:762628921540:android:b051c32cdec32f8d951191',
    messagingSenderId: '762628921540',
    projectId: 'delightco-86d31',
    storageBucket: 'delightco-86d31.appspot.com',
  );
}
