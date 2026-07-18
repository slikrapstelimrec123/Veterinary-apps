import 'package:flutter/foundation.dart';

/// A small app-wide refresh signal for data that is shown in several tabs.
///
/// Supabase Realtime keeps remote devices in sync, while this signal makes
/// local mutations visible immediately without waiting for a network event.
class AppDataEvents {
  AppDataEvents._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void notifyChanged() {
    revision.value++;
  }
}
