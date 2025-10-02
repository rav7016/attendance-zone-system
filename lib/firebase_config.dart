// Simple Firebase configuration for web
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const bool useFirebase = kIsWeb; // Only use Firebase on web

  static const Map<String, dynamic> firebaseOptions = {
    'apiKey': 'AIzaSyBBR_RGjN3NuW6lUUkp5nRq1nRfL6AQhtc',
    'authDomain': 'attendance-be289.firebaseapp.com',
    'projectId': 'attendance-be289',
    'storageBucket': 'attendance-be289.firebasestorage.app',
    'messagingSenderId': '333733790795',
    'appId': '1:333733790795:web:e4ddef7ae433b5e52939ce',
    'measurementId': 'G-9685YWT572',
  };
}
