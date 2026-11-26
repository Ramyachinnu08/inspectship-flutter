import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  /// Live server (HTTPS). Same address for web, Android phone and desktop.
  /// For local testing against a backend on this computer, see the comments.
  static String get baseUrl {
    return 'https://api.trybeanalytics.com';

    // Local testing instead? Comment the line above and uncomment below:
    // if (kIsWeb) return 'http://127.0.0.1:8000';
    // if (Platform.isAndroid) return 'http://192.168.1.103:8000';
    // return 'http://127.0.0.1:8000';
  }

  /// Where the app downloads the on-device AI model (Gemma 3 1B, .task file).
  /// Served by the backend from app/static/models/.
  static String get offlineModelUrl =>
      '$baseUrl/static/models/gemma-3-1b-it-int4.task';
}