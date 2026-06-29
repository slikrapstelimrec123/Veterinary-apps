import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'current_user.dart';

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
        .select('id,email,full_name,role')
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
    );
  }

  Future<CurrentUser?> login({required String email, required String password}) async {
    if (!isConfigured) {
      return getCurrentUser();
    }

    await _client.auth.signInWithPassword(email: email, password: password);
    return getCurrentUser();
  }

  Future<CurrentUser?> registerPetOwner({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    if (!isConfigured) {
      return getCurrentUser();
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': 'pet_owner',
      },
    );

    final user = response.user;
    if (user == null) {
      return null;
    }

    await _client.from('profiles').insert({
      'id': user.id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': 'pet_owner',
    });

    return getCurrentUser();
  }

  Future<void> logout() async {
    if (!isConfigured) {
      return;
    }

    await _client.auth.signOut();
  }
}
