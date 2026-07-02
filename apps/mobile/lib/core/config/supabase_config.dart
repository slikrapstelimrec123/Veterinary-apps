import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const bool forceMockMode = bool.fromEnvironment('MOCK_MODE');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static bool get useMockData {
    // In release builds, mock mode is NEVER allowed — crash loudly if Supabase is not configured
    if (kReleaseMode && !isConfigured) {
      throw StateError('SUPABASE_URL and SUPABASE_ANON_KEY must be set for release builds. '
          'Build with: flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...');
    }
    return forceMockMode || !isConfigured;
  }
}
