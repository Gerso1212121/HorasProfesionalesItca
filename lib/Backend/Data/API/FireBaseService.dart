import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:horas2/firebase_options.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  static User? currentUser() {
    return FirebaseAuth.instance.currentUser;
  }
}
