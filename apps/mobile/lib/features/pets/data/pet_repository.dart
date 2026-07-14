import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/data/mock_data.dart';
import '../../../shared/services/private_pet_storage.dart';
import '../domain/pet.dart';

class PetRepository {
  bool get _useMockData => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Pet>> getPets() async {
    if (_useMockData) {
      return MockData.pets;
    }

    final data = await _client
        .from('pets')
        .select('*')
        .order('created_at', ascending: false);

    return Future.wait((data as List<dynamic>)
        .map((row) => _fromPrivateRow(row as Map<String, dynamic>)));
  }

  Future<Pet?> getPet(String id) async {
    if (_useMockData) {
      for (final pet in MockData.pets) {
        if (pet.id == id) {
          return pet;
        }
      }
      return null;
    }

    final data =
        await _client.from('pets').select('*').eq('id', id).maybeSingle();
    return data == null ? null : _fromPrivateRow(data);
  }

  Future<Pet> createPet(Pet pet) async {
    if (_useMockData) {
      final created =
          pet.copyWith(id: 'mock_pet_${DateTime.now().millisecondsSinceEpoch}');
      MockData.pets.add(created);
      return created;
    }

    final created = await _client.rpc(
      'create_pet_for_current_user',
      params: {'payload': pet.toInsertJson()},
    );
    return _fromPrivateRow(Map<String, dynamic>.from(created as Map));
  }

  Future<Pet> updatePet(Pet pet) async {
    if (_useMockData) {
      final index = MockData.pets.indexWhere((item) => item.id == pet.id);
      if (index >= 0) {
        MockData.pets[index] = pet;
      }
      return pet;
    }

    final updated = await _client
        .from('pets')
        .update(pet.toInsertJson())
        .eq('id', pet.id)
        .select('*')
        .single();
    return _fromPrivateRow(updated);
  }

  Future<void> deletePet(String id) async {
    if (_useMockData) {
      MockData.pets.removeWhere((p) => p.id == id);
      return;
    }
    await _client.from('pets').delete().eq('id', id);
  }

  Future<Pet> _fromPrivateRow(Map<String, dynamic> row) async {
    final hydrated = Map<String, dynamic>.from(row);
    try {
      hydrated['avatar_url'] = await PrivatePetStorage.signedUrl(
              row['avatar_storage_path'] as String?) ??
          row['avatar_url'];
      hydrated['passport_photo_url'] = await PrivatePetStorage.signedUrl(
            row['passport_storage_path'] as String?,
          ) ??
          row['passport_photo_url'];
    } catch (_) {
      // Keep legacy URLs available if signing is temporarily unavailable.
    }
    return Pet.fromJson(hydrated);
  }
}
