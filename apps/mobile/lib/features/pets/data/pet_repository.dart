import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/data/mock_data.dart';
import '../domain/pet.dart';

class PetRepository {
  bool get _useMockData => SupabaseConfig.useMockData;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Pet>> getPets() async {
    if (_useMockData) {
      return MockData.pets;
    }

    final links = await _client
        .from('pet_owners')
        .select('pets(*)')
        .eq('user_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return (links as List<dynamic>)
        .map((row) => row['pets'])
        .whereType<Map<String, dynamic>>()
        .map(Pet.fromJson)
        .toList();
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

    final data = await _client.from('pets').select('*').eq('id', id).maybeSingle();
    return data == null ? null : Pet.fromJson(data);
  }

  Future<Pet> createPet(Pet pet) async {
    if (_useMockData) {
      final created = pet.copyWith(id: 'mock_pet_${DateTime.now().millisecondsSinceEpoch}');
      MockData.pets.add(created);
      return created;
    }

    final created = await _client.from('pets').insert(pet.toInsertJson()).select('*').single();
    final parsed = Pet.fromJson(created);
    await _client.from('pet_owners').insert({
      'pet_id': parsed.id,
      'user_id': _client.auth.currentUser!.id,
      'relationship': 'primary_owner',
      'relationship_type': 'primary_owner',
      'is_primary': true,
    });

    return parsed;
  }

  Future<Pet> updatePet(Pet pet) async {
    if (_useMockData) {
      final index = MockData.pets.indexWhere((item) => item.id == pet.id);
      if (index >= 0) {
        MockData.pets[index] = pet;
      }
      return pet;
    }

    final updated = await _client.from('pets').update(pet.toInsertJson()).eq('id', pet.id).select('*').single();
    return Pet.fromJson(updated);
  }
}
