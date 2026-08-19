import 'package:flutter/foundation.dart';

/// Tiny app-wide event notifier.
/// Screens listen to [dataVersion] and reload when it changes,
/// e.g. after an inspection is submitted.
class AppEvents {
  static final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  /// Announce that server data changed (new report, submitted inspection...).
  static void bump() => dataVersion.value++;
}