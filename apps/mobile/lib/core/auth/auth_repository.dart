import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'current_user.dart';

enum RegisterResult { success, confirmationRequired, failed }

class AuthRepository {
  bool get isConfigured => SupabaseConfig.isConfigured;
  bool get useMockData => SupabaseConfig.useMockData;

  SupabaseClient get _client => Supabase.instance.client;

  Future<CurrentUser?> getCurrentUser() async {
    if (useMockData) {
      return const CurrentUser(
        id: 'mock_pet_owner',
        email: 'owner@example.com',
        fullName: 'Olena Petrenko',
        role: UserRole.petOwner,
      );
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final profile = await _client
        .from('profiles')
        .select('id,email,full_name,role,phone')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      return null;
    }

    return CurrentUser(
      id: profile['id'] as String,
      email: profile['email'] as String? ?? user.email ?? '',
      fullName: profile['full_name'] as String? ?? 'Pet owner',
      role: CurrentUser.roleFromString(profile['role'] as String?),
      phone: profile['phone'] as String?,
    );
  }

  Future<CurrentUser?> login({required String email, required String password}) async {
    if (!isConfigured) {
      return getCurrentUser();
    }

    await _client.auth.signInWithPassword(email: email, password: password);
    return getCurrentUser();
  }

  Future<RegisterResult> registerPetOwner({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    if (!isConfigured) {
      return RegisterResult.success;
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': 'pet_owner',
        'phone': phone,
      },
    );

    if (response.user == null) {
      return RegisterResult.failed;
    }

    // If session is null, Supabase requires email confirmation
    if (response.session == null) {
      return RegisterResult.confirmationRequired;
    }

    // Update phone in profile if provided (trigger may not capture it)
    if (phone != null && phone.isNotEmpty) {
      await _client
          .from('profiles')
          .update({'phone': phone})
          .eq('id', response.user!.id);
    }

    return RegisterResult.success;
  }

  Future<void> signInWithGoogle() async {
    if (!isConfigured) return;
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'lappo://auth/callback',
    );
  }

  Future<void> signInWithApple() async {
    if (!isConfigured) return;
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'lappo://auth/callback',
    );
  }

  Future<void> logout() async {
    if (!isConfigured) {
      return;
    }

    await _client.auth.signOut();
  }
}
