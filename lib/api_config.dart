import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      // Real phone on the same Wi-Fi as the PC running the backend.
      // (Use http://10.0.2.2:8000 for the Android emulator.)
      return 'http://192.168.1.103:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Where the app downloads the on-device AI model (Gemma 3 1B, .task file).
  /// Put the file at  <backend>/app/static/models/gemma-3-1b-it-int4.task
  static String get offlineModelUrl => '$baseUrl/static/models/gemma-3-1b-it-int4.task';
}