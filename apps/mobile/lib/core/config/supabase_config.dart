import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const bool forceMockMode = bool.fromEnvironment('MOCK_MODE');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static bool get useMockData {
    if (kReleaseMode) {
      if (!isConfigured) {
        throw StateError(
          'SUPABASE_URL and SUPABASE_ANON_KEY must be set for release builds.',
        );
      }
      return false;
    }
    return forceMockMode || !isConfigured;
  }
}
