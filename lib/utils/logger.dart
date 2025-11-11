import 'package:flutter/foundation.dart';
/// Lightweight wrapper around [debugPrint] that is ignored in release builds.
void logDebug(Object? message) {
  if (kDebugMode) {
    debugPrint(message?.toString());
  }
}

