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
        city: 'Київ',
      );
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final profile = await _client
        .from('profiles')
        .select('id,email,full_name,role,phone,city')
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
      city: profile['city'] as String?,
    );
  }

  Future<CurrentUser> updateProfile({
    required String fullName,
    required String city,
    String? phone,
  }) async {
    if (useMockData) {
      return CurrentUser(
        id: 'mock_pet_owner',
        email: 'owner@example.com',
        fullName: fullName,
        role: UserRole.petOwner,
        phone: phone,
        city: city,
      );
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Authentication required');
    }

    final profile = await _client
        .from('profiles')
        .update({
          'full_name': fullName,
          'phone': phone,
          'city': city,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id)
        .select('id,email,full_name,role,phone,city')
        .single();

    return CurrentUser(
      id: profile['id'] as String,
      email: profile['email'] as String? ?? user.email ?? '',
      fullName: profile['full_name'] as String? ?? fullName,
      role: CurrentUser.roleFromString(profile['role'] as String?),
      phone: profile['phone'] as String?,
      city: profile['city'] as String?,
    );
  }

  Future<CurrentUser?> login(
      {required String email, required String password}) async {
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
    required String city,
    String? phone,
  }) async {
    if (!isConfigured) {
      return RegisterResult.success;
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'lappo://auth/callback',
      data: {
        'full_name': fullName,
        'role': 'pet_owner',
        'phone': phone,
        'city': city,
      },
    );

    if (response.user == null) {
      return RegisterResult.failed;
    }

    // If session is null, Supabase requires email confirmation
    if (response.session == null) {
      return RegisterResult.confirmationRequired;
    }

    // Update phone/city in profile (trigger may not capture them)
    await _client.from('profiles').update({
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'city': city,
    }).eq('id', response.user!.id);

    return RegisterResult.success;
  }

  Future<bool> signInWithGoogle() async {
    if (!isConfigured) return false;
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'lappo://auth/callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<bool> signInWithApple() async {
    if (!isConfigured) return false;
    return _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'lappo://auth/callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> logout() async {
    if (!isConfigured) {
      return;
    }

    await _client.auth.signOut();
  }

  Future<void> updatePassword(String password) async {
    if (!isConfigured) return;
    await _client.auth.updateUser(UserAttributes(password: password));
  }
}
