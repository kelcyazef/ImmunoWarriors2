// This is a placeholder for Firebase options
// In a real app, you would generate this file using the FlutterFire CLI
// Run: dart pub global activate flutterfire_cli
// Then: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Replace with your actual Firebase configuration
    return const FirebaseOptions(
      apiKey: 'YOUR_API_KEY',
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
      projectId: 'immunowarriors-app',
      authDomain: 'immunowarriors-app.firebaseapp.com',
      storageBucket: 'immunowarriors-app.appspot.com',
    );
  }
}
